#!/usr/bin/env python3
"""Small compiler/linker simulator used only by runner_selftest.py."""

import json
import os
import re
import signal
import sys
import time
from pathlib import Path
from typing import Dict, List


DIRECTIVE_RE = re.compile(r"FAKE-([A-Z-]+):\s*(.*)$")


def directives(text: str) -> Dict[str, List[str]]:
    result: Dict[str, List[str]] = {}
    for line in text.splitlines():
        match = DIRECTIVE_RE.search(line)
        if match is not None:
            result.setdefault(match.group(1), []).append(match.group(2).strip())
    return result


def literal_stop_status(text: str) -> int:
    statements = re.findall(
        r"error\s+stop(?P<rest>[^\n!]*)",
        text,
        re.IGNORECASE,
    )
    if not statements:
        return 0
    normalized = re.sub(r"\s+", "", statements[-1].lower())
    status = 40 + sum(ord(character) for character in normalized) % 70
    if status in {126, 127}:
        status -= 2
    return status


def option_value(arguments: List[str], option: str) -> str:
    try:
        return arguments[arguments.index(option) + 1]
    except (ValueError, IndexError):
        raise SystemExit("fake compiler: missing {}".format(option))


def marker_target(text: str) -> int:
    lines = text.splitlines()
    for index, line in enumerate(lines, 1):
        if "TEST-ERROR-HERE" not in line:
            continue
        before = line.split("!", 1)[0].strip()
        if before:
            return index
        target = index + 1
        while target <= len(lines):
            candidate = lines[target - 1].strip()
            if candidate and not candidate.startswith("!"):
                return target
            target += 1
    return 1


def compile_source(arguments: List[str]) -> int:
    source = Path(option_value(arguments, "-c")).resolve()
    output = Path(option_value(arguments, "-o")).resolve()
    text = source.read_text(encoding="utf-8", errors="replace")
    values = directives(text)
    if "COMPILE-SLEEP" in values:
        time.sleep(float(values["COMPILE-SLEEP"][-1]))
    if "ECHO-SOURCE" in values:
        sys.stderr.write(text)
    for diagnostic in values.get("DIAGNOSTIC", []):
        parts = diagnostic.split("|", 2)
        if len(parts) != 3:
            raise SystemExit("bad FAKE-DIAGNOSTIC")
        line_text, severity, message = parts
        line = marker_target(text) if line_text == "HERE" else int(line_text)
        sys.stderr.write(
            "{}:{}:1: {}: {}\n".format(source, line, severity, message)
        )
    for diagnostic in values.get("RAW-DIAGNOSTIC", []):
        sys.stderr.write(
            diagnostic.replace("{source}", str(source)).replace(
                "{here}", str(marker_target(text))
            )
            + "\n"
        )
    if (
        "FGS-AUTO-GENERIC-PREREQUISITE-PASS" in text
        and os.environ.get("FAKE_REJECT_PREREQUISITE") == "1"
    ):
        sys.stderr.write(
            "{}:4:3: Error: unsupported GENERIC syntax\n".format(source)
        )
        return 1
    if (
        "FGS-MAX-RANK-INVENTORY-V1" in text
        and os.environ.get("FAKE_REJECT_MAX_RANK") == "1"
    ):
        sys.stderr.write(
            "{}:3:3: Error: unsupported MAX_RANK intrinsic\n".format(source)
        )
        return 1
    if "COMPILE-SIGNAL" in values:
        os.kill(os.getpid(), int(values["COMPILE-SIGNAL"][-1]))
    status = int(values.get("COMPILE-EXIT", ["0"])[-1])
    if status == 0 and "NO-OBJECT" not in values:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            json.dumps({"source": str(source), "text": text}),
            encoding="utf-8",
        )
    return status


def source_pass_markers(text: str) -> List[str]:
    markers: List[str] = []
    pattern = re.compile(r"['\"](TEST-PASS:\s*[^'\"]+)['\"]")
    for line in text.splitlines():
        stripped = line.lstrip()
        if (
            not stripped
            or stripped.startswith("!")
            or (line and line[0] in {"c", "C", "*"})
        ):
            continue
        code = line.split("!", 1)[0]
        markers.extend(match.group(1) for match in pattern.finditer(code))
    return markers


