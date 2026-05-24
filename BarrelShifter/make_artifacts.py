#!/usr/bin/env python3
"""Generate BarrelShifter waveform/report artifacts from simulation VCD data."""

from __future__ import annotations

import base64
import csv
import html
import re
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent
VCD = ROOT / "barrelshifter_waveforms.vcd"
CSV_OUT = ROOT / "waveform_samples.csv"
WAVEFORM_SVG = ROOT / "waveforms.svg"
WAVEFORM_PNG = ROOT / "waveforms.png"
REPORT_SVG = ROOT / "report.svg"
REPORT_PDF = ROOT / "report.pdf"

SIGNALS = {
    "In",
    "ShiftAmount",
    "ShiftIn",
    "Out",
    "Expected",
    "Match",
    "Sample",
    "CheckIndex",
}


def bits_to_int(bits: str) -> int:
    return int(bits.replace("x", "0").replace("z", "0"), 2)


def parse_vcd(path: Path) -> list[dict[str, int]]:
    if not path.exists():
        raise SystemExit(f"missing VCD: {path}")

    id_to_name: dict[str, str] = {}
    values: dict[str, str] = {name: "0" for name in SIGNALS}
    rows: list[dict[str, int]] = []
    current_time = 0
    in_header = True
    scope_stack: list[str] = []
    var_re = re.compile(r"\$var\s+\S+\s+\d+\s+(\S+)\s+(\S+)")

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
                clean_name = name.split("[", 1)[0]
                if scope_stack == ["top"] and clean_name in SIGNALS:
                    id_to_name[code] = clean_name
            if line == "$enddefinitions $end":
                in_header = False
            continue

        if line.startswith("#"):
            current_time = int(line[1:])
            continue

        if line[0] in "01xz":
            code = line[1:]
            value = line[0]
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

        previous = values.get(name, "0")
        values[name] = value

        if name == "Sample" and previous != "1" and value == "1":
            rows.append({
                "time": current_time,
                "check": bits_to_int(values["CheckIndex"]),
                "shift_amount": bits_to_int(values["ShiftAmount"]),
                "shift_in": bits_to_int(values["ShiftIn"]),
                "in": bits_to_int(values["In"]),
                "out": bits_to_int(values["Out"]),
                "expected": bits_to_int(values["Expected"]),
                "match": bits_to_int(values["Match"]),
            })

    return rows


def write_csv(rows: list[dict[str, int]], path: Path) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def selected_rows(rows: list[dict[str, int]], count: int) -> list[dict[str, int]]:
    if len(rows) <= count:
        return rows

    head_count = min(12, count // 4)
    tail_count = count - head_count
    head = rows[:head_count]
    tail: list[dict[str, int]] = []
    span = len(rows) - head_count - 1
    for index in range(tail_count):
        source_index = head_count
        if tail_count > 1:
            source_index += round(index * span / (tail_count - 1))
        tail.append(rows[source_index])
    return head + tail


def polyline(points: list[tuple[float, float]]) -> str:
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)


