#!/usr/bin/env python3
"""Generate FindFirstOne_Sequential diagrams and waveform artifacts."""

from __future__ import annotations

import csv
import html
import re
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent

VARIANTS = {
    "moore": {
        "vcd": ROOT / "moore.vcd",
        "csv": ROOT / "waveform_moore.csv",
        "wave": ROOT / "waveform_moore.png",
        "window_ns": 1000,
        "state_key": "DUT.state",
        "next_state_key": "DUT.next_state",
        "p_order": [0, 1, 2, 3, 4],
        "pe_order": [0, 1, 2, 3, 4],
        "state_names": {
            "0001": "INIT",
            "0010": "LOAD",
            "0100": "EVAL",
            "1000": "SHIFT",
        },
        "bit_lanes": ["clock", "reset", "start", "ready", "v", "ve", "error"],
        "bus_lanes": ["state", "next", "p", "pe", "b"],
    },
    "mealy": {
        "vcd": ROOT / "mealy.vcd",
        "csv": ROOT / "waveform_mealy.csv",
        "wave": ROOT / "waveform_mealy.png",
        "window_ns": 2600,
        "state_key": "DUT.State",
        "next_state_key": "DUT.NextState",
        "p_order": [0, 1, 2, 3, 4],
        "pe_order": [0, 1, 2, 3, 4],
        "state_names": {
            "01": "IDLE",
            "10": "CHECK",
        },
        "bit_lanes": ["clock", "reset", "start", "ready", "v", "ve", "error"],
        "bus_lanes": ["state", "next", "p", "pe", "b"],
    },
    "pipeline": {
        "vcd": ROOT / "pipeline.vcd",
        "csv": ROOT / "waveform_pipeline.csv",
        "wave": ROOT / "waveform_pipeline.png",
        "window_ns": 1600,
        "p_order": [4, 3, 2, 1, 0],
        "pe_order": [4, 3, 2, 1, 0],
        "bit_lanes": ["clock", "v", "ve", "error"],
        "bus_lanes": ["p", "pe", "b", "stage_valid"],
    },
}


VAR_RE = re.compile(r"\$var\s+\S+\s+(\d+)\s+(\S+)\s+(\S+)(?:\s+(\[[^\]]+\]))?\s+\$end")


def bits_to_int(bits: str) -> int:
    return int(bits.replace("x", "0").replace("z", "0"), 2)


def normalize_bits(bits: str, width: int) -> str:
    clean = bits.lower().replace("z", "x")
    if len(clean) >= width:
        return clean[-width:]
    return clean.rjust(width, "0")


def parse_index(range_text: str | None) -> int | None:
    if range_text is None:
        return None
    inner = range_text.strip("[]")
    if ":" in inner:
        return None
    return int(inner)


def parse_vcd(path: Path) -> tuple[list[dict[str, str]], dict[str, int]]:
    if not path.exists():
        raise SystemExit(f"missing VCD: {path}")

    id_to_signal: dict[str, tuple[str, int | None]] = {}
    widths: dict[str, int] = {}
    scalar_values: dict[str, str] = {}
    bit_values: dict[str, dict[int, str]] = {}
    rows: list[dict[str, str]] = []
    current_time: int | None = None
    changed = False
    in_header = True
    scope_stack: list[str] = []

    def make_key(name: str) -> str:
        if scope_stack == ["top"]:
            return f"top.{name}"
        if scope_stack == ["top", "DUT"]:
            return f"DUT.{name}"
        return ".".join([*scope_stack, name])

    def get_value(key: str) -> str:
        if key in scalar_values:
            return normalize_bits(scalar_values[key], widths.get(key, len(scalar_values[key])))
        if key in bit_values:
            indices = sorted(bit_values[key])
            return "".join(bit_values[key].get(index, "x") for index in indices)
        return "x"

    def append_snapshot() -> None:
        if current_time is None:
            return
        row = {"time_ns": str(current_time)}
        for key in sorted(set(widths) | set(scalar_values) | set(bit_values)):
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
                width = int(width_text)
                key = make_key(name)
                bit_index = parse_index(range_text)
                id_to_signal[code] = (key, bit_index)
                if bit_index is None:
                    widths[key] = width
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

    return rows, widths


def row_get(row: dict[str, str], key: str, default: str = "x") -> str:
    return row.get(key, default)


