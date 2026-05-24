#!/usr/bin/env python3
"""Generate MemoryZeroController waveform artifacts from farm VCD data."""

from __future__ import annotations

import csv
import html
import re
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent
VCD = ROOT / "memoryzero_waveforms.vcd"
CSV_OUT = ROOT / "waveform_samples.csv"
WAVEFORM_SVG = ROOT / "waveforms.svg"
WAVEFORM_PNG = ROOT / "waveforms.png"

VAR_RE = re.compile(r"\$var\s+\S+\s+(\d+)\s+(\S+)\s+(\S+)(?:\s+(\[[^\]]+\]))?\s+\$end")

WATCH_KEYS = [
    "clock",
    "reset",
    "zero",
    "busy",
    "write",
    "addr",
    "din",
    "dout",
    "DUT.set_busy",
    "DUT.clr_busy",
    "DUT.ld_cnt",
    "DUT.cnt_en",
    "DUT.addr_sel",
    "DUT.zero_we",
    "DUT.cnt_eq",
    "DUT.FSM.State",
    "DUT.FSM.NextState",
    "DUT.DP.dina",
    "DUT.DP.dcnt",
    "DUT.DP.dinb",
    "DUT.DP.addrm",
    "DUT.DP.dinm",
    "DUT.DP.mem_we",
]

STATE_NAMES = {
    "00": "Init",
    "01": "Load",
    "10": "Write",
    "11": "unused",
}


def convert_with_sips(source: Path, dest: Path, fmt: str) -> None:
    if shutil.which("sips") is None:
        raise SystemExit("sips is required to render PNG artifacts")
    subprocess.run(
        ["sips", "-s", "format", fmt, str(source), "--out", str(dest)],
        check=True,
        stdout=subprocess.DEVNULL,
    )


def normalize_bits(bits: str, width: int) -> str:
    clean = bits.lower().replace("z", "x")
    if len(clean) >= width:
        return clean[-width:]
    return clean.rjust(width, "0")


def bits_to_int(bits: str) -> int | None:
    if not bits or any(bit not in "01" for bit in bits):
        return None
    return int(bits, 2)


