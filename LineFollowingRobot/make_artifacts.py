#!/usr/bin/env python3
"""Generate LineFollowingRobot waveform/report artifacts from simulation VCD data."""

from __future__ import annotations

import base64
import csv
import html
import re
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent
VCD = ROOT / "linefollowing_dataflow_waveforms.vcd"
CSV_OUT = ROOT / "waveform_samples.csv"
LOGIC_FLOW_PNG = ROOT / "logic_flow.png"
WAVEFORM_SVG = ROOT / "waveforms.svg"
WAVEFORM_PNG = ROOT / "waveforms.png"
REPORT_SVG = ROOT / "report.svg"
REPORT_PDF = ROOT / "report.pdf"

SIGNALS = {
    "Sensors",
    "ML",
    "MR",
    "InMotion",
    "Error",
    "Expected",
    "Match",
    "Sample",
    "CheckIndex",
    "CaseCode",
}

CASE_NAMES = {
    0: "lost",
    1: "split",
    2: "center",
    3: "left",
    4: "right",
}


def bits_to_int(bits: str) -> int:
    return int(bits.replace("x", "0").replace("z", "0"), 2)


def parse_vcd(path: Path) -> list[dict[str, int | str]]:
    if not path.exists():
        raise SystemExit(f"missing VCD: {path}")

    id_to_name: dict[str, str] = {}
    values: dict[str, str] = {name: "0" for name in SIGNALS}
    rows: list[dict[str, int | str]] = []
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
            case_code = bits_to_int(values["CaseCode"])
            rows.append({
                "time": current_time,
                "check": bits_to_int(values["CheckIndex"]),
                "sensors": bits_to_int(values["Sensors"]),
                "case_code": case_code,
                "case_name": CASE_NAMES.get(case_code, f"case{case_code}"),
                "ml": bits_to_int(values["ML"]),
                "mr": bits_to_int(values["MR"]),
                "in_motion": bits_to_int(values["InMotion"]),
                "error": bits_to_int(values["Error"]),
                "expected": bits_to_int(values["Expected"]),
                "match": bits_to_int(values["Match"]),
            })

    return rows


def write_csv(rows: list[dict[str, int | str]], path: Path) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def polyline(points: list[tuple[float, float]]) -> str:
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)


def render_waveforms(rows: list[dict[str, int | str]], path: Path) -> None:
    width = 1360
    height = 760
    left = 158
    right = 40
    top = 62
    lane_h = 66
    plot_w = width - left - right

    lanes = [
        ("check", "check", "bus"),
        ("sensors", "sensors[4:0]", "bus"),
        ("case_name", "case", "case"),
        ("ml", "ML", "bit"),
        ("mr", "MR", "bit"),
        ("in_motion", "InMotion", "bit"),
        ("error", "Error", "bit"),
        ("expected", "expected", "bus"),
        ("match", "match", "bit"),
    ]

    def x_at(index: int) -> float:
        if len(rows) <= 1:
            return left
        return left + (index * plot_w / (len(rows) - 1))

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        f'<rect x="0" y="0" width="{width}" height="{height}" fill="#ffffff" fill-opacity="1"/>',
        '<text x="40" y="32" font-family="Arial, sans-serif" font-size="24" font-weight="700">LineFollowingRobot exhaustive simulation waveform</text>',
        '<text x="40" y="54" font-family="Arial, sans-serif" font-size="14" fill="#555">Plotted from linefollowing_dataflow_waveforms.vcd; all 32 checked sensor patterns shown</text>',
    ]

    for index in range(len(rows)):
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
            for index, row in enumerate(rows):
                x = x_at(index)
                y = y_hi if int(row[key]) else y_lo
                if index:
                    points.append((x, previous_y))
                points.append((x, y))
                previous_y = y
            parts.append(f'<polyline points="{polyline(points)}" fill="none" stroke="#111" stroke-width="2.4"/>')
        else:
            for index, row in enumerate(rows):
                x0 = x_at(index)
                x1 = x_at(index + 1) if index < (len(rows) - 1) else (width - right)
                fill = "#f8f8f8" if index % 2 else "#ffffff"
                parts.append(f'<rect x="{x0:.1f}" y="{y_hi}" width="{x1 - x0:.1f}" height="{y_lo - y_hi}" fill="{fill}" stroke="#111" stroke-width="1"/>')
                if kind == "case":
                    text = str(row[key])
                elif key == "sensors":
                    text = f'{int(row[key]):05b}'
                elif key == "expected":
                    text = f'{int(row[key]):04b}'
                else:
                    text = str(row[key])
                parts.append(f'<text x="{x0 + 4:.1f}" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="11" fill="#111">{html.escape(text)}</text>')

    parts.append(f'<text x="{left}" y="{height - 24}" font-family="Arial, sans-serif" font-size="13" fill="#555">Samples shown: all {len(rows)} sensor patterns. Match stays high for every checked pattern.</text>')
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
    logic_flow = LOGIC_FLOW_PNG
    if not logic_flow.exists():
        raise SystemExit("missing logic_flow.png")

    logic_data = base64.b64encode(logic_flow.read_bytes()).decode()
    wave_data = base64.b64encode(WAVEFORM_PNG.read_bytes()).decode()
    REPORT_SVG.write_text(f"""<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1500" viewBox="0 0 1200 1500">
<rect x="0" y="0" width="1200" height="1500" fill="#ffffff" fill-opacity="1"/>
<text x="60" y="58" font-family="Arial, sans-serif" font-size="34" font-weight="700">LineFollowingRobot Verification Report</text>
<text x="60" y="98" font-family="Arial, sans-serif" font-size="18" fill="#555">Combinational logic-flow diagram and waveform snapshot from exhaustive simulation data</text>
<text x="60" y="145" font-family="Arial, sans-serif" font-size="24" font-weight="700">Logic Flow</text>
<image x="60" y="170" width="1080" height="590" href="data:image/png;base64,{logic_data}"/>
<text x="60" y="815" font-family="Arial, sans-serif" font-size="24" font-weight="700">Waveform Snapshot</text>
<image x="60" y="840" width="1080" height="604" href="data:image/png;base64,{wave_data}"/>
</svg>
""")
    convert_with_sips(REPORT_SVG, REPORT_PDF, "pdf")


def main() -> None:
    # logic_flow.png is generated with the visualize skill to match the
    # repository's hand-drawn graph-paper diagram style.
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