def bit(row: dict[str, str], key: str) -> int:
    value = row_get(row, key)
    return 1 if value and value[-1] == "1" else 0


def vector(row: dict[str, str], key: str, order: list[int] | None = None) -> str:
    value = row_get(row, key)
    if order is None or len(value) <= 1:
        return value
    chars = []
    for index in order:
        if index < len(value):
            chars.append(value[index])
        else:
            chars.append("x")
    return "".join(chars)


def b_label(bits: str) -> str:
    if not bits or set(bits) <= {"x"}:
        return "x"
    clean = bits.replace("x", "0")
    ones = [index for index, char in enumerate(clean) if char == "1"]
    if len(ones) == 1:
        return f"1@{ones[0]}"
    if not ones:
        return "0"
    return f"{len(ones)} ones"


def process_variant(name: str, rows: list[dict[str, str]], config: dict[str, object]) -> list[dict[str, str | int]]:
    processed: list[dict[str, str | int]] = []
    p_order = config["p_order"]  # type: ignore[index]
    pe_order = config["pe_order"]  # type: ignore[index]
    state_names = config.get("state_names", {})  # type: ignore[assignment]

    for row in rows:
        p_bits = vector(row, "top.p", p_order)  # type: ignore[arg-type]
        pe_bits = vector(row, "top.pe", pe_order)  # type: ignore[arg-type]
        b_bits = row_get(row, "top.b")
        out: dict[str, str | int] = {
            "time_ns": int(row["time_ns"]),
            "clock": bit(row, "top.clock"),
            "v": bit(row, "top.v"),
            "ve": bit(row, "top.ve"),
            "p_bits": p_bits,
            "p_dec": bits_to_int(p_bits) if set(p_bits) <= {"0", "1"} else "",
            "pe_bits": pe_bits,
            "pe_dec": bits_to_int(pe_bits) if set(pe_bits) <= {"0", "1"} else "",
            "b": b_label(b_bits),
            "error": bit(row, "top.error_flag") if name == "moore" else bit(row, "top.Error"),
        }

        if name in {"moore", "mealy"}:
            state_bits = row_get(row, config["state_key"])  # type: ignore[index]
            next_bits = row_get(row, config["next_state_key"])  # type: ignore[index]
            state_width = 4 if name == "moore" else 2
            state_bits = normalize_bits(state_bits, state_width)
            next_bits = normalize_bits(next_bits, state_width)
            out.update({
                "reset": bit(row, "top.reset"),
                "start": bit(row, "top.start"),
                "ready": bit(row, "top.ready"),
                "state_bits": state_bits,
                "state": state_names.get(state_bits, state_bits),  # type: ignore[union-attr]
                "next_state_bits": next_bits,
                "next": state_names.get(next_bits, next_bits),  # type: ignore[union-attr]
            })
            if name == "moore":
                count_bits = normalize_bits(row_get(row, "DUT.counter_out"), 5)
                out["count"] = bits_to_int(count_bits) if set(count_bits) <= {"0", "1"} else ""
            else:
                count_bits = normalize_bits(row_get(row, "DUT.Count"), 32)
                out["count"] = bits_to_int(count_bits[-5:]) if set(count_bits[-5:]) <= {"0", "1"} else ""
        else:
            out["stage_valid"] = "warmup" if int(row["time_ns"]) < 500 else "valid"

        processed.append(out)

    return processed


def write_csv(rows: list[dict[str, str | int]], path: Path) -> None:
    fieldnames: list[str] = []
    for row in rows:
        for key in row:
            if key not in fieldnames:
                fieldnames.append(key)
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def polyline(points: list[tuple[float, float]]) -> str:
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)


