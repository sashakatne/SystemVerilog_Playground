#!/usr/bin/env python3
"""Generate timing gotcha waveform artifacts from the farm VCD."""

from __future__ import annotations

import csv
import html
import re
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent
VCD = ROOT / "timing_gotchas_waveforms.vcd"
CSV_OUT = ROOT / "waveform_samples.csv"
WAVEFORM_SVG = ROOT / "waveforms.svg"
WAVEFORM_PNG = ROOT / "waveforms.png"

WATCH_SIGNALS = (
    "clk",
    "rst_n",
    "launch_d",
    "min_fast_capture_d",
    "min_fast_hold_window",
    "min_fast_hold_violation_pulse",
    "min_padded_capture_d",
    "max_slow_capture_d",
    "max_slow_setup_window",
    "max_slow_setup_violation_pulse",
    "max_ok_capture_d",
)

VAR_RE = re.compile(r"\$var\s+\S+\s+\d+\s+(\S+)\s+(\S+)")


def parse_vcd(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise SystemExit(f"missing VCD: {path}")

    id_to_name: dict[str, str] = {}
    values = {name: "x" for name in WATCH_SIGNALS}
    rows: list[dict[str, str]] = []
    scope_stack: list[str] = []
    current_time = 0
    in_header = True
    changed = False

    def append_snapshot() -> None:
        row = {"time_ps": str(current_time)}
        for name in WATCH_SIGNALS:
            row[name] = values[name]
        if rows and rows[-1] == row:
            return
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
            match = VAR_RE.match(line)
            if match and scope_stack == ["top"]:
                code, name = match.groups()
                if name in WATCH_SIGNALS:
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
        values[name] = value[-1].lower()
        changed = True

    if changed:
        append_snapshot()

    return rows


def write_csv(rows: list[dict[str, str]], path: Path) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["time_ps", *WATCH_SIGNALS])
        writer.writeheader()
        writer.writerows(rows)


def signal_at(rows: list[dict[str, str]], signal: str, time_ps: int) -> str:
    value = "x"
    for row in rows:
        row_time = int(row["time_ps"])
        if row_time > time_ps:
            break
        value = row[signal]
    return value


def transitions(rows: list[dict[str, str]], signal: str, start_ps: int, end_ps: int) -> list[int]:
    hits: list[int] = []
    previous = signal_at(rows, signal, start_ps)
    for row in rows:
        row_time = int(row["time_ps"])
        if row_time < start_ps or row_time > end_ps:
            continue
        current = row[signal]
        if previous != "1" and current == "1":
            hits.append(row_time)
        previous = current
    return hits


def polyline(points: list[tuple[float, float]]) -> str:
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)


def render_waveforms(rows: list[dict[str, str]], path: Path) -> None:
    start_ps = 1000
    end_ps = 2800
    visible = [row for row in rows if start_ps <= int(row["time_ps"]) <= end_ps]
    if not visible:
        raise SystemExit("no visible waveform rows")

    width = 1480
    height = 790
    left = 230
    right = 48
    top = 96
    lane_h = 60
    plot_w = width - left - right

    lanes = [
        ("clk", "clk", "#111111"),
        ("launch_d", "launch_d", "#111111"),
        ("min_fast_capture_d", "min fast D (20 ps)", "#b42318"),
        ("min_fast_hold_window", "hold window (80 ps)", "#c2410c"),
        ("min_fast_hold_violation_pulse", "hold violation", "#b42318"),
        ("min_padded_capture_d", "min padded D (120 ps)", "#15803d"),
        ("max_slow_capture_d", "max slow D (920 ps)", "#1d4ed8"),
        ("max_slow_setup_window", "setup window (150 ps)", "#6d28d9"),
        ("max_slow_setup_violation_pulse", "setup violation", "#b42318"),
        ("max_ok_capture_d", "max clean D (700 ps)", "#15803d"),
    ]

    def x_at(time_ps: int) -> float:
        return left + ((time_ps - start_ps) * plot_w / (end_ps - start_ps))

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        f'<rect x="0" y="0" width="{width}" height="{height}" fill="#ffffff"/>',
        '<text x="40" y="38" font-family="Arial, sans-serif" font-size="24" font-weight="700" fill="#111">Timing gotchas farm simulation waveform</text>',
        '<text x="40" y="63" font-family="Arial, sans-serif" font-size="14" fill="#555">Rendered from timing_gotchas_waveforms.vcd produced by the PSU Questa farm run; 1000-2800 ps window shown</text>',
    ]

    for tick in range(start_ps, end_ps + 1, 250):
        x = x_at(tick)
        stroke = "#d7dce2" if tick % 1000 == 500 else "#eceff3"
        parts.append(f'<line x1="{x:.1f}" y1="{top - 18}" x2="{x:.1f}" y2="{height - 58}" stroke="{stroke}" stroke-width="1"/>')
        if tick % 500 == 0:
            parts.append(f'<text x="{x:.1f}" y="{height - 32}" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#555">{tick}</text>')

    for lane_index, (key, label, color) in enumerate(lanes):
        y_mid = top + lane_index * lane_h + 20
        y_hi = y_mid - 17
        y_lo = y_mid + 17
        parts.append(f'<text x="36" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="15" fill="#111">{html.escape(label)}</text>')
        parts.append(f'<line x1="{left}" y1="{y_lo}" x2="{width - right}" y2="{y_lo}" stroke="#d7dce2" stroke-width="1"/>')

        points: list[tuple[float, float]] = []
        previous_y: float | None = None
        seed = {"time_ps": str(start_ps), key: signal_at(rows, key, start_ps)}
        lane_rows = [seed, *visible]
        for index, row in enumerate(lane_rows):
            row_time = int(row["time_ps"])
            value = row[key]
            x = x_at(row_time)
            if value == "1":
                y = y_hi
            elif value == "0":
                y = y_lo
            else:
                y = y_mid
            if index and previous_y is not None:
                points.append((x, previous_y))
            points.append((x, y))
            previous_y = y
        parts.append(f'<polyline points="{polyline(points)}" fill="none" stroke="{color}" stroke-width="2.6"/>')

    marker_rows = {
        "hold": (transitions(rows, "min_fast_hold_violation_pulse", start_ps, end_ps)[:1], "#b42318", "hold hit"),
        "setup": (transitions(rows, "max_slow_setup_violation_pulse", start_ps, end_ps)[:1], "#b42318", "setup hit"),
    }
    for times, color, label in marker_rows.values():
        for time_ps in times:
            x = x_at(time_ps)
            parts.append(f'<line x1="{x:.1f}" y1="{top - 8}" x2="{x:.1f}" y2="{height - 78}" stroke="{color}" stroke-width="1.6" stroke-dasharray="5 4"/>')
            parts.append(f'<text x="{x + 5:.1f}" y="{top - 12}" font-family="Arial, sans-serif" font-size="12" fill="{color}">{label} @{time_ps}ps</text>')

    parts.append(f'<text x="{left}" y="{height - 8}" font-family="Arial, sans-serif" font-size="13" fill="#555">Fast min path changes D at 1520 ps, inside the 1500-1580 ps hold window. Slow max path changes D at 2420 ps, inside the 2350-2500 ps setup window.</text>')
    parts.append("</svg>")
    path.write_text("\n".join(parts))


def convert_with_sips(source: Path, dest: Path, fmt: str) -> None:
    if shutil.which("sips") is None:
        raise SystemExit("sips is required to render PNG artifacts")
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