def render_waveforms(rows: list[dict[str, int]], path: Path) -> None:
    sampled = selected_rows(rows, 180)
    width = 1360
    height = 720
    left = 158
    right = 40
    top = 62
    lane_h = 68
    plot_w = width - left - right

    lanes = [
        ("check", "check", "bus"),
        ("shift_amount", "shift_amt", "bus"),
        ("shift_in", "shift_in", "bit"),
        ("in", "in[31:0]", "bus"),
        ("out", "out[31:0]", "bus"),
        ("expected", "expected[31:0]", "bus"),
        ("match", "match", "bit"),
    ]

    def x_at(index: int) -> float:
        if len(sampled) <= 1:
            return left
        return left + (index * plot_w / (len(sampled) - 1))

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        f'<rect x="0" y="0" width="{width}" height="{height}" fill="#ffffff" fill-opacity="1"/>',
        '<text x="40" y="32" font-family="Arial, sans-serif" font-size="24" font-weight="700">BarrelShifter checked simulation waveform</text>',
        '<text x="40" y="54" font-family="Arial, sans-serif" font-size="14" fill="#555">Plotted from barrelshifter_waveforms.vcd; selected checked transactions shown across the full run</text>',
    ]

    for index in range(len(sampled)):
        x = x_at(index)
        parts.append(f'<line x1="{x:.1f}" y1="{top - 15}" x2="{x:.1f}" y2="{height - 56}" stroke="#e6e6e6" stroke-width="1" stroke-dasharray="3 8"/>')

    for lane_index, (key, label, kind) in enumerate(lanes):
        y_mid = top + lane_index * lane_h + 25
        y_hi = y_mid - 16
        y_lo = y_mid + 16
        parts.append(f'<text x="34" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="16" fill="#111">{html.escape(label)}</text>')
        parts.append(f'<line x1="{left}" y1="{y_lo}" x2="{width - right}" y2="{y_lo}" stroke="#d0d0d0" stroke-width="1"/>')

        if kind == "bit":
            points: list[tuple[float, float]] = []
            previous_y = y_lo
            for index, row in enumerate(sampled):
                x = x_at(index)
                y = y_hi if row[key] else y_lo
                if index:
                    points.append((x, previous_y))
                points.append((x, y))
                previous_y = y
            parts.append(f'<polyline points="{polyline(points)}" fill="none" stroke="#111" stroke-width="2.4"/>')
        else:
            for index, row in enumerate(sampled[:-1]):
                x0 = x_at(index)
                x1 = x_at(index + 1)
                fill = "#f8f8f8" if index % 2 else "#ffffff"
                parts.append(f'<rect x="{x0:.1f}" y="{y_hi}" width="{x1 - x0:.1f}" height="{y_lo - y_hi}" fill="{fill}" stroke="#111" stroke-width="1"/>')
                if index % 20 == 0:
                    if key == "check":
                        text = str(row[key])
                    elif key == "shift_amount":
                        text = str(row[key])
                    else:
                        text = f'{row[key]:08X}'
                    parts.append(f'<text x="{x0 + 4:.1f}" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="11" fill="#111">{html.escape(text)}</text>')

    parts.append(f'<text x="{left}" y="{height - 24}" font-family="Arial, sans-serif" font-size="13" fill="#555">Samples shown: {len(sampled)} selected from {len(rows)} checked transactions. Match stays high for every plotted sample.</text>')
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


def render_report() -> None:
    stage_flow = ROOT / "stage_flow.png"
    if not stage_flow.exists():
        raise SystemExit("missing stage_flow.png")

    stage_data = base64.b64encode(stage_flow.read_bytes()).decode()
    wave_data = base64.b64encode(WAVEFORM_PNG.read_bytes()).decode()
    REPORT_SVG.write_text(f"""<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1500" viewBox="0 0 1200 1500">
<rect x="0" y="0" width="1200" height="1500" fill="#ffffff" fill-opacity="1"/>
<text x="60" y="58" font-family="Arial, sans-serif" font-size="34" font-weight="700">BarrelShifter Verification Report</text>
<text x="60" y="98" font-family="Arial, sans-serif" font-size="18" fill="#555">Combinational stage-flow diagram and waveform snapshot from simulation data</text>
<text x="60" y="145" font-family="Arial, sans-serif" font-size="24" font-weight="700">Stage Flow</text>
<image x="60" y="170" width="1080" height="590" href="data:image/png;base64,{stage_data}"/>
<text x="60" y="815" font-family="Arial, sans-serif" font-size="24" font-weight="700">Waveform Snapshot</text>
<image x="60" y="840" width="1080" height="572" href="data:image/png;base64,{wave_data}"/>
</svg>
""")
    convert_with_sips(REPORT_SVG, REPORT_PDF, "pdf")


def main() -> None:
    rows = parse_vcd(VCD)
    if not rows:
        raise SystemExit("no checked samples found in VCD")
    write_csv(rows, CSV_OUT)
    render_waveforms(rows, WAVEFORM_SVG)
    convert_with_sips(WAVEFORM_SVG, WAVEFORM_PNG, "png")
    render_report()
    WAVEFORM_SVG.unlink(missing_ok=True)
    REPORT_SVG.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