def bits_to_hex(bits: str) -> str:
    value = bits_to_int(bits)
    if value is None:
        return "x"
    width = max(1, (len(bits) + 3) // 4)
    return f"0x{value:0{width}X}"


def state_name(bits: str) -> str:
    return STATE_NAMES.get(bits, "X")


def parse_vcd(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise SystemExit(f"missing VCD: {path}")

    id_to_signal: dict[str, tuple[str, int | None]] = {}
    widths: dict[str, int] = {}
    scalar_values: dict[str, str] = {}
    bit_values: dict[str, dict[int, str]] = {}
    rows: list[dict[str, str]] = []
    scope_stack: list[str] = []
    current_time: int | None = None
    in_header = True
    changed = False

    def make_key(name: str) -> str:
        if scope_stack == ["top"]:
            return name
        if scope_stack and scope_stack[0] == "top":
            return ".".join([*scope_stack[1:], name])
        return ".".join([*scope_stack, name])

    def get_value(key: str) -> str:
        if key in scalar_values:
            return normalize_bits(scalar_values[key], widths.get(key, len(scalar_values[key])))
        if key in bit_values:
            width = widths[key]
            return "".join(bit_values[key].get(index, "x") for index in range(width - 1, -1, -1))
        return "x"

    def append_snapshot() -> None:
        if current_time is None:
            return
        row = {"time_ns": str(current_time)}
        for key in WATCH_KEYS:
            row[key] = get_value(key)
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
            if match:
                width_text, code, name, range_text = match.groups()
                key = make_key(name)
                bit_index = None
                if range_text and ":" not in range_text:
                    bit_index = int(range_text.strip("[]"))
                id_to_signal[code] = (key, bit_index)
                if bit_index is None:
                    widths[key] = int(width_text)
                else:
                    widths[key] = max(widths.get(key, 0), bit_index + 1)
                    bit_values.setdefault(key, {})[bit_index] = "x"
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
            value = line[0].lower()
            code = line[1:]
        elif line[0] in "bB":
            fields = line[1:].split()
            if len(fields) != 2:
                continue
            value, code = fields
            value = value.lower()
        else:
            continue

        signal = id_to_signal.get(code)
        if signal is None:
            continue
        key, bit_index = signal
        if bit_index is None:
            scalar_values[key] = value
        else:
            bit_values.setdefault(key, {})[bit_index] = value
        changed = True

    if changed:
        append_snapshot()

    return rows


def rising_edge_samples(rows: list[dict[str, str]]) -> list[dict[str, str | int]]:
    samples: list[dict[str, str | int]] = []
    previous_clock = "x"
    for row in rows:
        clock = row["clock"][-1]
        if previous_clock == "0" and clock == "1":
            state_bits = normalize_bits(row["DUT.FSM.State"], 2)
            next_bits = normalize_bits(row["DUT.FSM.NextState"], 2)
            counter = bits_to_int(row["DUT.DP.dinb"])
            samples.append({
                "time_ns": int(row["time_ns"]),
                "state": state_name(state_bits),
                "state_bits": state_bits,
                "next_state": state_name(next_bits),
                "next_state_bits": next_bits,
                "zero": int(row["zero"] == "1"),
                "busy": int(row["busy"] == "1"),
                "write": int(row["write"] == "1"),
                "set_busy": int(row["DUT.set_busy"] == "1"),
                "clr_busy": int(row["DUT.clr_busy"] == "1"),
                "ld_cnt": int(row["DUT.ld_cnt"] == "1"),
                "cnt_en": int(row["DUT.cnt_en"] == "1"),
                "addr_sel": int(row["DUT.addr_sel"] == "1"),
                "zero_we": int(row["DUT.zero_we"] == "1"),
                "mem_we": int(row["DUT.DP.mem_we"] == "1"),
                "cnt_eq": int(row["DUT.cnt_eq"] == "1"),
                "counter": "" if counter is None else counter,
                "addr": bits_to_hex(row["addr"]),
                "addrm": bits_to_hex(row["DUT.DP.addrm"]),
                "dina_high": bits_to_hex(row["DUT.DP.dina"]),
                "dcnt_low": bits_to_hex(row["DUT.DP.dcnt"]),
                "din": bits_to_hex(row["din"]),
                "dinm": bits_to_hex(row["DUT.DP.dinm"]),
                "dout": bits_to_hex(row["dout"]),
            })
        previous_clock = clock
    return samples


def write_csv(rows: list[dict[str, str | int]], path: Path) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def polyline(points: list[tuple[float, float]]) -> str:
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)


def bus_label(row: dict[str, str], key: str) -> str:
    if key == "DUT.FSM.State":
        return state_name(normalize_bits(row[key], 2))
    if key == "DUT.DP.dinb":
        value = bits_to_int(row[key])
        return "x" if value is None else str(value)
    return bits_to_hex(row[key])


def render_waveforms(rows: list[dict[str, str]], path: Path) -> None:
    window_ns = 340
    visible = [row for row in rows if int(row["time_ns"]) <= window_ns]
    if len(visible) < 2:
        raise SystemExit("not enough waveform samples to render")

    width = 1500
    left = 160
    right = 44
    top = 88
    lane_h = 54
    bit_lanes = [
        ("clock", "clock"),
        ("zero", "zero"),
        ("busy", "busy"),
        ("write", "write"),
        ("DUT.set_busy", "set_busy"),
        ("DUT.clr_busy", "clr_busy"),
        ("DUT.ld_cnt", "ld_cnt"),
        ("DUT.cnt_en", "cnt_en"),
        ("DUT.zero_we", "zero_we"),
        ("DUT.DP.mem_we", "mem_we"),
    ]
    bus_lanes = [
        ("DUT.FSM.State", "state"),
        ("DUT.DP.dinb", "counter"),
        ("addr", "addr"),
        ("DUT.DP.addrm", "addrm"),
        ("dout", "dout"),
    ]
    height = top + (len(bit_lanes) + len(bus_lanes)) * lane_h + 90
    plot_w = width - left - right
    max_time = int(visible[-1]["time_ns"])

    def x_at(time_ns: int) -> float:
        return left + (time_ns * plot_w / max_time)

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        f'<rect x="0" y="0" width="{width}" height="{height}" fill="#ffffff"/>',
        '<text x="44" y="36" font-family="Arial, sans-serif" font-size="24" font-weight="700">MemoryZeroController farm waveform</text>',
        f'<text x="44" y="60" font-family="Arial, sans-serif" font-size="14" fill="#555">Rendered from memoryzero_waveforms.vcd; first {window_ns} ns of the failing PSU Questa run shown</text>',
    ]

    for tick in range(0, max_time + 1, 20):
        x = x_at(tick)
        parts.append(f'<line x1="{x:.1f}" y1="{top - 22}" x2="{x:.1f}" y2="{height - 56}" stroke="#e8e8e8" stroke-width="1"/>')
        parts.append(f'<text x="{x:.1f}" y="{height - 34}" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#555">{tick}</text>')

    lane_index = 0
    for key, label in bit_lanes:
        y_mid = top + lane_index * lane_h + 21
        y_hi = y_mid - 15
        y_lo = y_mid + 15
        parts.append(f'<text x="34" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="15">{html.escape(label)}</text>')
        parts.append(f'<line x1="{left}" y1="{y_lo}" x2="{width - right}" y2="{y_lo}" stroke="#d4d4d4" stroke-width="1"/>')
        points: list[tuple[float, float]] = []
        previous_y: float | None = None
        for index, row in enumerate(visible):
            x = x_at(int(row["time_ns"]))
            y = y_hi if row[key][-1] == "1" else y_lo
            if index and previous_y is not None:
                points.append((x, previous_y))
            points.append((x, y))
            previous_y = y
        parts.append(f'<polyline points="{polyline(points)}" fill="none" stroke="#111" stroke-width="2.2"/>')
        lane_index += 1

    for key, label in bus_lanes:
        y_mid = top + lane_index * lane_h + 21
        y_hi = y_mid - 17
        y_lo = y_mid + 17
        parts.append(f'<text x="34" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="15">{html.escape(label)}</text>')
        runs: list[tuple[int, int, str]] = []
        run_start = int(visible[0]["time_ns"])
        run_text = bus_label(visible[0], key)
        for row in visible[1:]:
            text = bus_label(row, key)
            time_ns = int(row["time_ns"])
            if text != run_text:
                runs.append((run_start, time_ns, run_text))
                run_start = time_ns
                run_text = text
        runs.append((run_start, max_time, run_text))

        for index, (start_time, end_time, _text) in enumerate(runs):
            x0 = x_at(start_time)
            x1 = x_at(end_time)
            fill = "#f8f8f8" if index % 2 else "#ffffff"
            parts.append(f'<rect x="{x0:.1f}" y="{y_hi}" width="{max(x1 - x0, 1):.1f}" height="{y_lo - y_hi}" fill="{fill}" stroke="#111" stroke-width="1"/>')
        for start_time, end_time, text in runs:
            x0 = x_at(start_time)
            x1 = x_at(end_time)
            if (x1 - x0) > 25:
                parts.append(f'<text x="{x0 + 4:.1f}" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="11">{html.escape(text[:14])}</text>')
        lane_index += 1

    note = (
        "The second zero pulse arrives while the first sweep is still in Write, showing the testbench completed its "
        "busy wait before the zero operation was actually done."
    )
    parts.append(f'<text x="{left}" y="{height - 10}" font-family="Arial, sans-serif" font-size="13" fill="#555">{html.escape(note)}</text>')
    parts.append("</svg>")
    path.write_text("\n".join(parts))


def main() -> None:
    rows = parse_vcd(VCD)
    if not rows:
        raise SystemExit("no waveform rows found in VCD")
    samples = rising_edge_samples(rows)
    if not samples:
        raise SystemExit("no rising-edge samples found in VCD")
    write_csv(samples, CSV_OUT)
    render_waveforms(rows, WAVEFORM_SVG)
    convert_with_sips(WAVEFORM_SVG, WAVEFORM_PNG, "png")
    WAVEFORM_SVG.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