def image_directives(
    values: Dict[str, List[str]], name: str
) -> Dict[int, List[str]]:
    result: Dict[int, List[str]] = {}
    for value in values.get(name, []):
        image_text, separator, payload = value.partition("|")
        if not separator:
            raise SystemExit("bad FAKE-{} directive".format(name))
        result.setdefault(int(image_text), []).append(payload)
    return result


def executable_script(text: str) -> str:
    values = directives(text)
    outputs: List[str] = []
    status = int(values.get("RUN-EXIT", ["0"])[-1])
    run_signal = values.get("RUN-SIGNAL", [None])[-1]
    sleep_seconds = float(values.get("RUN-SLEEP", ["0"])[-1])
    selected_calibration_image = None
    image_outputs = image_directives(values, "RUN-OUTPUT-IMAGE")
    image_status_values = image_directives(values, "RUN-EXIT-IMAGE")
    image_statuses = {
        image: int(status_values[-1])
        for image, status_values in image_status_values.items()
    }

    if "FGS-PROCESSOR-INVENTORY-V1" in text:
        outputs = [
            "FGS-PROCESSOR-INVENTORY-V1",
            "INTEGER_KIND 0",
            "INTEGER_KIND 4",
            "REAL_KIND 0",
            "REAL_KIND 8",
            "LOGICAL_KIND 0",
            "LOGICAL_KIND 4",
            "CHARACTER_KIND 0",
            "CHARACTER_KIND 1",
            "NAMED_INT8 0",
            "NAMED_INT16 -1",
            "NAMED_INT32 4",
            "NAMED_INT64 -1",
            "NAMED_REAL16 -1",
            "NAMED_REAL32 0",
            "NAMED_REAL64 8",
            "NAMED_REAL128 -1",
            "NAMED_ASCII 0",
            "NAMED_ISO_10646 -1",
            "NAMED_SYSTEM_CHARACTER 1",
            "NAMED_DEFAULT_CHARACTER 1",
            "COMPILER_VERSION fake compiler",
            "FGS-PROCESSOR-INVENTORY-END",
        ]
    elif "FGS-MAX-RANK-INVENTORY-V1" in text:
        max_rank = int(os.environ.get("FAKE_MAX_RANK", "15"))
        max_rank_corank_1 = int(
            os.environ.get(
                "FAKE_MAX_RANK_CORANK_1",
                str(max(14, max_rank - 1)),
            )
        )
        outputs = [
            "FGS-MAX-RANK-INVENTORY-V1",
            "MAX_RANK {}".format(max_rank),
            "MAX_RANK_CORANK_1 {}".format(max_rank_corank_1),
            "FGS-MAX-RANK-INVENTORY-END",
        ]
    elif "FGS-ERROR-STOP-CALIBRATION" in text:
        outputs = []
        selected_match = re.search(
            r"fgs_stop_image\s*=\s*(\d+)",
            text,
            re.IGNORECASE,
        )
        if selected_match is None:
            if os.environ.get("FAKE_CALIBRATION_NO_MARKER") != "1":
                outputs.append("FGS-ERROR-STOP-CALIBRATION")
            if os.environ.get("FAKE_CALIBRATION_UNEXPECTED_RETURN") == "1":
                outputs.append("FGS-CALIBRATION-UNEXPECTED-RETURN")
            status = int(os.environ.get("FAKE_CALIBRATION_STATUS", "23"))
        else:
            selected_calibration_image = int(selected_match.group(1))
            status = int(
                os.environ.get(
                    "FAKE_CALIBRATION_STATUS_IMAGE_{}".format(
                        selected_calibration_image
                    ),
                    os.environ.get(
                        "FAKE_SELECTED_CALIBRATION_STATUS",
                        os.environ.get("FAKE_CALIBRATION_STATUS", "23"),
                    ),
                )
            )
    elif "FGS-AUTO-GENERIC-PREREQUISITE-PASS" in text:
        outputs = ["FGS-AUTO-GENERIC-PREREQUISITE-PASS"]
    elif "FGS-GENERATED-KINDS-PASS" in text:
        outputs = ["FGS-GENERATED-KINDS-PASS"]
    elif "FGS-GENERATED-RANK-PASS" in text:
        count = re.search(r"FGS-GENERATED-RANK-COUNT \d+", text)
        ranks = re.search(r"FGS-GENERATED-RANKS [0-9,]+", text)
        outputs = ["FGS-GENERATED-RANK-PASS"]
        if count is not None:
            outputs.append(count.group(0))
        if ranks is not None:
            outputs.append(ranks.group(0))
    else:
        if "RUN-OUTPUT" in values:
            outputs = values["RUN-OUTPUT"]
        elif "SUPPRESS-PASS" not in values:
            outputs = source_pass_markers(text)
    if os.environ.get("FAKE_STOP_STATUS_BY_LITERAL") == "1":
        literal_status = literal_stop_status(text)
        if literal_status:
            status = literal_status

    return """#!/usr/bin/env python3
import os
import signal
import sys
import time

outputs = {outputs!r}
image_outputs = {image_outputs!r}
image_statuses = {image_statuses!r}
selected_calibration_image = {selected_calibration_image!r}
status = {status!r}
this_image = int(os.environ.get("FAKE_THIS_IMAGE", "1"))
if selected_calibration_image is not None:
    if this_image == selected_calibration_image:
        outputs = []
        if os.environ.get("FAKE_CALIBRATION_NO_MARKER") != "1":
            marker_count = (
                2
                if os.environ.get("FAKE_CALIBRATION_DUPLICATE_MARKER") == "1"
                else 1
            )
            outputs.extend(
                ["FGS-ERROR-STOP-CALIBRATION"] * marker_count
            )
        if os.environ.get("FAKE_CALIBRATION_UNEXPECTED_RETURN") == "1":
            outputs.append("FGS-CALIBRATION-UNEXPECTED-RETURN")
    else:
        status = 0
        outputs = []
        sync_status = os.environ.get("FAKE_CALIBRATION_SYNC_STATUS")
        if (
            os.environ.get("FAKE_CALIBRATION_SYNC_RETURNS") == "1"
            or sync_status in {{"0", "stopped", "failed"}}
        ):
            outputs.append("FGS-CALIBRATION-UNEXPECTED-RETURN")
        elif sync_status is not None:
            outputs.append(
                "FGS-CALIBRATION-INCONCLUSIVE: "
                "coarray-sync-status " + sync_status
            )
            status = int(
                os.environ.get("FAKE_CALIBRATION_PROPAGATION_STATUS", "1")
            )
elif image_outputs or image_statuses:
    outputs = image_outputs.get(this_image, [])
    status = image_statuses.get(this_image, 0)
for line in outputs:
    print(line, flush=True)
time.sleep({sleep_seconds!r})
run_signal = {run_signal!r}
if run_signal is not None:
    os.kill(os.getpid(), int(run_signal))
sys.exit(status)
""".format(
        outputs=outputs,
        image_outputs=image_outputs,
        image_statuses=image_statuses,
        selected_calibration_image=selected_calibration_image,
        sleep_seconds=sleep_seconds,
        run_signal=run_signal,
        status=status,
    )


def link_objects(arguments: List[str]) -> int:
    output = Path(option_value(arguments, "-o")).resolve()
    object_paths = [
        Path(argument)
        for argument in arguments
        if argument.endswith(".o") and Path(argument).is_file()
    ]
    payloads = [
        json.loads(path.read_text(encoding="utf-8")) for path in object_paths
    ]
    text = "\n".join(str(payload["text"]) for payload in payloads)
    values = directives(text)
    if "LINK-SLEEP" in values:
        time.sleep(float(values["LINK-SLEEP"][-1]))
    for diagnostic in values.get("LINK-DIAGNOSTIC", []):
        sys.stderr.write("ld.lld: error: {}\n".format(diagnostic))
    if "LINK-SIGNAL" in values:
        os.kill(os.getpid(), int(values["LINK-SIGNAL"][-1]))
    status = int(values.get("LINK-EXIT", ["0"])[-1])
    if status == 0:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(executable_script(text), encoding="utf-8")
        output.chmod(0o755)
    return status


def main() -> int:
    arguments = sys.argv[1:]
    if "-c" in arguments:
        return compile_source(arguments)
    return link_objects(arguments)


if __name__ == "__main__":
    sys.exit(main())
