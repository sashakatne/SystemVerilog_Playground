#!/usr/bin/env python3
"""Generate waveform and report artifacts from the simulation VCD."""

from __future__ import annotations

import base64
import csv
import html
import re
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent
VCD = ROOT / "fpclass_waveforms.vcd"
CSV_OUT = ROOT / "waveform_samples.csv"
WAVEFORM_SVG = ROOT / "waveforms.svg"
WAVEFORM_PNG = ROOT / "waveforms.png"
REPORT_SVG = ROOT / "report.svg"
REPORT_PDF = ROOT / "report.pdf"

SIGNALS = {
    "Clock": "clk",
    "Mode": "mode",
    "RandomizeOK": "ok",
    "SignSample": "sign",
    "ExponentSample": "exp",
    "DenormSample": "denorm",
    "NanSample": "nan",
    "InfSample": "inf",
    "RangeSample": "range",
    "ErrorSeen": "error",
}

MODE_NAMES = {
    0: "direct",
    1: "nodenorm",
    2: "alldenorm",
    3: "nonan",
    4: "noinf",
    5: "exprange",
    6: "combined",
}


def parse_vcd(path: Path) -> list[dict[str, int | str]]:
    if not path.exists():
        raise SystemExit(f"missing VCD: {path}")

    id_to_name: dict[str, str] = {}
    values: dict[str, str] = {name: "0" for name in SIGNALS}
    rows: list[dict[str, int | str]] = []
    current_time = 0
    in_header = True

    var_re = re.compile(r"\$var\s+\S+\s+\d+\s+(\S+)\s+(\S+)")

    for raw_line in path.read_text(errors="replace").splitlines():
        line = raw_line.strip()
        if not line:
            continue

        if in_header:
            match = var_re.match(line)
            if match:
                code, name = match.groups()
                if name in SIGNALS:
                    id_to_name[code] = name
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
            bits, code = line[1:].split()
            value = bits.replace("x", "0").replace("z", "0")
        else:
            continue

        name = id_to_name.get(code)
        if name is None:
            continue

        values[name] = value

        if name == "Clock" and value == "1":
            mode = int(values["Mode"], 2)
            row = {
                "time": current_time,
                "mode": mode,
                "mode_name": MODE_NAMES.get(mode, f"mode{mode}"),
                "ok": int(values["RandomizeOK"], 2),
                "sign": int(values["SignSample"], 2),
                "exp": int(values["ExponentSample"], 2),
                "denorm": int(values["DenormSample"], 2),
                "nan": int(values["NanSample"], 2),
                "inf": int(values["InfSample"], 2),
                "range": int(values["RangeSample"], 2),
                "error": int(values["ErrorSeen"], 2),
            }
            rows.append(row)

    return rows


def write_csv(rows: list[dict[str, int | str]], path: Path) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def polyline(points: list[tuple[float, float]]) -> str:
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)