def render_waveform(name: str, rows: list[dict[str, str | int]], config: dict[str, object], path: Path) -> None:
    window_ns = int(config["window_ns"])
    visible = [row for row in rows if int(row["time_ns"]) <= window_ns]
    if len(visible) < 2:
        raise SystemExit(f"not enough {name} waveform samples")

    bit_lanes: list[str] = config["bit_lanes"]  # type: ignore[assignment]
    bus_lanes: list[str] = config["bus_lanes"]  # type: ignore[assignment]
    lane_count = len(bit_lanes) + len(bus_lanes)
    width = 1400
    left = 150
    right = 44
    top = 82
    lane_h = 58
    height = top + lane_count * lane_h + 92
    plot_w = width - left - right
    max_time = int(visible[-1]["time_ns"])

    def x_at(time_ns: int) -> float:
        return left + (time_ns * plot_w / max_time)

    title = {
        "moore": "FindFirstOne Sequential Moore waveform",
        "mealy": "FindFirstOne Sequential Mealy waveform",
        "pipeline": "FindFirstOne pipelined waveform",
    }[name]

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        f'<rect x="0" y="0" width="{width}" height="{height}" fill="#ffffff"/>',
        f'<text x="40" y="36" font-family="Arial, sans-serif" font-size="24" font-weight="700">{html.escape(title)}</text>',
        f'<text x="40" y="60" font-family="Arial, sans-serif" font-size="14" fill="#555">Rendered from farm VCD; first {window_ns} ns shown</text>',
    ]

    tick_step = 200 if max_time <= 3000 else 500
    for tick in range(0, max_time + 1, tick_step):
        x = x_at(tick)
        parts.append(f'<line x1="{x:.1f}" y1="{top - 20}" x2="{x:.1f}" y2="{height - 54}" stroke="#e8e8e8" stroke-width="1"/>')
        parts.append(f'<text x="{x:.1f}" y="{height - 30}" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#555">{tick}</text>')

    lane_index = 0
    for key in bit_lanes:
        y_mid = top + lane_index * lane_h + 22
        y_hi = y_mid - 15
        y_lo = y_mid + 15
        parts.append(f'<text x="34" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="15">{html.escape(key)}</text>')
        parts.append(f'<line x1="{left}" y1="{y_lo}" x2="{width - right}" y2="{y_lo}" stroke="#d6d6d6" stroke-width="1"/>')
        points: list[tuple[float, float]] = []
        previous_y: float | None = None
        for index, row in enumerate(visible):
            x = x_at(int(row["time_ns"]))
            y = y_hi if int(row.get(key, 0)) else y_lo
            if index and previous_y is not None:
                points.append((x, previous_y))
            points.append((x, y))
            previous_y = y
        parts.append(f'<polyline points="{polyline(points)}" fill="none" stroke="#111" stroke-width="2.3"/>')
        lane_index += 1

    for key in bus_lanes:
        y_mid = top + lane_index * lane_h + 22
        y_hi = y_mid - 17
        y_lo = y_mid + 17
        parts.append(f'<text x="34" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="15">{html.escape(key)}</text>')
        runs: list[tuple[int, int, str]] = []
        run_start = int(visible[0]["time_ns"])
        run_text = str(visible[0].get(key, visible[0].get(f"{key}_dec", "")))
        for row in visible[1:]:
            text = str(row.get(key, row.get(f"{key}_dec", "")))
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
            if (x1 - x0) > 24:
                parts.append(f'<text x="{x0 + 4:.1f}" y="{y_mid + 5}" font-family="Arial, sans-serif" font-size="11">{html.escape(text[:16])}</text>')
        lane_index += 1

    if name == "pipeline":
        note = "Pipeline output is checked against a 5-cycle delayed KGD queue in the testbench."
    else:
        note = "Ready marks the comparison point against the combinational KGD reference."
    parts.append(f'<text x="{left}" y="{height - 8}" font-family="Arial, sans-serif" font-size="13" fill="#555">{html.escape(note)}</text>')
    parts.append("</svg>")
    svg_path = path.with_suffix(".svg")
    svg_path.write_text("\n".join(parts))
    convert_with_sips(svg_path, path, "png")
    svg_path.unlink(missing_ok=True)


def convert_with_sips(source: Path, dest: Path, fmt: str) -> None:
    if shutil.which("sips") is None:
        raise SystemExit("sips is required to render PNG artifacts")
    subprocess.run(
        ["sips", "-s", "format", fmt, str(source), "--out", str(dest)],
        check=True,
        stdout=subprocess.DEVNULL,
    )


def main() -> None:
    for name, config in VARIANTS.items():
        rows, _widths = parse_vcd(config["vcd"])  # type: ignore[arg-type]
        processed = process_variant(name, rows, config)
        write_csv(processed, config["csv"])  # type: ignore[arg-type]
        render_waveform(name, processed, config, config["wave"])  # type: ignore[arg-type]

    # FSM and pipeline-flow PNGs are generated with the visualize skill to match
    # the repository's hand-drawn graph-paper style. This script owns waveforms.


if __name__ == "__main__":
    main()
