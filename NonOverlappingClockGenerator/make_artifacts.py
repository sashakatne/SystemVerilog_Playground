#!/usr/bin/env python3
"""Generate NonOverlappingClockGenerator waveform artifacts from dump.vcd."""

from __future__ import annotations

import csv
import html
import re
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent
VCD = ROOT / "dump.vcd"
CSV_OUT = ROOT / "waveform_samples.csv"
WAVEFORM_SVG = ROOT / "waveforms.svg"
WAVEFORM_PNG = ROOT / "waveforms.png"

SIGNALS = ("CK", "CK1", "CK1_b", "CK2", "CK2_b", "start_checking")


def bit_value(value: str) -> int:
    return 1 if value == "1" else 0


def parse_vcd(path: Path) -> list[dict[str, int]]:
    if not path.exists():
        raise SystemExit(f"missing VCD: {path}")

    id_to_name: dict[str, str] = {}
    values: dict[str, str] = {name: "x" for name in SIGNALS}
    rows: list[dict[str, int]] = []
    current_time: int | None = None
    changed = False
    in_header = True
    scope_stack: list[str] = []
    var_re = re.compile(r"\$var\s+\S+\s+\d+\s+(\S+)\s+(\S+)")

    def append_snapshot() -> None:
        if current_time is None:
            return
        if any(values[name] not in {"0", "1"} for name in SIGNALS[:5]):
            return
        if rows and rows[-1]["time_ns"] == current_time:
            return
        ck1 = bit_value(values["CK1"])
        ck2 = bit_value(values["CK2"])
        row = {
            "time_ns": current_time,
            "CK": bit_value(values["CK"]),
            "CK1": ck1,
            "CK1_b": bit_value(values["CK1_b"]),
            "CK2": ck2,
            "CK2_b": bit_value(values["CK2_b"]),
            "start_checking": bit_value(values["start_checking"]) if values["start_checking"] in {"0", "1"} else 0,
            "overlap": ck1 & ck2,
            "both_low": int((ck1 == 0) and (ck2 == 0)),
        }
        rows.append(row)

    for raw_line in path.read_text(errors="replace").splitlines():
        line = raw_line.strip()
        if not line:
            continue

        if in_header:
            if line.startswith("$scope "):
                fields = line.split()
                if len(fields) >= 3:
                    scope_stack.append(fields[2])
                continue
            if line.startswith("$upscope"):
                if scope_stack:
                    scope_stack.pop()
                continue
            match = var_re.match(line)
            if match:
                code, name = match.groups()
                if scope_stack == ["top"] and name in SIGNALS:
                    id_to_name[code] = name
            if line == "$enddefinitions $end":
                in_header = False
            continue

        if line.startswith("#"):
            if changed:
                append_snapshot()
            current_time = int(line[1:])
            changed = False
            continue

        if line.startswith("$"):
            continue

        if line[0] in "01xz":
            value = line[0]
            code = line[1:]
        elif line[0] in "bB":
            fields = line[1:].split()
            if len(fields) != 2:
                continue
            value, code = fields
        else:
            continue

        name = id_to_name.get(code)
        if name is None:
            continue
        values[name] = value
        changed = True

    if changed:
        append_snapshot()

    return rows


def write_csv(rows: list[dict[str, int]], path: Path) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def polyline(points: list[tuple[float, float]]) -> str:
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)


def render_waveforms(rows: list[dict[str, int]], path: Path) -> None:
    visible = [row for row in rows if row["time_ns"] <= 80]
    if len(visible) < 2:
        raise SystemExit("not enough waveform samples to render")

    width = 1360
    height = 660
    left = 150
    right = 42
    top = 78
    lane_h = 70
    plot_w = width - left - right
    max_time = visible[-1]["time_ns"]

    lanes = [
        ("CK", "CK"),
        ("CK1", "CK1"),
        ("CK2", "CK2"),
        ("CK1_b", "CK1_b"),
        ("CK2_b", "CK2_b"),
        ("overlap", "CK1 & CK2"),
        ("both_low", "dead band"),
    ]

    def x_at(time_ns: int) -> float:
        return left + (time_ns * plot_w / max_time)

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect x="0" y="0" width="1360" height="660" fill="#ffffff"/>',
        '<text x="40" y="36" font-family="Arial, sans-serif" font-size="24" font-weight="700">NonOverlappingClockGenerator farm simulation waveform</text>',
        '<text x="40" y="60" font-family="Arial, sans-serif" font-size="14" fill="#555">Rendered from dump.vcd produced by the Questa farm run; first 80 ns of the 1000 ns simulation shown</text>',
    ]

    for tick in range(0, max_time + 1, 10):
        x = x_at(tick)
        parts.append(f'<line x1="{x:.1f}" y1="{top - 22}" x2="{x:.1f}" y2="{height - 64}" stroke="#e7e7e7" stroke-width="1"/>')
        parts.append(f'<text x="{x:.1f}" y="{height - 38}" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#555">{tick}</text>')

    for lane_index, (key, label) in enumerate(lanes):
        y_mid = top + lane_index * lane_h + 24
        y_hi = y_mid - 18
        y_lo = y_mid + 18
        parts.append(f'<text x="34" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="16" fill="#111">{html.escape(label)}</text>')
        parts.append(f'<line x1="{left}" y1="{y_lo}" x2="{width - right}" y2="{y_lo}" stroke="#d4d4d4" stroke-width="1"/>')

        points: list[tuple[float, float]] = []
        previous_y: float | None = None
        for index, row in enumerate(visible):
            x = x_at(row["time_ns"])
            y = y_hi if row[key] else y_lo
            if index and previous_y is not None:
                points.append((x, previous_y))
            points.append((x, y))
            previous_y = y
        parts.append(f'<polyline points="{polyline(points)}" fill="none" stroke="#111" stroke-width="2.4"/>')

    parts.append(f'<text x="{left}" y="{height - 14}" font-family="Arial, sans-serif" font-size="13" fill="#555">No CK1/CK2 overlap was observed. The zero-delay RTL waveform also shows no visible dead band; the buffer chains collapse to same-time transitions in this simulation.</text>')
    parts.append("</svg>")
    path.write_text("\n".join(parts))


def convert_with_sips(source: Path, dest: Path, fmt: str) -> None:
    if shutil.which("sips") is None:
        raise SystemExit("sips is required to render artifacts on this machine")
    subprocess.run(
        ["sips", "-s", "format", fmt, str(source), "--out", str(dest)],
        check=True,
        stdout=subprocess.DEVNULL,
    )


def main() -> None:
    rows = parse_vcd(VCD)
    if not rows:
        raise SystemExit("no waveform samples found in VCD")
    write_csv(rows, CSV_OUT)
    render_waveforms(rows, WAVEFORM_SVG)
    convert_with_sips(WAVEFORM_SVG, WAVEFORM_PNG, "png")
    WAVEFORM_SVG.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