def render_waveforms(rows: list[dict[str, int | str]], path: Path) -> None:
    max_rows = min(len(rows), 180)
    if len(rows) <= max_rows:
        sampled = rows
    else:
        head_count = min(8, max_rows // 4)
        tail_count = max_rows - head_count
        head = rows[:head_count]
        tail: list[dict[str, int | str]] = []
        span = len(rows) - head_count - 1
        for index in range(tail_count):
            source_index = head_count
            if tail_count > 1:
                source_index += round(index * span / (tail_count - 1))
            tail.append(rows[source_index])
        sampled = head + tail

    width = 1360
    height = 760
    left = 160
    right = 40
    top = 60
    lane_h = 62
    plot_w = width - left - right

    lanes = [
        ("mode", "mode", "bus"),
        ("ok", "randomize_ok", "bit"),
        ("sign", "sign", "bit"),
        ("exp", "exponent[7:0]", "bus"),
        ("denorm", "denorm", "bit"),
        ("nan", "nan", "bit"),
        ("inf", "inf", "bit"),
        ("range", "in_range", "bit"),
        ("error", "error_seen", "bit"),
    ]

    def x_at(index: int) -> float:
        if max_rows <= 1:
            return left
        return left + (index * plot_w / (max_rows - 1))

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        f'<rect x="0" y="0" width="{width}" height="{height}" fill="#ffffff" fill-opacity="1"/>',
        '<text x="40" y="32" font-family="Arial, sans-serif" font-size="24" font-weight="700">Floating-point class randomized simulation waveform</text>',
        '<text x="40" y="54" font-family="Arial, sans-serif" font-size="14" fill="#555">Plotted from fpclass_waveforms.vcd; directed probes plus samples across the full run shown</text>',
    ]

    for index in range(max_rows):
        x = x_at(index)
        parts.append(f'<line x1="{x:.1f}" y1="{top - 15}" x2="{x:.1f}" y2="{height - 60}" stroke="#e6e6e6" stroke-width="1" stroke-dasharray="3 8"/>')

    for lane_index, (key, label, kind) in enumerate(lanes):
        y_mid = top + lane_index * lane_h + 24
        y_hi = y_mid - 16
        y_lo = y_mid + 16
        parts.append(f'<text x="34" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="16" fill="#111">{html.escape(label)}</text>')
        parts.append(f'<line x1="{left}" y1="{y_lo}" x2="{width - right}" y2="{y_lo}" stroke="#d0d0d0" stroke-width="1"/>')

        if kind == "bit":
            points: list[tuple[float, float]] = []
            previous_y = y_lo
            for index, row in enumerate(sampled):
                x = x_at(index)
                y = y_hi if int(row[key]) else y_lo
                if index:
                    points.append((x, previous_y))
                points.append((x, y))
                previous_y = y
            parts.append(f'<polyline points="{polyline(points)}" fill="none" stroke="#111" stroke-width="2.4"/>')
        else:
            if key == "mode":
                segment_start = 0
                while segment_start < max_rows:
                    segment_mode = sampled[segment_start]["mode"]
                    segment_end = segment_start + 1
                    while segment_end < max_rows and sampled[segment_end]["mode"] == segment_mode:
                        segment_end += 1
                    x0 = x_at(segment_start)
                    x1 = x_at(segment_end - 1)
                    if segment_end < max_rows:
                        x1 = x_at(segment_end)
                    else:
                        x1 = width - right
                    fill = "#f8f8f8" if int(segment_mode) % 2 else "#ffffff"
                    parts.append(f'<rect x="{x0:.1f}" y="{y_hi}" width="{x1 - x0:.1f}" height="{y_lo - y_hi}" fill="{fill}" stroke="#111" stroke-width="1.2"/>')
                    parts.append(f'<text x="{x0 + 6:.1f}" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="12" fill="#111">{html.escape(str(sampled[segment_start]["mode_name"]))}</text>')
                    segment_start = segment_end
            else:
                for index, row in enumerate(sampled):
                    if index == max_rows - 1:
                        break
                    x0 = x_at(index)
                    x1 = x_at(index + 1)
                    value = row[key]
                    fill = "#f8f8f8" if index % 2 else "#ffffff"
                    parts.append(f'<rect x="{x0:.1f}" y="{y_hi}" width="{x1 - x0:.1f}" height="{y_lo - y_hi}" fill="{fill}" stroke="#111" stroke-width="1"/>')
                    if index % 18 == 0:
                        parts.append(f'<text x="{x0 + 4:.1f}" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="12" fill="#111">0x{int(value):02X}</text>')

    parts.append(f'<text x="{left}" y="{height - 24}" font-family="Arial, sans-serif" font-size="13" fill="#555">Samples shown: {len(sampled)} selected from {len(rows)} rising edges. Dotted guides mark plotted samples.</text>')
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
    fsm = ROOT / "fsm.png"
    if not fsm.exists():
        raise SystemExit("missing fsm.png; generate the FSM diagram first")

    fsm_data = base64.b64encode(fsm.read_bytes()).decode()
    wave_data = base64.b64encode(WAVEFORM_PNG.read_bytes()).decode()
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1500" viewBox="0 0 1200 1500">
<rect x="0" y="0" width="1200" height="1500" fill="#ffffff" fill-opacity="1"/>
<text x="60" y="58" font-family="Arial, sans-serif" font-size="34" font-weight="700">Floating-Point Class Randomization Report</text>
<text x="60" y="98" font-family="Arial, sans-serif" font-size="18" fill="#555">FSM-style verification flow and waveform snapshot from simulation data</text>
<text x="60" y="145" font-family="Arial, sans-serif" font-size="24" font-weight="700">Verification Flow</text>
<image x="60" y="170" width="1080" height="590" href="data:image/png;base64,{fsm_data}"/>
<text x="60" y="815" font-family="Arial, sans-serif" font-size="24" font-weight="700">Waveform Snapshot</text>
<image x="60" y="840" width="1080" height="604" href="data:image/png;base64,{wave_data}"/>
</svg>
"""
    REPORT_SVG.write_text(svg)
    convert_with_sips(REPORT_SVG, REPORT_PDF, "pdf")


def main() -> None:
    rows = parse_vcd(VCD)
    if not rows:
        raise SystemExit("no rising-edge samples found in VCD")

    write_csv(rows, CSV_OUT)
    render_waveforms(rows, WAVEFORM_SVG)
    convert_with_sips(WAVEFORM_SVG, WAVEFORM_PNG, "png")
    render_report()

    WAVEFORM_SVG.unlink(missing_ok=True)
    REPORT_SVG.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
