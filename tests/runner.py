#!/usr/bin/env python3
"""Metadata-aware runner for the auto-generic Fortran test suite."""

import argparse
import json
import os
import re
import shlex
import shutil
import signal
import subprocess
import sys
import time
import uuid
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Pattern, Sequence, Set, Tuple

sys.dont_write_bytecode = True

from processor_cases import (
    FEATURE_PREREQUISITE_SOURCE,
    KIND_INVENTORY_SOURCE,
    MAX_RANK_INVENTORY_SOURCE,
    ProcessorInventory,
    error_stop_calibration_source,
    generate_kind_runtime_source,
    generate_rank_runtime_source,
    generation_manifest,
    parse_kind_inventory,
    parse_max_rank_inventory,
)


SOURCE_SUFFIXES = {".f", ".f90", ".f95", ".f03", ".f08", ".f18"}
KNOWN_DRAFTS = {
    "generic-interface-declarations",
    "assumed-length-guards",
    "character-generic-parse",
    "character-ordinary-parse",
    "empty-expansion",
    "generic-bind-c",
    "extended-rank-limit",
    "mixed-length-dedup",
    "template-integration",
}
MUTUALLY_EXCLUSIVE_DRAFTS = {
    frozenset(
        {
            "character-generic-parse",
            "character-ordinary-parse",
        }
    )
}
NAMED_CAPABILITIES = {
    "int8",
    "int16",
    "int32",
    "int64",
    "real16",
    "real32",
    "real64",
    "real128",
    "ascii",
    "iso_10646",
}
COUNT_CAPABILITIES = {
    "integer_kinds",
    "real_kinds",
    "logical_kinds",
    "character_kinds",
}
CAPABILITY_RE = re.compile(
    r"^(?P<name>[a-z][a-z0-9_]*)(?:(?P<operator>>=|<=|==|>|<)(?P<value>-?\d+))?$"
)
METADATA_RE = re.compile(
    r"TEST-(?P<key>[A-Z][A-Z-]*)(?::[ \t]*(?P<value>.*?))?[ \t]*$",
    re.IGNORECASE,
)
ANSI_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
CRASH_RE = re.compile(
    r"(internal compiler error|please submit a bug report|segmentation fault|"
    r"bus error|abort trap|aborted|illegal instruction|floating point exception|"
    r"stack dump|llvm error|fatal error: error in backend|"
    r"cannot allocate memory|out of memory|resource temporarily unavailable|"
    r"no space left|too many open files|killed(?: by)? signal|"
    r"unable to execute command|"
    r"cannot execute)",
    re.IGNORECASE,
)
MEANINGLESS_ERROR_PATTERNS = {
    "error",
    "errors",
    "invalid",
    "failed",
    "failure",
    "syntax",
    "syntaxerror",
    "constraint",
    "generic",
    "notallowed",
}
MISSING_MAIN_RE = re.compile(
    r"(undefined reference to [`'\"]?_?main\b|undefined symbol:?\s+_?main\b|"
    r"entry point.*(?:_?main|winmain)|LNK1561)",
    re.IGNORECASE,
)


@dataclass
class Marker:
    source: Path
    marker_line: int
    target_lines: Set[int]

    def to_dict(self, tests_root: Path) -> Dict[str, Any]:
        return {
            "source": relative_display(self.source, tests_root),
            "marker_line": self.marker_line,
            "target_lines": sorted(self.target_lines),
        }


@dataclass
class ErrorStopSpec:
    code_form: str
    code_literal: Optional[str]
    quiet_literal: Optional[str]
    flush_before_stop: bool
    statement: str
    source: Path
    line: int

    @property
    def stop_clause(self) -> str:
        clause = ""
        if self.code_literal is not None:
            clause = " " + self.code_literal
        if self.quiet_literal is not None:
            clause += ", quiet = " + self.quiet_literal
        return clause

    @property
    def cache_key(self) -> str:
        return json.dumps(
            [
                self.code_form,
                self.code_literal,
                self.quiet_literal,
                self.flush_before_stop,
            ],
            separators=(",", ":"),
        )

    def to_dict(self, tests_root: Path) -> Dict[str, Any]:
        return {
            "code_form": self.code_form,
            "code_literal": self.code_literal,
            "quiet_literal": self.quiet_literal,
            "flush_before_stop": self.flush_before_stop,
            "statement": self.statement,
            "source": relative_display(self.source, tests_root),
            "line": self.line,
            "calibration_clause": self.stop_clause,
        }


@dataclass
class Metadata:
    rules: List[str] = field(default_factory=list)
    requires: List[str] = field(default_factory=list)
    drafts: List[str] = field(default_factory=list)
    diagnostic_class: Optional[str] = None
    error_patterns: List[str] = field(default_factory=list)
    error_phase: str = "compile"
    error_phase_explicit: bool = False
    error_markers: List[Marker] = field(default_factory=list)
    stop_id: Optional[str] = None
    error_stop_spec: Optional[ErrorStopSpec] = None
    error_stop_error: Optional[str] = None
    images: int = 1
    parse_errors: List[str] = field(default_factory=list)

    def to_dict(self, tests_root: Path) -> Dict[str, Any]:
        return {
            "rules": list(self.rules),
            "requires": list(self.requires),
            "drafts": list(self.drafts),
            "diagnostic_class": self.diagnostic_class,
            "error_patterns": list(self.error_patterns),
            "error_phase": self.error_phase,
            "error_phase_explicit": self.error_phase_explicit,
            "error_markers": [
                marker.to_dict(tests_root) for marker in self.error_markers
            ],
            "stop_id": self.stop_id,
            "error_stop_spec": (
                None
                if self.error_stop_spec is None
                else self.error_stop_spec.to_dict(tests_root)
            ),
            "error_stop_error": self.error_stop_error,
            "images": self.images,
        }


@dataclass
class Case:
    case_id: str
    category: str
    path: Path
    sources: List[Path]
    metadata: Metadata
    in_draft_tree: bool

    def has_program(self) -> bool:
        return any(source_has_program(source) for source in self.sources)

    def to_dict(self, tests_root: Path) -> Dict[str, Any]:
        return {
            "id": self.case_id,
            "category": self.category,
            "path": relative_display(self.path, tests_root),
            "sources": [
                relative_display(source, tests_root) for source in self.sources
            ],
            "in_draft_tree": self.in_draft_tree,
            "has_program": self.has_program(),
            "metadata": self.metadata.to_dict(tests_root),
        }


@dataclass
class ValidationIssue:
    case_id: str
    severity: str
    code: str
    message: str

    def to_dict(self) -> Dict[str, str]:
        return asdict(self)


@dataclass
class ProcessResult:
    command: List[str]
    cwd: str
    returncode: Optional[int]
    stdout: str
    stderr: str
    duration_seconds: float
    timed_out: bool = False
    spawn_error: Optional[str] = None

    @property
    def combined_output(self) -> str:
        if self.stdout and self.stderr:
            return self.stdout + "\n" + self.stderr
        return self.stdout or self.stderr

    def outcome(self) -> Dict[str, Any]:
        if self.timed_out:
            return {"kind": "timeout"}
        if self.spawn_error is not None:
            return {"kind": "spawn-error", "message": self.spawn_error}
        if self.returncode is None:
            return {"kind": "unknown"}
        if self.returncode < 0:
            return {"kind": "signal", "signal": -self.returncode}
        return {"kind": "exit", "status": self.returncode}

    def to_dict(self, include_output: bool = True) -> Dict[str, Any]:
        data: Dict[str, Any] = {
            "command": self.command,
            "command_display": shlex.join(self.command),
            "cwd": self.cwd,
            "outcome": self.outcome(),
            "duration_seconds": round(self.duration_seconds, 6),
        }
        if include_output:
            data["stdout"] = self.stdout
            data["stderr"] = self.stderr
        return data


@dataclass
class DiagnosticRecord:
    style: str
    severity: str
    message: str
    raw: str
    source: Optional[str] = None
    line: Optional[int] = None
    column: Optional[int] = None
    phase: str = "compile"

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class DiagnosticExpectationOverride:
    message_regexes: Optional[List[str]]
    location_policy: str
    selector_type: str
    selector_id: str

    def effective_dict(self, case: Case) -> Dict[str, Any]:
        return {
            "case_id": case.case_id,
            "selector_type": self.selector_type,
            "selector_id": self.selector_id,
            "message_regexes": (
                list(case.metadata.error_patterns)
                if self.message_regexes is None
                else list(self.message_regexes)
            ),
            "location_policy": self.location_policy,
            "preserved_error_phase": case.metadata.error_phase,
            "preserved_diagnostic_class": case.metadata.diagnostic_class,
        }


@dataclass
class DiagnosticExpectationOverrides:
    source_file: Optional[Path]
    cases: Dict[str, DiagnosticExpectationOverride]
    rules: Dict[str, DiagnosticExpectationOverride]

    @classmethod
    def empty(cls) -> "DiagnosticExpectationOverrides":
        return cls(source_file=None, cases={}, rules={})

    def resolve(
        self, case: Case
    ) -> Optional[DiagnosticExpectationOverride]:
        case_override = self.cases.get(case.case_id)
        if case_override is not None:
            return case_override
        matching = [
            self.rules[rule]
            for rule in case.metadata.rules
            if rule in self.rules
        ]
        if not matching:
            return None
        return matching[0]

    def disclosure(self, cases: Sequence[Case]) -> Dict[str, Any]:
        active = []
        for case in cases:
            if case.category != "invalid_compile_time":
                continue
            override = self.resolve(case)
            if override is not None:
                active.append(override.effective_dict(case))
        return {
            "source_file": (
                None
                if self.source_file is None
                else str(self.source_file)
            ),
            "active_overrides": active,
        }


@dataclass
class TestResult:
    case_id: str
    category: str
    status: str
    reason_code: str
    message: str
    gating: bool
    executed: bool
    details: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.case_id,
            "category": self.category,
            "status": self.status,
            "reason_code": self.reason_code,
            "message": self.message,
            "gating": self.gating,
            "executed": self.executed,
            "details": self.details,
        }


def relative_display(path: Path, base: Path) -> str:
    try:
        return path.resolve().relative_to(base.resolve()).as_posix()
    except ValueError:
        return str(path)


def is_source(path: Path) -> bool:
    return path.is_file() and path.suffix.lower() in SOURCE_SUFFIXES


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def metadata_comment(
    line: str, fixed_form: bool
) -> Optional[Tuple[str, str, int, bool]]:
    fixed_comment = (
        fixed_form and bool(line) and line[0] in {"c", "C", "*", "!"}
    )
    free_comment = bool(line) and line[0] == "!"
    if fixed_comment or free_comment:
        comment_start = 0
        payload = line[1:].strip()
        standalone = True
    else:
        match = re.search(r"!\s*TEST-", line, re.IGNORECASE)
        if match is None:
            return None
        comment_start = match.start()
        payload = line[match.start() + 1 :].strip()
        standalone = not line[:comment_start].strip()
    match = METADATA_RE.match(payload)
    if match is None:
        return None
    key = match.group("key").upper()
    value = (match.group("value") or "").strip()
    return key, value, comment_start, standalone


def is_comment_or_blank(line: str, fixed_form: bool) -> bool:
    if not line.strip():
        return True
    if fixed_form and line[0] in {"c", "C", "*", "!"}:
        return True
    return line.lstrip().startswith("!")


def statement_lines(lines: Sequence[str], target: int, fixed_form: bool) -> Set[int]:
    if target < 1 or target > len(lines):
        return {target}
    if fixed_form:
        start = target
        while start > 1:
            current = lines[start - 1]
            if len(current) >= 6 and current[5] not in {" ", "0"}:
                start -= 1
            else:
                break
        end = target
        while end < len(lines):
            following = lines[end]
            if len(following) >= 6 and following[5] not in {" ", "0"}:
                end += 1
            else:
                break
        return set(range(start, end + 1))

    def code_part(line: str) -> str:
        return line.split("!", 1)[0].rstrip()

    start = target
    while start > 1 and code_part(lines[start - 2]).endswith("&"):
        start -= 1
    end = target
    while end < len(lines) and code_part(lines[end - 1]).endswith("&"):
        end += 1
    return set(range(start, end + 1))


def parse_metadata(sources: Sequence[Path]) -> Metadata:
    metadata = Metadata()
    scalar_values: Dict[str, str] = {}
    for source in sources:
        lines = read_text(source).splitlines()
        fixed_form = source.suffix.lower() == ".f"
        for index, line in enumerate(lines, 1):
            parsed = metadata_comment(line, fixed_form)
            if parsed is None:
                continue
            key, value, _, standalone = parsed
            if key == "RULE":
                metadata.rules.extend(value.split())
            elif key == "REQUIRES":
                metadata.requires.extend(value.split())
            elif key == "DRAFT":
                metadata.drafts.extend(value.split())
            elif key == "ERROR":
                if value:
                    metadata.error_patterns.append(value)
                else:
                    metadata.parse_errors.append(
                        "{}:{}: TEST-ERROR has no regex".format(source, index)
                    )
            elif key == "ERROR-HERE":
                target = index
                if standalone:
                    target = index + 1
                    while target <= len(lines) and is_comment_or_blank(
                        lines[target - 1], fixed_form
                    ):
                        target += 1
                metadata.error_markers.append(
                    Marker(
                        source=source,
                        marker_line=index,
                        target_lines=statement_lines(lines, target, fixed_form),
                    )
                )
            elif key in {
                "DIAGNOSTIC-CLASS",
                "ERROR-PHASE",
                "STOP",
                "IMAGES",
            }:
                previous = scalar_values.get(key)
                if previous is not None and previous != value:
                    metadata.parse_errors.append(
                        "{}:{}: conflicting TEST-{} values".format(
                            source, index, key
                        )
                    )
                scalar_values[key] = value
            else:
                metadata.parse_errors.append(
                    "{}:{}: unknown TEST-{} metadata".format(
                    source, index, key
                    )
                )

    metadata.rules = unique(metadata.rules)
    metadata.requires = unique(metadata.requires)
    metadata.drafts = unique(metadata.drafts)
    if "DIAGNOSTIC-CLASS" in scalar_values:
        metadata.diagnostic_class = scalar_values["DIAGNOSTIC-CLASS"].lower()
    if "ERROR-PHASE" in scalar_values:
        metadata.error_phase = scalar_values["ERROR-PHASE"].lower()
        metadata.error_phase_explicit = True
    if "STOP" in scalar_values:
        metadata.stop_id = scalar_values["STOP"]
        (
            metadata.error_stop_spec,
            metadata.error_stop_error,
        ) = find_error_stop_spec(sources, metadata.stop_id)
    if "IMAGES" in scalar_values:
        try:
            metadata.images = int(scalar_values["IMAGES"], 10)
        except ValueError:
            metadata.parse_errors.append("TEST-IMAGES must be an integer")
    return metadata


def unique(values: Iterable[str]) -> List[str]:
    result: List[str] = []
    seen: Set[str] = set()
    for value in values:
        if value not in seen:
            seen.add(value)
            result.append(value)
    return result


def source_has_program(path: Path) -> bool:
    fixed_form = path.suffix.lower() == ".f"
    for line in read_text(path).splitlines():
        if is_comment_or_blank(line, fixed_form):
            continue
        code = line.split("!", 1)[0]
        if re.match(
            r"^[ \t]*(?:\d+[ \t]+)?program(?:[ \t]+[a-z_]\w*|[ \t]*$)",
            code,
            re.IGNORECASE,
        ):
            return True
    return False


def strip_fortran_comment(line: str) -> str:
    quote: Optional[str] = None
    index = 0
    while index < len(line):
        character = line[index]
        if quote is not None:
            if character == quote:
                if index + 1 < len(line) and line[index + 1] == quote:
                    index += 2
                    continue
                quote = None
        elif character in {"'", '"'}:
            quote = character
        elif character == "!":
            return line[:index]
        index += 1
    return line


def logical_statement(
    lines: Sequence[str], start: int, fixed_form: bool
) -> Tuple[str, int]:
    if fixed_form:
        parts = [strip_fortran_comment(lines[start])[6:].strip()]
        end = start
        while end + 1 < len(lines):
            following = lines[end + 1]
            if len(following) < 6 or following[5] in {" ", "0"}:
                break
            end += 1
            parts.append(strip_fortran_comment(lines[end])[6:].strip())
        return " ".join(part for part in parts if part), end

    parts: List[str] = []
    end = start
    continuation = False
    while end < len(lines):
        if is_comment_or_blank(lines[end], False):
            if continuation:
                end += 1
                continue
            break
        code = strip_fortran_comment(lines[end]).strip()
        if continuation and code.startswith("&"):
            code = code[1:].lstrip()
        continuation = code.endswith("&")
        if continuation:
            code = code[:-1].rstrip()
        parts.append(code)
        if not continuation:
            return " ".join(part for part in parts if part), end
        end += 1
    return " ".join(part for part in parts if part), max(start, end - 1)


def split_fortran_commas(text: str) -> List[str]:
    parts: List[str] = []
    quote: Optional[str] = None
    start = 0
    index = 0
    while index < len(text):
        character = text[index]
        if quote is not None:
            if character == quote:
                if index + 1 < len(text) and text[index + 1] == quote:
                    index += 2
                    continue
                quote = None
        elif character in {"'", '"'}:
            quote = character
        elif character == ",":
            parts.append(text[start:index].strip())
            start = index + 1
        index += 1
    parts.append(text[start:].strip())
    return parts


def has_unquoted_character(text: str, expected: str) -> bool:
    quote: Optional[str] = None
    index = 0
    while index < len(text):
        character = text[index]
        if quote is not None:
            if character == quote:
                if index + 1 < len(text) and text[index + 1] == quote:
                    index += 2
                    continue
                quote = None
        elif character in {"'", '"'}:
            quote = character
        elif character == expected:
            return True
        index += 1
    return False


def parse_error_stop_statement(
    statement: str,
    source: Path,
    line: int,
    flush_before_stop: bool,
) -> Tuple[Optional[ErrorStopSpec], Optional[str]]:
    match = re.fullmatch(
        r"[ \t]*(?:\d+[ \t]+)?error[ \t]+stop\b(?P<rest>.*)",
        statement,
        re.IGNORECASE,
    )
    if match is None:
        return None, "TEST-STOP output is not immediately followed by ERROR STOP"
    rest = match.group("rest").strip()
    if has_unquoted_character(rest, ";"):
        return None, "ERROR STOP calibration does not support compound statements"
    parts = split_fortran_commas(rest) if rest else []
    if len(parts) > 2:
        return None, "ERROR STOP has an unsupported stop-code/QUIET form"

    code_literal: Optional[str] = None
    code_form = "none"
    quiet_part: Optional[str] = None
    if parts:
        if re.match(r"^quiet[ \t]*=", parts[0], re.IGNORECASE):
            if not rest.startswith(","):
                return None, "ERROR STOP QUIET must follow a comma"
            quiet_part = parts[0]
        elif parts[0]:
            code_literal = parts[0]
        if len(parts) == 2:
            if quiet_part is not None:
                return None, "ERROR STOP has duplicate trailing fields"
            quiet_part = parts[1]

    if code_literal is not None:
        character_literal = re.fullmatch(
            r"'(?:[^']|'')*'|\"(?:[^\"]|\"\")*\"",
            code_literal,
        )
        integer_literal = re.fullmatch(
            r"[+-]?\d+(?:_\d+)?",
            code_literal,
        )
        if character_literal is not None:
            code_form = "character-literal"
        elif integer_literal is not None:
            code_form = "integer-literal"
        else:
            return (
                None,
                "dynamic or nonliteral ERROR STOP code cannot be calibrated",
            )

    quiet_literal: Optional[str] = None
    if quiet_part is not None:
        quiet_match = re.fullmatch(
            r"quiet[ \t]*=[ \t]*(?P<value>\.(?:true|false)\.)",
            quiet_part,
            re.IGNORECASE,
        )
        if quiet_match is None:
            return None, "dynamic ERROR STOP QUIET cannot be calibrated"
        quiet_literal = quiet_match.group("value").lower()

    return (
        ErrorStopSpec(
            code_form=code_form,
            code_literal=code_literal,
            quiet_literal=quiet_literal,
            flush_before_stop=flush_before_stop,
            statement=statement,
            source=source,
            line=line,
        ),
        None,
    )


def find_error_stop_spec(
    sources: Sequence[Path], stop_id: str
) -> Tuple[Optional[ErrorStopSpec], Optional[str]]:
    marker = "TEST-STOP: {}".format(stop_id)
    specs: List[ErrorStopSpec] = []
    errors: List[str] = []
    for source in sources:
        lines = read_text(source).splitlines()
        fixed_form = source.suffix.lower() == ".f"
        for index, line in enumerate(lines):
            if marker not in line or is_comment_or_blank(line, fixed_form):
                continue
            _, marker_end = logical_statement(lines, index, fixed_form)
            next_index = marker_end + 1
            while next_index < len(lines) and is_comment_or_blank(
                lines[next_index], fixed_form
            ):
                next_index += 1
            if next_index >= len(lines):
                errors.append(
                    "{}:{} TEST-STOP has no following statement".format(
                        source, index + 1
                    )
                )
                continue
            statement, statement_end = logical_statement(
                lines, next_index, fixed_form
            )
            flush_before_stop = bool(
                re.fullmatch(
                    r"[ \t]*(?:\d+[ \t]+)?flush[ \t]*"
                    r"\([ \t]*output_unit[ \t]*\)[ \t]*",
                    statement,
                    re.IGNORECASE,
                )
            )
            if flush_before_stop:
                next_index = statement_end + 1
                while next_index < len(lines) and is_comment_or_blank(
                    lines[next_index], fixed_form
                ):
                    next_index += 1
                if next_index >= len(lines):
                    errors.append(
                        "{}:{} FLUSH has no following ERROR STOP".format(
                            source, statement_end + 1
                        )
                    )
                    continue
                statement, _ = logical_statement(
                    lines, next_index, fixed_form
                )
            spec, error = parse_error_stop_statement(
                statement,
                source,
                next_index + 1,
                flush_before_stop,
            )
            if error is not None:
                errors.append(
                    "{}:{} {}".format(source, next_index + 1, error)
                )
            elif spec is not None:
                specs.append(spec)
    if errors:
        return None, "; ".join(errors)
    if not specs:
        return None, "source has no executable TEST-STOP output statement"
    keys = {spec.cache_key for spec in specs}
    if len(keys) != 1:
        return None, "TEST-STOP sites use different ERROR STOP forms or codes"
    return specs[0], None


def source_code_contains(
    sources: Sequence[Path], text: str
) -> bool:
    for source in sources:
        fixed_form = source.suffix.lower() == ".f"
        for line in read_text(source).splitlines():
            if not is_comment_or_blank(line, fixed_form) and text in line:
                return True
    return False


def category_roots(tests_root: Path) -> List[Tuple[Path, str, bool]]:
    roots = [
        (tests_root / "valid", "valid", False),
        (tests_root / "invalid_compile_time", "invalid_compile_time", False),
        (tests_root / "invalid_runtime", "invalid_runtime", False),
        (
            tests_root / "draft_interpretations" / "valid",
            "valid",
            True,
        ),
        (
            tests_root / "draft_interpretations" / "negative",
            "invalid_compile_time",
            True,
        ),
        (
            tests_root / "draft_interpretations" / "invalid_compile_time",
            "invalid_compile_time",
            True,
        ),
        (
            tests_root / "draft_interpretations" / "invalid_runtime",
            "invalid_runtime",
            True,
        ),
    ]
    return roots


def discover_cases(tests_root: Path) -> List[Case]:
    cases: List[Case] = []
    for root, category, in_draft_tree in category_roots(tests_root):
        if not root.is_dir():
            continue
        for entry in sorted(root.iterdir(), key=lambda item: item.name):
            sources: List[Path]
            if is_source(entry):
                sources = [entry.resolve()]
                case_path = entry.resolve()
            elif entry.is_dir():
                sources = sorted(
                    (
                        item.resolve()
                        for item in entry.iterdir()
                        if is_source(item)
                    ),
                    key=lambda item: item.name,
                )
                if not sources:
                    continue
                case_path = entry.resolve()
            else:
                continue
            case_id = relative_display(case_path, tests_root)
            cases.append(
                Case(
                    case_id=case_id,
                    category=category,
                    path=case_path,
                    sources=sources,
                    metadata=parse_metadata(sources),
                    in_draft_tree=in_draft_tree,
                )
            )
    return cases


def resolve_selector(
    selector: str, suite_root: Path, tests_root: Path, invocation_cwd: Path
) -> Path:
    raw = Path(selector).expanduser()
    candidates: List[Path] = []
    if raw.is_absolute():
        candidates.append(raw)
    else:
        candidates.extend(
            [
                invocation_cwd / raw,
                tests_root / raw,
                suite_root / raw,
            ]
        )
    for candidate in candidates:
        if candidate.exists():
            return candidate.resolve()
    raise ValueError("selector does not exist: {}".format(selector))


def select_cases(
    all_cases: Sequence[Case],
    selectors: Sequence[str],
    suite_root: Path,
    tests_root: Path,
    invocation_cwd: Path,
) -> List[Case]:
    if not selectors:
        return list(all_cases)
    selected: List[Case] = []
    seen: Set[str] = set()
    for selector in selectors:
        resolved = resolve_selector(
            selector, suite_root, tests_root, invocation_cwd
        )
        matches: List[Case] = []
        for case in all_cases:
            if resolved == case.path:
                matches.append(case)
                continue
            if resolved in case.sources:
                matches.append(case)
                continue
            if resolved.is_dir():
                try:
                    case.path.relative_to(resolved)
                except ValueError:
                    pass
                else:
                    matches.append(case)
        if not matches:
            if resolved.is_dir():
                raise ValueError(
                    "selector contains no test cases: {}".format(selector)
                )
            raise ValueError(
                "selector is not a recognized test source: {}".format(selector)
            )
        for case in matches:
            if case.case_id not in seen:
                seen.add(case.case_id)
                selected.append(case)
    return selected


def meaningful_error_pattern(pattern: str) -> bool:
    simplified = re.sub(r"[^a-z0-9]+", "", pattern.lower())
    if len(simplified) < 6:
        return False
    return simplified not in MEANINGLESS_ERROR_PATTERNS


def validate_case(case: Case) -> List[ValidationIssue]:
    issues: List[ValidationIssue] = []

    def error(code: str, message: str) -> None:
        issues.append(
            ValidationIssue(
                case_id=case.case_id,
                severity="error",
                code=code,
                message=message,
            )
        )

    for parse_error in case.metadata.parse_errors:
        error("metadata-parse", parse_error)
    if not case.sources:
        error("no-sources", "case has no .f or .f90 sources")
    for source in case.sources:
        if not source.is_file():
            error("missing-source", "source does not exist: {}".format(source))
        elif source.suffix.lower() not in SOURCE_SUFFIXES:
            error(
                "unsupported-source",
                "unsupported Fortran source suffix: {}".format(source),
            )
    if not case.metadata.rules:
        error("missing-rule", "TEST-RULE metadata is required")
    for requirement in case.metadata.requires:
        match = CAPABILITY_RE.fullmatch(requirement)
        if match is None:
            error(
                "invalid-requirement",
                "invalid TEST-REQUIRES token {!r}".format(requirement),
            )
            continue
        name = match.group("name")
        if name not in NAMED_CAPABILITIES | COUNT_CAPABILITIES:
            error(
                "unknown-capability",
                "unknown processor capability {!r}".format(name),
            )
    for draft in case.metadata.drafts:
        if draft not in KNOWN_DRAFTS:
            error("unknown-draft", "unknown TEST-DRAFT id {!r}".format(draft))
    if case.in_draft_tree and not case.metadata.drafts:
        error(
            "unmarked-draft",
            "tests under draft_interpretations require TEST-DRAFT",
        )
    if case.metadata.images < 1:
        error("invalid-images", "TEST-IMAGES must be at least one")

    if case.category == "invalid_compile_time":
        if case.metadata.diagnostic_class not in {"required", "enhanced"}:
            error(
                "missing-diagnostic-class",
                "negative tests require TEST-DIAGNOSTIC-CLASS: required or enhanced",
            )
        if not case.metadata.error_patterns:
            error("missing-error", "negative tests require TEST-ERROR")
        for pattern in case.metadata.error_patterns:
            try:
                re.compile(pattern, re.IGNORECASE)
            except re.error as exc:
                error(
                    "invalid-error-regex",
                    "invalid TEST-ERROR regex {!r}: {}".format(pattern, exc),
                )
            if not meaningful_error_pattern(pattern):
                error(
                    "weak-error-regex",
                    "TEST-ERROR regex {!r} is too broad".format(pattern),
                )
        if not case.metadata.error_markers:
            error(
                "missing-error-marker",
                "negative tests require at least one TEST-ERROR-HERE marker",
            )
        for marker in case.metadata.error_markers:
            source_line_count = len(read_text(marker.source).splitlines())
            if not any(
                1 <= line <= source_line_count
                for line in marker.target_lines
            ):
                error(
                    "dangling-error-marker",
                    "{}:{} TEST-ERROR-HERE has no following statement".format(
                        marker.source, marker.marker_line
                    ),
                )
        if case.metadata.error_phase not in {
            "compile",
            "link",
            "compile-or-link",
        }:
            error(
                "invalid-error-phase",
                "TEST-ERROR-PHASE must be compile, link, or compile-or-link",
            )
        if case.metadata.error_phase in {"link", "compile-or-link"}:
            if not case.metadata.error_phase_explicit:
                error(
                    "implicit-link-phase",
                    "link expectations require explicit TEST-ERROR-PHASE",
                )
            if not case.has_program():
                error(
                    "link-without-program",
                    "link rejection cannot be tested without a PROGRAM unit",
                )
    elif case.metadata.diagnostic_class is not None:
        error(
            "unexpected-diagnostic-class",
            "TEST-DIAGNOSTIC-CLASS is only valid for compile-time negatives",
        )

    if case.category in {"valid", "invalid_runtime"} and not case.has_program():
        error(
            "missing-program",
            "{} case has no PROGRAM unit to link and run".format(case.category),
        )

    if case.category == "invalid_runtime":
        stop_id = case.metadata.stop_id
        if not stop_id:
            error("missing-stop-id", "runtime negative requires TEST-STOP")
        else:
            stop_line = "TEST-STOP: {}".format(stop_id)
            unexpected_line = "TEST-UNEXPECTED-RETURN: {}".format(stop_id)
            if not source_code_contains(case.sources, stop_line):
                error(
                    "missing-stop-source-marker",
                    "source does not contain {!r}".format(stop_line),
                )
            if case.metadata.error_stop_error is not None:
                error(
                    "uncalibratable-error-stop",
                    case.metadata.error_stop_error,
                )
            elif case.metadata.error_stop_spec is None:
                error(
                    "uncalibratable-error-stop",
                    "ERROR STOP form could not be determined",
                )
            if not source_code_contains(case.sources, unexpected_line):
                error(
                    "missing-unexpected-return-marker",
                    "source does not contain {!r}".format(unexpected_line),
                )
    return issues


def coverage_summary(cases: Sequence[Case]) -> Dict[str, Any]:
    rules: Dict[str, List[str]] = {}
    capabilities: Dict[str, List[str]] = {}
    drafts: Dict[str, List[str]] = {}
    diagnostic_classes: Dict[str, List[str]] = {}
    for case in cases:
        for rule in case.metadata.rules:
            rules.setdefault(rule, []).append(case.case_id)
        for capability in case.metadata.requires:
            capabilities.setdefault(capability, []).append(case.case_id)
        for draft in case.metadata.drafts:
            drafts.setdefault(draft, []).append(case.case_id)
        if case.metadata.diagnostic_class:
            diagnostic_classes.setdefault(
                case.metadata.diagnostic_class, []
            ).append(case.case_id)
    return {
        "rules": dict(sorted(rules.items())),
        "capabilities": dict(sorted(capabilities.items())),
        "drafts": dict(sorted(drafts.items())),
        "diagnostic_classes": dict(sorted(diagnostic_classes.items())),
    }


def generated_catalog() -> List[Dict[str, Any]]:
    return [
        {
            "id": "@generated/processor-kinds",
            "enabled_by_default": True,
            "inventory_dimensions": [
                "INTEGER_KINDS",
                "REAL_KINDS",
                "LOGICAL_KINDS",
                "CHARACTER_KINDS",
            ],
            "runtime_coverage": [
                "integer",
                "real",
                "complex-for-each-real-kind",
                "logical",
                "character",
                "result-kind-and-value",
                "save-state-by-kind-type-and-rank",
                "joint-type-kind-rank-save-state",
            ],
            "counts": "processor-dependent; emitted in run/generate JSON",
        },
        {
            "id": "@generated/processor-rank",
            "enabled_by_default": True,
            "inventory_dimensions": ["MAX_RANK", "MAX_RANK(1)"],
            "portable_default_bound": 15,
            "extended_profile": "extended-rank-limit",
            "runtime_coverage": "every rank from zero through selected bound",
            "counts": "processor-dependent; emitted in run/generate JSON",
        },
    ]


def reject_duplicate_json_keys(
    pairs: Sequence[Tuple[str, Any]]
) -> Dict[str, Any]:
    result: Dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(
                "duplicate key in diagnostic expectations: {!r}".format(key)
            )
        result[key] = value
    return result


def parse_expectation_entry(
    value: Any, selector_type: str, selector_id: str
) -> DiagnosticExpectationOverride:
    if not isinstance(value, dict):
        raise ValueError(
            "{} expectation {!r} must be an object".format(
                selector_type, selector_id
            )
        )
    unknown = set(value) - {"message_regexes", "location"}
    if unknown:
        raise ValueError(
            "{} expectation {!r} has unknown fields: {}".format(
                selector_type,
                selector_id,
                ", ".join(sorted(unknown)),
            )
        )
    if not value:
        raise ValueError(
            "{} expectation {!r} is empty".format(
                selector_type, selector_id
            )
        )

    message_regexes: Optional[List[str]] = None
    if "message_regexes" in value:
        raw_patterns = value["message_regexes"]
        if (
            not isinstance(raw_patterns, list)
            or not raw_patterns
            or any(
                not isinstance(pattern, str) or not pattern
                for pattern in raw_patterns
            )
        ):
            raise ValueError(
                "{} expectation {!r} message_regexes must be a "
                "nonempty array of nonempty strings".format(
                    selector_type, selector_id
                )
            )
        message_regexes = list(raw_patterns)
        for pattern in message_regexes:
            try:
                re.compile(pattern, re.IGNORECASE)
            except re.error as exc:
                raise ValueError(
                    "{} expectation {!r} has invalid regex {!r}: {}".format(
                        selector_type,
                        selector_id,
                        pattern,
                        exc,
                    )
                )

    location = value.get("location", "marked")
    if not isinstance(location, str) or location not in {
        "marked",
        "source",
        "case-context",
    }:
        raise ValueError(
            "{} expectation {!r} location must be marked, source, "
            "or case-context".format(selector_type, selector_id)
        )
    return DiagnosticExpectationOverride(
        message_regexes=message_regexes,
        location_policy=location,
        selector_type=selector_type,
        selector_id=selector_id,
    )


def load_diagnostic_expectations(
    filename: Optional[str],
    cases: Sequence[Case],
    invocation_cwd: Path,
) -> DiagnosticExpectationOverrides:
    if filename is None:
        return DiagnosticExpectationOverrides.empty()
    path = Path(filename).expanduser()
    if not path.is_absolute():
        path = invocation_cwd / path
    path = path.resolve()
    if not path.is_file():
        raise ValueError(
            "diagnostic expectations file does not exist: {}".format(path)
        )
    try:
        data = json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=reject_duplicate_json_keys,
        )
    except json.JSONDecodeError as exc:
        raise ValueError(
            "invalid diagnostic expectations JSON: {}".format(exc)
        )
    if not isinstance(data, dict):
        raise ValueError("diagnostic expectations root must be an object")
    unknown = set(data) - {"schema_version", "cases", "rules"}
    if unknown:
        raise ValueError(
            "diagnostic expectations has unknown top-level fields: {}".format(
                ", ".join(sorted(unknown))
            )
        )
    schema_version = data.get("schema_version", 1)
    if type(schema_version) is not int or schema_version != 1:
        raise ValueError(
            "diagnostic expectations schema_version must be integer 1"
        )
    raw_cases = data.get("cases", {})
    raw_rules = data.get("rules", {})
    if not isinstance(raw_cases, dict) or not isinstance(raw_rules, dict):
        raise ValueError(
            "diagnostic expectations cases and rules must be objects"
        )
    if not raw_cases and not raw_rules:
        raise ValueError("diagnostic expectations contains no overrides")

    negative_cases = {
        case.case_id: case
        for case in cases
        if case.category == "invalid_compile_time"
    }
    negative_rules = {
        rule
        for case in negative_cases.values()
        for rule in case.metadata.rules
    }
    case_overrides: Dict[str, DiagnosticExpectationOverride] = {}
    for case_id, value in raw_cases.items():
        if not isinstance(case_id, str) or case_id not in negative_cases:
            raise ValueError(
                "unknown compile-negative case ID in diagnostic "
                "expectations: {!r}".format(case_id)
            )
        case_overrides[case_id] = parse_expectation_entry(
            value, "case", case_id
        )

    rule_overrides: Dict[str, DiagnosticExpectationOverride] = {}
    for rule, value in raw_rules.items():
        if not isinstance(rule, str) or rule not in negative_rules:
            raise ValueError(
                "unknown compile-negative rule ID in diagnostic "
                "expectations: {!r}".format(rule)
            )
        rule_overrides[rule] = parse_expectation_entry(
            value, "rule", rule
        )

    for case in negative_cases.values():
        if case.case_id in case_overrides:
            continue
        matching_rules = [
            rule for rule in case.metadata.rules if rule in rule_overrides
        ]
        if len(matching_rules) > 1:
            raise ValueError(
                "diagnostic expectations ambiguously match {} through "
                "rules {}; add a case override".format(
                    case.case_id,
                    ", ".join(matching_rules),
                )
            )
    return DiagnosticExpectationOverrides(
        source_file=path,
        cases=case_overrides,
        rules=rule_overrides,
    )


def normalize_relative_flag_paths(
    flags: List[str], invocation_cwd: Path
) -> List[str]:
    result: List[str] = []
    separate_path_flags = {"-I", "-L", "-J", "-include", "-module"}
    expect_path = False
    for flag in flags:
        if expect_path:
            candidate = Path(flag).expanduser()
            if not candidate.is_absolute():
                candidate = invocation_cwd / candidate
            result.append(str(candidate.resolve()))
            expect_path = False
            continue
        if flag in separate_path_flags:
            result.append(flag)
            expect_path = True
            continue
        matched = False
        for prefix in ("-I", "-L", "-J"):
            if flag.startswith(prefix) and flag != prefix:
                candidate = Path(flag[len(prefix) :]).expanduser()
                if not candidate.is_absolute():
                    candidate = invocation_cwd / candidate
                result.append(prefix + str(candidate.resolve()))
                matched = True
                break
        if matched:
            continue
        if flag.startswith("@") and len(flag) > 1:
            candidate = Path(flag[1:]).expanduser()
            if not candidate.is_absolute():
                candidate = invocation_cwd / candidate
            result.append("@" + str(candidate.resolve()))
            continue
        result.append(flag)
    return result


def parse_command_words(
    value: str, label: str, invocation_cwd: Path
) -> List[str]:
    try:
        words = shlex.split(value)
    except ValueError as exc:
        raise ValueError("invalid {} quoting: {}".format(label, exc))
    if not words:
        raise ValueError("{} is empty".format(label))
    first = Path(words[0]).expanduser()
    if first.is_absolute() or "/" in words[0]:
        executable = first if first.is_absolute() else invocation_cwd / first
        executable = executable.resolve()
        if not executable.is_file():
            raise ValueError(
                "{} executable does not exist: {}".format(label, executable)
            )
        if not os.access(str(executable), os.X_OK):
            raise ValueError(
                "{} executable is not executable: {}".format(label, executable)
            )
        words[0] = str(executable)
    else:
        found = shutil.which(words[0])
        if found is None:
            raise ValueError(
                "{} executable was not found: {}".format(label, words[0])
            )
        words[0] = str(Path(found).resolve())
    for index in range(1, len(words)):
        word = words[index]
        if word.startswith("-") or "=" in word:
            continue
        candidate = Path(word).expanduser()
        if not candidate.is_absolute() and (invocation_cwd / candidate).exists():
            words[index] = str((invocation_cwd / candidate).resolve())
    return words


def run_process(
    command: Sequence[str], cwd: Path, timeout: float
) -> ProcessResult:
    started = time.monotonic()
    try:
        process = subprocess.Popen(
            list(command),
            cwd=str(cwd),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            errors="replace",
            start_new_session=True,
        )
    except OSError as exc:
        return ProcessResult(
            command=list(command),
            cwd=str(cwd),
            returncode=None,
            stdout="",
            stderr="",
            duration_seconds=time.monotonic() - started,
            spawn_error=str(exc),
        )
    try:
        stdout, stderr = process.communicate(timeout=timeout)
        return ProcessResult(
            command=list(command),
            cwd=str(cwd),
            returncode=process.returncode,
            stdout=stdout,
            stderr=stderr,
            duration_seconds=time.monotonic() - started,
        )
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        stdout, stderr = process.communicate()
        return ProcessResult(
            command=list(command),
            cwd=str(cwd),
            returncode=process.returncode,
            stdout=stdout,
            stderr=stderr,
            duration_seconds=time.monotonic() - started,
            timed_out=True,
        )


class CompilerDriver:
    def __init__(
        self,
        fc: str,
        fcflags: str,
        launcher: Optional[str],
        invocation_cwd: Path,
        compile_timeout: float,
        run_timeout: float,
    ) -> None:
        self.invocation_cwd = invocation_cwd
        self.command = parse_command_words(fc, "FC", invocation_cwd)
        try:
            split_flags = shlex.split(fcflags)
        except ValueError as exc:
            raise ValueError("invalid FCFLAGS quoting: {}".format(exc))
        self.flags = normalize_relative_flag_paths(split_flags, invocation_cwd)
        if compile_timeout <= 0 or run_timeout <= 0:
            raise ValueError("compile and runtime timeouts must be positive")
        self.compile_timeout = compile_timeout
        self.run_timeout = run_timeout
        self.launcher_template = launcher
        self.launcher_words: Optional[List[str]] = None
        if launcher:
            try:
                launcher_words = shlex.split(launcher)
            except ValueError as exc:
                raise ValueError("invalid launcher quoting: {}".format(exc))
            if not launcher_words:
                raise ValueError("launcher is empty")
            if not any("{exe}" in word for word in launcher_words):
                raise ValueError("launcher must contain an {exe} placeholder")
            first = launcher_words[0]
            if "{" not in first:
                parsed_first = parse_command_words(
                    shlex.join([first]), "launcher", invocation_cwd
                )[0]
                launcher_words[0] = parsed_first
            for index in range(1, len(launcher_words)):
                word = launcher_words[index]
                if "{" in word or word.startswith("-") or "=" in word:
                    continue
                candidate = Path(word).expanduser()
                if (
                    not candidate.is_absolute()
                    and (invocation_cwd / candidate).exists()
                ):
                    launcher_words[index] = str(
                        (invocation_cwd / candidate).resolve()
                    )
            self.launcher_words = launcher_words

    @property
    def display(self) -> str:
        return shlex.join(self.command + self.flags)

    def compile(self, source: Path, obj: Path, cwd: Path) -> ProcessResult:
        command = (
            self.command
            + self.flags
            + ["-c", str(source), "-o", str(obj)]
        )
        return run_process(command, cwd, self.compile_timeout)

    def link(
        self, objects: Sequence[Path], executable: Path, cwd: Path
    ) -> ProcessResult:
        command = (
            self.command
            + self.flags
            + [str(obj) for obj in objects]
            + ["-o", str(executable)]
        )
        return run_process(command, cwd, self.compile_timeout)

    def launch_command(
        self, executable: Path, images: int
    ) -> Optional[List[str]]:
        if self.launcher_words is None:
            if images > 1:
                return None
            return [str(executable)]
        if images > 1 and not any(
            "{images}" in word for word in self.launcher_words
        ):
            raise ValueError(
                "multi-image launcher must contain an {images} placeholder"
            )
        return [
            word.replace("{images}", str(images)).replace(
                "{exe}", str(executable)
            )
            for word in self.launcher_words
        ]

    def execute(
        self, executable: Path, images: int, cwd: Path
    ) -> ProcessResult:
        command = self.launch_command(executable, images)
        if command is None:
            raise ValueError("multi-image launcher is not configured")
        return run_process(command, cwd, self.run_timeout)


def compiler_infrastructure_failure(result: ProcessResult) -> Optional[str]:
    if result.spawn_error is not None:
        return "compiler could not be started: {}".format(result.spawn_error)
    if result.timed_out:
        return "compiler timed out"
    if result.returncode is None:
        return "compiler outcome is unavailable"
    if result.returncode < 0:
        return "compiler terminated by signal {}".format(-result.returncode)
    if result.returncode in {126, 127}:
        return "compiler/wrapper returned infrastructure status {}".format(
            result.returncode
        )
    crash = CRASH_RE.search(result.combined_output)
    if crash is not None:
        return "compiler infrastructure/crash evidence: {}".format(
            crash.group(0)
        )
    return None


def artifact_error(path: Path, executable: bool = False) -> Optional[str]:
    if not path.is_file():
        return "expected artifact was not produced: {}".format(path)
    if path.stat().st_size <= 0:
        return "expected artifact is empty: {}".format(path)
    if executable and not os.access(str(path), os.X_OK):
        return "produced executable is not executable: {}".format(path)
    return None


class DiagnosticParser:
    GNU_RE = re.compile(
        r"^(?P<file>.+?\.(?:f|f90|f95|f03|f08|f18)):"
        r"(?P<line>\d+)(?::(?P<column>\d+))?:\s*"
        r"(?P<severity>fatal error|error|warning|remark|note):\s*"
        r"(?P<message>.*)$",
        re.IGNORECASE,
    )
    GNU_LOCATION_RE = re.compile(
        r"^(?P<file>.+?\.(?:f|f90|f95|f03|f08|f18)):"
        r"(?P<line>\d+)(?::(?P<column>\d+))?:\s*$",
        re.IGNORECASE,
    )
    GNU_SEVERITY_RE = re.compile(
        r"^(?P<severity>fatal error|error|warning|note):\s*"
        r"(?P<message>.*)$",
        re.IGNORECASE,
    )
    INTEL_RE = re.compile(
        r"^(?P<file>.+?\.(?:f|f90|f95|f03|f08|f18))"
        r"\((?P<line>\d+)(?:,(?P<column>\d+))?\):\s*"
        r"(?P<severity>fatal error|error|warning|remark|note)"
        r"(?:\s*#\d+)?:\s*(?P<message>.*)$",
        re.IGNORECASE,
    )
    NAG_RE = re.compile(
        r"^(?P<severity>Fatal Error|Error|Warning|Questionable):\s*"
        r"(?P<file>.+?\.(?:f|f90|f95|f03|f08|f18)),\s*line\s*"
        r"(?P<line>\d+)(?::|\s)(?P<message>.*)$",
        re.IGNORECASE,
    )
    CLASSIC_FLANG_RE = re.compile(
        r"^F90-(?P<code>[SEW])-\d+-\s*(?P<message>.*?)\s*"
        r"\((?P<file>.+?\.(?:f|f90|f95|f03|f08|f18)):\s*"
        r"(?P<line>\d+)\)\s*$",
        re.IGNORECASE,
    )
    LOC_RE = re.compile(
        r"^(?P<severity>error|warning|remark|note):\s*loc\("
        r'"(?P<file>.+?)":(?P<line>\d+):(?P<column>\d+)\):\s*'
        r"(?P<message>.*)$",
        re.IGNORECASE,
    )
    LFORTRAN_RE = re.compile(
        r"^(?P<severity>semantic error|syntax error|code generation error|"
        r"error|warning):\s*(?P<message>.+)$",
        re.IGNORECASE,
    )
    ARROW_RE = re.compile(
        r"^\s*-->\s*(?P<file>.+?):(?P<line>\d+):(?P<column>\d+)"
    )
    LINK_RE = re.compile(
        r"(?P<message>undefined reference|unresolved external|"
        r"multiple definition|duplicate symbol|ld(?:\.lld)?: error:|"
        r"linker command failed|LNK\d+).*",
        re.IGNORECASE,
    )

    def __init__(
        self, style: str = "auto", custom_patterns: Sequence[str] = ()
    ) -> None:
        self.style = style
        self.custom_patterns: List[Pattern[str]] = []
        for pattern in custom_patterns:
            try:
                compiled = re.compile(pattern, re.IGNORECASE)
            except re.error as exc:
                raise ValueError(
                    "invalid diagnostic record regex {!r}: {}".format(
                        pattern, exc
                    )
                )
            self.custom_patterns.append(compiled)

    def parse(self, text: str, phase: str) -> List[DiagnosticRecord]:
        clean_lines = [ANSI_RE.sub("", line) for line in text.splitlines()]
        records: List[DiagnosticRecord] = []
        pending_lfortran: Optional[Tuple[int, DiagnosticRecord]] = None
        pending_gnu: Optional[Tuple[int, Dict[str, str]]] = None
        for index, line in enumerate(clean_lines):
            if pending_gnu is not None:
                pending_index, location = pending_gnu
                severity = self.GNU_SEVERITY_RE.match(line)
                if severity is not None:
                    records.append(
                        DiagnosticRecord(
                            style="gnu",
                            severity=severity.group("severity"),
                            message=severity.group("message"),
                            raw=line,
                            source=location["file"],
                            line=int(location["line"]),
                            column=(
                                int(location["column"])
                                if location.get("column")
                                else None
                            ),
                            phase=phase,
                        )
                    )
                    pending_gnu = None
                    continue
                if index - pending_index > 12:
                    pending_gnu = None

            if pending_lfortran is not None:
                pending_index, pending = pending_lfortran
                arrow = self.ARROW_RE.match(line)
                if arrow is not None:
                    pending.source = arrow.group("file")
                    pending.line = int(arrow.group("line"))
                    pending.column = int(arrow.group("column"))
                    records.append(pending)
                    pending_lfortran = None
                    continue
                if index - pending_index > 8:
                    records.append(pending)
                    pending_lfortran = None

            if self.style in {"auto", "gnu"}:
                gnu_location = self.GNU_LOCATION_RE.match(line)
                if gnu_location is not None:
                    pending_gnu = (index, gnu_location.groupdict())
                    continue

            custom = self._custom_record(line, phase)
            if custom is not None:
                records.append(custom)
                continue

            match: Optional[re.Match[str]] = None
            style = ""
            if self.style in {"auto", "gnu", "flang"}:
                match = self.GNU_RE.match(line)
                style = "gnu/flang"
            if match is None and self.style in {"auto", "intel"}:
                match = self.INTEL_RE.match(line)
                style = "intel"
            if match is None and self.style in {"auto", "nag"}:
                match = self.NAG_RE.match(line)
                style = "nag"
            if match is None and self.style in {"auto", "flang"}:
                classic = self.CLASSIC_FLANG_RE.match(line)
                if classic is not None:
                    severity = {
                        "S": "error",
                        "E": "error",
                        "W": "warning",
                    }.get(classic.group("code").upper(), "error")
                    records.append(
                        DiagnosticRecord(
                            style="classic-flang",
                            severity=severity,
                            message=classic.group("message"),
                            raw=line,
                            source=classic.group("file"),
                            line=int(classic.group("line")),
                            phase=phase,
                        )
                    )
                    continue
            if match is None and self.style in {"auto", "flang"}:
                match = self.LOC_RE.match(line)
                style = "flang-loc"
            if match is not None:
                groups = match.groupdict()
                records.append(
                    DiagnosticRecord(
                        style=style,
                        severity=groups.get("severity") or "error",
                        message=groups.get("message") or line,
                        raw=line,
                        source=groups.get("file"),
                        line=(
                            int(groups["line"])
                            if groups.get("line") is not None
                            else None
                        ),
                        column=(
                            int(groups["column"])
                            if groups.get("column") is not None
                            else None
                        ),
                        phase=phase,
                    )
                )
                continue

            if self.style in {"auto", "lfortran"}:
                lfortran = self.LFORTRAN_RE.match(line)
                if lfortran is not None:
                    if pending_lfortran is not None:
                        records.append(pending_lfortran[1])
                    pending_lfortran = (
                        index,
                        DiagnosticRecord(
                            style="lfortran",
                            severity=lfortran.group("severity"),
                            message=lfortran.group("message"),
                            raw=line,
                            phase=phase,
                        ),
                    )
                    continue

            if phase == "link":
                link = self.LINK_RE.search(line)
                if link is not None:
                    records.append(
                        DiagnosticRecord(
                            style="linker",
                            severity="error",
                            message=line.strip(),
                            raw=line,
                            phase=phase,
                        )
                    )
        if pending_lfortran is not None:
            records.append(pending_lfortran[1])
        return records

    def _custom_record(
        self, line: str, phase: str
    ) -> Optional[DiagnosticRecord]:
        for pattern in self.custom_patterns:
            match = pattern.search(line)
            if match is None:
                continue
            groups = match.groupdict()
            source = groups.get("file")
            line_number = groups.get("line")
            column = groups.get("column")
            return DiagnosticRecord(
                style="custom",
                severity=groups.get("severity") or "diagnostic",
                message=groups.get("message") or match.group(0),
                raw=line,
                source=source,
                line=int(line_number) if line_number else None,
                column=int(column) if column else None,
                phase=phase,
            )
        return None


def diagnostic_source_matches(record_source: str, source: Path) -> bool:
    candidate = Path(record_source)
    try:
        if candidate.exists() and candidate.resolve() == source.resolve():
            return True
    except OSError:
        pass
    return candidate.name == source.name


def match_diagnostic(
    case: Case,
    records: Sequence[DiagnosticRecord],
    phase: str,
    override: Optional[DiagnosticExpectationOverride] = None,
) -> Tuple[Optional[DiagnosticRecord], Optional[str]]:
    pattern_texts = (
        case.metadata.error_patterns
        if override is None or override.message_regexes is None
        else override.message_regexes
    )
    patterns = [
        re.compile(pattern, re.IGNORECASE)
        for pattern in pattern_texts
    ]
    location_policy = (
        "marked" if override is None else override.location_policy
    )
    source_lines = {
        line.strip()
        for source in case.sources
        for line in read_text(source).splitlines()
        if line.strip()
    }
    message_matches = []
    for record in records:
        if record.phase != phase:
            continue
        if record.raw.strip() in source_lines:
            continue
        if any(pattern.search(record.message) for pattern in patterns):
            message_matches.append(record)
    if not message_matches:
        return (
            None,
            "no recognized diagnostic record matched the active "
            "message expectation",
        )
    if phase == "link":
        return message_matches[0], None
    if location_policy == "case-context":
        return message_matches[0], None
    if location_policy == "source":
        for record in message_matches:
            if record.source is None:
                continue
            if any(
                diagnostic_source_matches(record.source, source)
                for source in case.sources
            ):
                return record, None
        return (
            None,
            "matching diagnostic did not identify a source in the case",
        )
    for record in message_matches:
        if record.source is None or record.line is None:
            continue
        for marker in case.metadata.error_markers:
            if diagnostic_source_matches(record.source, marker.source):
                if record.line in marker.target_lines:
                    return record, None
    return (
        None,
        "matching diagnostic was not located at a TEST-ERROR-HERE statement",
    )


class WorkArea:
    def __init__(self, root: Path, keep: bool) -> None:
        self.root = root.resolve()
        self.keep = keep
        self.run_id = "run-{}-{}-{}".format(
            time.strftime("%Y%m%dT%H%M%S"),
            os.getpid(),
            uuid.uuid4().hex[:10],
        )
        self.path = self.root / self.run_id

    def __enter__(self) -> "WorkArea":
        self.path.mkdir(parents=True, exist_ok=False)
        return self

    def __exit__(self, exc_type: Any, exc: Any, traceback: Any) -> None:
        if not self.keep:
            shutil.rmtree(str(self.path))

    def case_dir(self, case_id: str) -> Path:
        safe = re.sub(r"[^A-Za-z0-9_.-]+", "_", case_id).strip("_")
        path = self.path / "{}-{}".format(safe[:80], uuid.uuid4().hex[:8])
        path.mkdir(parents=True, exist_ok=False)
        return path


def process_details(
    processes: Sequence[ProcessResult],
) -> List[Dict[str, Any]]:
    return [process.to_dict() for process in processes]


def capability_satisfied(
    requirement: str, inventory: ProcessorInventory
) -> Tuple[bool, str]:
    match = CAPABILITY_RE.fullmatch(requirement)
    if match is None:
        return False, "invalid capability expression"
    name = match.group("name")
    operator = match.group("operator")
    expected_text = match.group("value")
    actual = inventory.capability_value(name)
    if actual is None:
        return False, "{} was not inventoried".format(name)
    if operator is None:
        if name in NAMED_CAPABILITIES:
            return (
                actual >= 0,
                "{}={} (negative means unavailable)".format(name, actual),
            )
        return actual > 0, "{}={}".format(name, actual)
    expected = int(expected_text, 10)
    comparisons = {
        ">=": actual >= expected,
        "<=": actual <= expected,
        "==": actual == expected,
        ">": actual > expected,
        "<": actual < expected,
    }
    return comparisons[operator], "{}={} does not satisfy {}{}".format(
        name, actual, operator, expected
    )


class SuiteRunner:
    def __init__(
        self,
        args: argparse.Namespace,
        suite_root: Path,
        tests_root: Path,
        invocation_cwd: Path,
        work: WorkArea,
    ) -> None:
        self.args = args
        self.suite_root = suite_root
        self.tests_root = tests_root
        self.invocation_cwd = invocation_cwd
        self.work = work
        self.driver = CompilerDriver(
            fc=args.fc,
            fcflags=args.fcflags,
            launcher=args.launcher,
            invocation_cwd=invocation_cwd,
            compile_timeout=args.compile_timeout,
            run_timeout=args.run_timeout,
        )
        self.diagnostics = DiagnosticParser(
            style=args.diagnostic_style,
            custom_patterns=args.diagnostic_record_regex,
        )
        self.expectation_overrides = getattr(
            args,
            "expectation_overrides",
            DiagnosticExpectationOverrides.empty(),
        )
        self.inventory: Optional[ProcessorInventory] = None
        self.inventory_error: Optional[str] = None
        self.inventory_processes: List[ProcessResult] = []
        self.prerequisite_result: Optional[TestResult] = None
        self.calibrations: Dict[
            Tuple[int, str],
            Tuple[Optional[ProcessResult], Optional[str]],
        ] = {}

    def compile_sources(
        self, sources: Sequence[Path], work_dir: Path
    ) -> Tuple[List[Path], List[ProcessResult], Optional[str]]:
        objects: List[Path] = []
        processes: List[ProcessResult] = []
        for index, source in enumerate(sources):
            obj = work_dir / "{:03d}_{}.o".format(index, source.stem)
            result = self.driver.compile(source, obj, work_dir)
            processes.append(result)
            infrastructure = compiler_infrastructure_failure(result)
            if infrastructure is not None:
                return objects, processes, infrastructure
            if result.returncode != 0:
                return objects, processes, None
            produced = artifact_error(obj)
            if produced is not None:
                return objects, processes, produced
            objects.append(obj)
        return objects, processes, None

    def link_objects(
        self, objects: Sequence[Path], work_dir: Path
    ) -> Tuple[Path, ProcessResult, Optional[str]]:
        executable = work_dir / "case.exe"
        result = self.driver.link(objects, executable, work_dir)
        infrastructure = compiler_infrastructure_failure(result)
        if infrastructure is not None:
            return executable, result, infrastructure
        if result.returncode == 0:
            produced = artifact_error(executable, executable=True)
            if produced is not None:
                return executable, result, produced
        return executable, result, None

    def probe_inventory(self) -> Optional[ProcessorInventory]:
        if self.inventory is not None or self.inventory_error is not None:
            return self.inventory
        probe_dir = self.work.case_dir("processor-inventory")
        source = probe_dir / "processor_kind_inventory.f90"
        source.write_text(KIND_INVENTORY_SOURCE, encoding="utf-8")
        objects, compile_results, error = self.compile_sources([source], probe_dir)
        self.inventory_processes.extend(compile_results)
        if error is not None:
            self.inventory_error = error
            return None
        if not compile_results or compile_results[-1].returncode != 0:
            self.inventory_error = "ordinary processor kind inventory did not compile"
            return None
        executable, link_result, error = self.link_objects(objects, probe_dir)
        self.inventory_processes.append(link_result)
        if error is not None:
            self.inventory_error = error
            return None
        if link_result.returncode != 0:
            self.inventory_error = "ordinary processor kind inventory did not link"
            return None
        run_result = self.driver.execute(executable, 1, probe_dir)
        self.inventory_processes.append(run_result)
        if run_result.spawn_error is not None:
            self.inventory_error = "inventory executable could not start: {}".format(
                run_result.spawn_error
            )
            return None
        if run_result.timed_out:
            self.inventory_error = "inventory executable timed out"
            return None
        if run_result.returncode != 0:
            self.inventory_error = "inventory executable terminated with {}".format(
                run_result.outcome()
            )
            return None
        try:
            inventory = parse_kind_inventory(
                run_result.stdout + "\n" + run_result.stderr
            )
        except ValueError as exc:
            self.inventory_error = "invalid inventory output: {}".format(exc)
            return None

        rank_dir = self.work.case_dir("max-rank-inventory")
        rank_source = rank_dir / "processor_max_rank_inventory.f90"
        rank_source.write_text(MAX_RANK_INVENTORY_SOURCE, encoding="utf-8")
        rank_objects, rank_compile, rank_error = self.compile_sources(
            [rank_source], rank_dir
        )
        self.inventory_processes.extend(rank_compile)
        if rank_error is not None:
            inventory.max_rank_error = rank_error
        elif not rank_compile or rank_compile[-1].returncode != 0:
            inventory.max_rank_error = (
                "ordinary MAX_RANK inventory did not compile"
            )
        else:
            rank_exe, rank_link, rank_error = self.link_objects(
                rank_objects, rank_dir
            )
            self.inventory_processes.append(rank_link)
            if rank_error is not None:
                inventory.max_rank_error = rank_error
            elif rank_link.returncode != 0:
                inventory.max_rank_error = (
                    "ordinary MAX_RANK inventory did not link"
                )
            else:
                rank_run = self.driver.execute(rank_exe, 1, rank_dir)
                self.inventory_processes.append(rank_run)
                if (
                    rank_run.spawn_error is not None
                    or rank_run.timed_out
                    or rank_run.returncode != 0
                ):
                    inventory.max_rank_error = (
                        "ordinary MAX_RANK inventory did not run successfully"
                    )
                else:
                    try:
                        max_rank, max_rank_corank_1 = parse_max_rank_inventory(
                            rank_run.stdout + "\n" + rank_run.stderr
                        )
                    except ValueError as exc:
                        inventory.max_rank_error = (
                            "invalid MAX_RANK inventory output: {}".format(exc)
                        )
                    else:
                        inventory.max_rank = max_rank
                        inventory.max_rank_corank_1 = max_rank_corank_1
                        if max_rank < 15:
                            inventory.max_rank_error = (
                                "MAX_RANK {} is below the required minimum 15".format(
                                    max_rank
                                )
                            )
                        elif max_rank_corank_1 < 14:
                            inventory.max_rank_error = (
                                "MAX_RANK(1) {} is below the required minimum 14".format(
                                    max_rank_corank_1
                                )
                            )
        self.inventory = inventory
        return inventory

    def run_prerequisite(self) -> TestResult:
        if self.prerequisite_result is not None:
            return self.prerequisite_result
        work_dir = self.work.case_dir("auto-generic-prerequisite")
        source = work_dir / "auto_generic_prerequisite.f90"
        source.write_text(FEATURE_PREREQUISITE_SOURCE, encoding="utf-8")
        objects, compile_results, error = self.compile_sources([source], work_dir)
        details: Dict[str, Any] = {
            "processes": process_details(compile_results)
        }
        if error is not None:
            self.prerequisite_result = TestResult(
                case_id="@prerequisite/auto-generic",
                category="prerequisite",
                status="error",
                reason_code="compiler-infrastructure",
                message=error,
                gating=True,
                executed=False,
                details=details,
            )
            return self.prerequisite_result
        if not compile_results or compile_results[-1].returncode != 0:
            self.prerequisite_result = TestResult(
                case_id="@prerequisite/auto-generic",
                category="prerequisite",
                status="error",
                reason_code="language-prerequisite",
                message=(
                    "the valid core GENERIC/TYPEOF/type-kind-rank "
                    "prerequisite did not compile; "
                    "negative diagnostics cannot be credited"
                ),
                gating=True,
                executed=True,
                details=details,
            )
            return self.prerequisite_result
        executable, link_result, error = self.link_objects(objects, work_dir)
        details["processes"].append(link_result.to_dict())
        if error is not None:
            self.prerequisite_result = TestResult(
                case_id="@prerequisite/auto-generic",
                category="prerequisite",
                status="error",
                reason_code="compiler-infrastructure",
                message=error,
                gating=True,
                executed=False,
                details=details,
            )
            return self.prerequisite_result
        if link_result.returncode != 0:
            self.prerequisite_result = TestResult(
                case_id="@prerequisite/auto-generic",
                category="prerequisite",
                status="error",
                reason_code="language-prerequisite",
                message="valid auto-generic prerequisite did not link",
                gating=True,
                executed=True,
                details=details,
            )
            return self.prerequisite_result
        run_result = self.driver.execute(executable, 1, work_dir)
        details["processes"].append(run_result.to_dict())
        lines = runtime_lines(run_result)
        if (
            run_result.spawn_error is not None
            or run_result.timed_out
            or run_result.returncode != 0
            or "FGS-AUTO-GENERIC-PREREQUISITE-PASS" not in lines
        ):
            self.prerequisite_result = TestResult(
                case_id="@prerequisite/auto-generic",
                category="prerequisite",
                status="error",
                reason_code="language-prerequisite",
                message="valid auto-generic prerequisite did not execute correctly",
                gating=True,
                executed=True,
                details=details,
            )
            return self.prerequisite_result
        self.prerequisite_result = TestResult(
            case_id="@prerequisite/auto-generic",
            category="prerequisite",
            status="pass",
            reason_code="language-prerequisite-satisfied",
            message=(
                "core GENERIC/TYPEOF/type-kind-rank prerequisite "
                "compiled and ran"
            ),
            gating=True,
            executed=True,
            details=details,
        )
        return self.prerequisite_result

    def calibration(
        self, images: int, stop_spec: ErrorStopSpec
    ) -> Tuple[Optional[ProcessResult], Optional[str], Dict[str, Any]]:
        cache_key = (images, stop_spec.cache_key)
        if cache_key in self.calibrations:
            result, error = self.calibrations[cache_key]
            return (
                result,
                error,
                {
                    "cached": True,
                    "stop_spec": stop_spec.to_dict(self.tests_root),
                },
            )
        work_dir = self.work.case_dir(
            "error-stop-calibration-{}".format(images)
        )
        source = work_dir / "error_stop_calibration.f90"
        source.write_text(
            error_stop_calibration_source(
                stop_spec.stop_clause,
                stop_spec.flush_before_stop,
            ),
            encoding="utf-8",
        )
        objects, compile_results, error = self.compile_sources([source], work_dir)
        details: Dict[str, Any] = {
            "compile": process_details(compile_results),
            "stop_spec": stop_spec.to_dict(self.tests_root),
        }
        if error is not None:
            self.calibrations[cache_key] = (None, error)
            return None, error, details
        if not compile_results or compile_results[-1].returncode != 0:
            error = "ordinary ERROR STOP calibration did not compile"
            self.calibrations[cache_key] = (None, error)
            return None, error, details
        executable, link_result, error = self.link_objects(objects, work_dir)
        details["link"] = link_result.to_dict()
        if error is not None:
            self.calibrations[cache_key] = (None, error)
            return None, error, details
        if link_result.returncode != 0:
            error = "ordinary ERROR STOP calibration did not link"
            self.calibrations[cache_key] = (None, error)
            return None, error, details
        run_result = self.driver.execute(executable, images, work_dir)
        details["run"] = run_result.to_dict()
        lines = runtime_lines(run_result)
        if run_result.spawn_error is not None:
            error = "ERROR STOP calibration could not start: {}".format(
                run_result.spawn_error
            )
        elif run_result.timed_out:
            error = "ERROR STOP calibration timed out"
        elif run_result.returncode in {None, 0, 126, 127}:
            error = "ERROR STOP calibration had invalid outcome {}".format(
                run_result.outcome()
            )
        elif "FGS-ERROR-STOP-CALIBRATION" not in lines:
            error = "ERROR STOP calibration did not print its reachability marker"
        elif "FGS-CALIBRATION-UNEXPECTED-RETURN" in lines:
            error = "ERROR STOP calibration returned unexpectedly"
        else:
            error = None
        self.calibrations[cache_key] = (run_result, error)
        return run_result, error, details

    def execute_case(self, case: Case, gating: bool) -> TestResult:
        work_dir = self.work.case_dir(case.case_id)
        if case.category == "valid":
            return self.execute_valid(case, work_dir, gating)
        if case.category == "invalid_runtime":
            return self.execute_runtime_negative(case, work_dir, gating)
        return self.execute_compile_negative(case, work_dir, gating)

    def execute_valid(
        self, case: Case, work_dir: Path, gating: bool
    ) -> TestResult:
        objects, compile_results, error = self.compile_sources(
            case.sources, work_dir
        )
        details: Dict[str, Any] = {
            "compiler": process_details(compile_results)
        }
        if error is not None:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "compiler-infrastructure",
                error,
                gating,
                False,
                details,
            )
        if not compile_results or compile_results[-1].returncode != 0:
            return TestResult(
                case.case_id,
                case.category,
                "fail",
                "test-compile-failure",
                "valid test did not compile",
                gating,
                True,
                details,
            )
        executable, link_result, error = self.link_objects(objects, work_dir)
        details["link"] = link_result.to_dict()
        if error is not None:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "compiler-infrastructure",
                error,
                gating,
                False,
                details,
            )
        if link_result.returncode != 0:
            return TestResult(
                case.case_id,
                case.category,
                "fail",
                "test-link-failure",
                "valid test did not link",
                gating,
                True,
                details,
            )
        run_result = self.driver.execute(
            executable, case.metadata.images, work_dir
        )
        details["runtime"] = run_result.to_dict()
        if run_result.spawn_error is not None or run_result.timed_out:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "runtime-infrastructure",
                (
                    run_result.spawn_error
                    or "valid test exceeded the runtime timeout"
                ),
                gating,
                False,
                details,
            )
        if run_result.returncode in {126, 127}:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "runtime-infrastructure",
                "valid test returned infrastructure status {}".format(
                    run_result.returncode
                ),
                gating,
                True,
                details,
            )
        if run_result.returncode != 0:
            reason = (
                "runtime-signal"
                if run_result.returncode is not None
                and run_result.returncode < 0
                else "test-assertion-failure"
            )
            return TestResult(
                case.case_id,
                case.category,
                "fail",
                reason,
                "valid test terminated with {}".format(run_result.outcome()),
                gating,
                True,
                details,
            )
        return TestResult(
            case.case_id,
            case.category,
            "pass",
            "valid-runtime-pass",
            "compiled, linked, and returned status zero",
            gating,
            True,
            details,
        )

    def execute_runtime_negative(
        self, case: Case, work_dir: Path, gating: bool
    ) -> TestResult:
        objects, compile_results, error = self.compile_sources(
            case.sources, work_dir
        )
        details: Dict[str, Any] = {
            "compiler": process_details(compile_results)
        }
        if error is not None:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "compiler-infrastructure",
                error,
                gating,
                False,
                details,
            )
        if not compile_results or compile_results[-1].returncode != 0:
            return TestResult(
                case.case_id,
                case.category,
                "fail",
                "test-compile-failure",
                "runtime-negative test did not compile",
                gating,
                True,
                details,
            )
        executable, link_result, error = self.link_objects(objects, work_dir)
        details["link"] = link_result.to_dict()
        if error is not None:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "compiler-infrastructure",
                error,
                gating,
                False,
                details,
            )
        if link_result.returncode != 0:
            return TestResult(
                case.case_id,
                case.category,
                "fail",
                "test-link-failure",
                "runtime-negative test did not link",
                gating,
                True,
                details,
            )
        stop_spec = case.metadata.error_stop_spec
        if stop_spec is None:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "uncalibratable-error-stop",
                case.metadata.error_stop_error
                or "ERROR STOP code/form is unavailable",
                gating,
                False,
                details,
            )
        calibration, calibration_error, calibration_details = self.calibration(
            case.metadata.images, stop_spec
        )
        details["calibration"] = calibration_details
        if calibration_error is not None or calibration is None:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "error-stop-calibration-failure",
                calibration_error or "ERROR STOP calibration is unavailable",
                gating,
                False,
                details,
            )
        run_result = self.driver.execute(
            executable, case.metadata.images, work_dir
        )
        details["runtime"] = run_result.to_dict()
        if run_result.spawn_error is not None or run_result.timed_out:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "runtime-infrastructure",
                (
                    run_result.spawn_error
                    or "runtime-negative test exceeded the timeout"
                ),
                gating,
                False,
                details,
            )
        if run_result.returncode in {126, 127}:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "runtime-infrastructure",
                "runtime-negative test returned infrastructure status {}".format(
                    run_result.returncode
                ),
                gating,
                True,
                details,
            )
        stop_id = case.metadata.stop_id or ""
        expected = "TEST-STOP: {}".format(stop_id)
        unexpected = "TEST-UNEXPECTED-RETURN: {}".format(stop_id)
        lines = runtime_lines(run_result)
        if expected not in lines:
            return TestResult(
                case.case_id,
                case.category,
                "fail",
                "missing-runtime-marker",
                "runtime output did not contain exact line {!r}".format(
                    expected
                ),
                gating,
                True,
                details,
            )
        if unexpected in lines or any(
            line.startswith("TEST-UNEXPECTED-RETURN:") for line in lines
        ):
            return TestResult(
                case.case_id,
                case.category,
                "fail",
                "unexpected-runtime-return",
                "runtime test reported return past its intended ERROR STOP",
                gating,
                True,
                details,
            )
        if run_result.outcome() != calibration.outcome():
            return TestResult(
                case.case_id,
                case.category,
                "fail",
                "error-stop-outcome-mismatch",
                "termination {} did not match calibrated {}".format(
                    run_result.outcome(), calibration.outcome()
                ),
                gating,
                True,
                details,
            )
        return TestResult(
            case.case_id,
            case.category,
            "pass",
            "calibrated-error-stop",
            "marker and termination match ordinary ERROR STOP calibration",
            gating,
            True,
            details,
        )

    def execute_compile_negative(
        self, case: Case, work_dir: Path, gating: bool
    ) -> TestResult:
        expectation_override = self.expectation_overrides.resolve(case)
        expectation_details = (
            None
            if expectation_override is None
            else expectation_override.effective_dict(case)
        )
        prerequisite = self.run_prerequisite()
        if prerequisite.status != "pass":
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "language-prerequisite",
                "valid auto-generic prerequisite failed; rejection is not credited",
                gating,
                False,
                {
                    "prerequisite": prerequisite.to_dict(),
                    "diagnostic_expectation_override": expectation_details,
                },
            )
        objects, compile_results, error = self.compile_sources(
            case.sources, work_dir
        )
        details: Dict[str, Any] = {
            "compiler": process_details(compile_results),
            "diagnostic_expectation_override": expectation_details,
        }
        if error is not None:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "compiler-infrastructure",
                error,
                gating,
                False,
                details,
            )
        compile_records: List[DiagnosticRecord] = []
        for result in compile_results:
            compile_records.extend(
                self.diagnostics.parse(result.combined_output, "compile")
            )
        details["diagnostics"] = [
            record.to_dict() for record in compile_records
        ]
        compile_nonzero = any(
            result.returncode != 0 for result in compile_results
        )
        phase = case.metadata.error_phase
        compile_match, compile_match_error = match_diagnostic(
            case,
            compile_records,
            "compile",
            expectation_override,
        )
        strict = self.args.mode == "strict"

        if phase == "compile":
            if compile_match is None:
                return TestResult(
                    case.case_id,
                    case.category,
                    "fail",
                    "intended-diagnostic-not-found",
                    compile_match_error
                    or "intended compile diagnostic was not found",
                    gating,
                    True,
                    details,
                )
            if strict and not compile_nonzero:
                return TestResult(
                    case.case_id,
                    case.category,
                    "fail",
                    "strict-rejection-required",
                    "strict mode requires nonzero compile rejection",
                    gating,
                    True,
                    details,
                )
            return TestResult(
                case.case_id,
                case.category,
                "pass",
                "required-diagnostic-reported",
                (
                    "matching diagnostic was reported"
                    if not strict
                    else "matching diagnostic accompanied compile rejection"
                ),
                gating,
                True,
                details,
            )

        if compile_nonzero:
            if phase == "compile-or-link" and compile_match is not None:
                return TestResult(
                    case.case_id,
                    case.category,
                    "pass",
                    "required-diagnostic-reported",
                    "matching compile diagnostic accompanied rejection",
                    gating,
                    True,
                    details,
                )
            return TestResult(
                case.case_id,
                case.category,
                "fail",
                "wrong-diagnostic-phase",
                "compilation failed before the expected link diagnostic",
                gating,
                True,
                details,
            )
        if (
            phase == "compile-or-link"
            and compile_match is not None
            and not strict
        ):
            return TestResult(
                case.case_id,
                case.category,
                "pass",
                "required-diagnostic-reported",
                "matching compile diagnostic was reported with status zero",
                gating,
                True,
                details,
            )

        executable, link_result, error = self.link_objects(objects, work_dir)
        details["link"] = link_result.to_dict()
        if error is not None:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "compiler-infrastructure",
                error,
                gating,
                False,
                details,
            )
        link_records = self.diagnostics.parse(
            link_result.combined_output, "link"
        )
        details["diagnostics"].extend(
            record.to_dict() for record in link_records
        )
        if any(
            MISSING_MAIN_RE.search(record.message)
            for record in link_records
        ):
            return TestResult(
                case.case_id,
                case.category,
                "fail",
                "missing-main-link",
                "a missing program entry point is not the intended rejection",
                gating,
                True,
                details,
            )
        link_match, link_match_error = match_diagnostic(
            case,
            link_records,
            "link",
            expectation_override,
        )
        if link_match is None:
            return TestResult(
                case.case_id,
                case.category,
                "fail",
                "intended-diagnostic-not-found",
                link_match_error or "intended link diagnostic was not found",
                gating,
                True,
                details,
            )
        if strict and link_result.returncode == 0:
            return TestResult(
                case.case_id,
                case.category,
                "fail",
                "strict-rejection-required",
                "strict mode requires nonzero link rejection",
                gating,
                True,
                details,
            )
        return TestResult(
            case.case_id,
            case.category,
            "pass",
            "required-diagnostic-reported",
            (
                "matching link diagnostic was reported"
                if not strict
                else "matching link diagnostic accompanied rejection"
            ),
            gating,
            True,
            details,
        )

    def generated_results(self) -> List[TestResult]:
        inventory = self.probe_inventory()
        if inventory is None:
            return [
                TestResult(
                    "@generated/processor-kinds",
                    "generated",
                    "error",
                    "processor-inventory-failure",
                    self.inventory_error or "processor inventory failed",
                    True,
                    False,
                    {
                        "processes": process_details(
                            self.inventory_processes
                        )
                    },
                ),
                TestResult(
                    "@generated/processor-rank",
                    "generated",
                    "error",
                    "processor-inventory-failure",
                    "processor inventory is unavailable",
                    True,
                    False,
                    {},
                ),
            ]

        generated_dir = self.work.case_dir("generated-sources")
        kind_source_text, counts = generate_kind_runtime_source(inventory)
        kind_source = generated_dir / "processor_kinds_generated.f90"
        kind_source.write_text(kind_source_text, encoding="utf-8")
        extended = "extended-rank-limit" in self.args.selected_drafts
        rank_details: Optional[Dict[str, Any]] = None
        rank_source: Optional[Path] = None
        if inventory.max_rank is not None:
            rank_source_text, rank_details = generate_rank_runtime_source(
                inventory, extended_rank=extended
            )
            rank_source = generated_dir / "processor_rank_generated.f90"
            rank_source.write_text(rank_source_text, encoding="utf-8")
        manifest = generation_manifest(inventory, counts, rank_details)
        manifest_path = generated_dir / "manifest.json"
        manifest_path.write_text(
            json.dumps(manifest, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        results = [
            self.execute_generated_source(
                case_id="@generated/processor-kinds",
                source=kind_source,
                expected_marker="FGS-GENERATED-KINDS-PASS",
                gating=True,
                details={"counts": counts},
            )
        ]
        if rank_source is None:
            results.append(
                TestResult(
                    "@generated/processor-rank",
                    "generated",
                    "error",
                    "language-prerequisite",
                    inventory.max_rank_error
                    or "ordinary MAX_RANK inventory is unavailable",
                    True,
                    False,
                    {"inventory": inventory.to_dict()},
                )
            )
        else:
            rank_gating = not (
                rank_details
                and rank_details.get("draft_interpretation")
                and not self.args.gate_drafts
            )
            results.append(
                self.execute_generated_source(
                    case_id="@generated/processor-rank",
                    source=rank_source,
                    expected_marker="FGS-GENERATED-RANK-PASS",
                    gating=rank_gating,
                    details={"rank": rank_details},
                    expected_output_lines=rank_details.get(
                        "expected_output_lines"
                    ),
                )
            )
        return results

    def execute_generated_source(
        self,
        case_id: str,
        source: Path,
        expected_marker: str,
        gating: bool,
        details: Dict[str, Any],
        expected_output_lines: Optional[Sequence[str]] = None,
    ) -> TestResult:
        work_dir = self.work.case_dir(case_id)
        objects, compile_results, error = self.compile_sources([source], work_dir)
        details = dict(details)
        details["compiler"] = process_details(compile_results)
        if error is not None:
            return TestResult(
                case_id,
                "generated",
                "error",
                "compiler-infrastructure",
                error,
                gating,
                False,
                details,
            )
        if not compile_results or compile_results[-1].returncode != 0:
            return TestResult(
                case_id,
                "generated",
                "fail",
                "generated-compile-failure",
                "generated processor case did not compile",
                gating,
                True,
                details,
            )
        executable, link_result, error = self.link_objects(objects, work_dir)
        details["link"] = link_result.to_dict()
        if error is not None:
            return TestResult(
                case_id,
                "generated",
                "error",
                "compiler-infrastructure",
                error,
                gating,
                False,
                details,
            )
        if link_result.returncode != 0:
            return TestResult(
                case_id,
                "generated",
                "fail",
                "generated-link-failure",
                "generated processor case did not link",
                gating,
                True,
                details,
            )
        run_result = self.driver.execute(executable, 1, work_dir)
        details["runtime"] = run_result.to_dict()
        if run_result.spawn_error is not None or run_result.timed_out:
            return TestResult(
                case_id,
                "generated",
                "error",
                "runtime-infrastructure",
                run_result.spawn_error or "generated case timed out",
                gating,
                False,
                details,
            )
        if run_result.returncode != 0:
            return TestResult(
                case_id,
                "generated",
                "fail",
                "generated-runtime-failure",
                "generated case terminated with {}".format(
                    run_result.outcome()
                ),
                gating,
                True,
                details,
            )
        actual_output_lines = runtime_lines(run_result)
        expected_lines = (
            [expected_marker]
            if expected_output_lines is None
            else list(expected_output_lines)
        )
        if actual_output_lines != expected_lines:
            details["expected_output_lines"] = expected_lines
            details["actual_output_lines"] = actual_output_lines
            return TestResult(
                case_id,
                "generated",
                "fail",
                "generated-output-mismatch",
                "generated output did not match the expected line shape",
                gating,
                True,
                details,
            )
        return TestResult(
            case_id,
            "generated",
            "pass",
            "generated-runtime-pass",
            "generated source compiled and exercised processor cases",
            gating,
            True,
            details,
        )


def runtime_lines(result: ProcessResult) -> List[str]:
    return result.stdout.splitlines() + result.stderr.splitlines()


def selected_drafts(values: Sequence[str]) -> Set[str]:
    drafts: Set[str] = set()
    for value in values:
        for draft in value.split(","):
            draft = draft.strip()
            if not draft:
                continue
            if draft == "all":
                drafts.update(KNOWN_DRAFTS)
            elif draft not in KNOWN_DRAFTS:
                raise ValueError("unknown draft interpretation: {}".format(draft))
            else:
                drafts.add(draft)
    return drafts


def validate_draft_selection(
    drafts: Set[str], gate_drafts: bool
) -> None:
    if not gate_drafts:
        return
    for group in MUTUALLY_EXCLUSIVE_DRAFTS:
        if group.issubset(drafts):
            raise ValueError(
                "cannot gate mutually exclusive draft interpretations: "
                + " and ".join(sorted(group))
            )


def pre_execution_result(
    case: Case,
    issues: Sequence[ValidationIssue],
    args: argparse.Namespace,
    runner: SuiteRunner,
) -> Optional[TestResult]:
    case_issues = [
        issue
        for issue in issues
        if issue.case_id == case.case_id and issue.severity == "error"
    ]
    draft_case = bool(case.metadata.drafts)
    gating = not draft_case or args.gate_drafts
    if case_issues:
        return TestResult(
            case.case_id,
            case.category,
            "error",
            "test-definition",
            "; ".join(issue.message for issue in case_issues),
            gating,
            False,
            {"issues": [issue.to_dict() for issue in case_issues]},
        )
    missing_drafts = set(case.metadata.drafts) - args.selected_drafts
    if missing_drafts:
        return TestResult(
            case.case_id,
            case.category,
            "skip",
            "unresolved-draft",
            "draft interpretation not selected: {}".format(
                ", ".join(sorted(missing_drafts))
            ),
            False,
            False,
            {},
        )
    if (
        case.category == "invalid_compile_time"
        and case.metadata.diagnostic_class == "enhanced"
        and args.mode != "strict"
    ):
        return TestResult(
            case.case_id,
            case.category,
            "skip",
            "enhanced-diagnostic",
            "enhanced rejection checks run only in strict mode",
            False,
            False,
            {},
        )
    if case.metadata.images > 1 and runner.driver.launcher_words is None:
        return TestResult(
            case.case_id,
            case.category,
            "skip",
            "multi-image-unconfigured",
            "TEST-IMAGES={} requires --launcher".format(
                case.metadata.images
            ),
            False,
            False,
            {},
        )
    if case.metadata.requires:
        inventory = runner.probe_inventory()
        if inventory is None:
            return TestResult(
                case.case_id,
                case.category,
                "error",
                "processor-inventory-failure",
                runner.inventory_error or "processor inventory failed",
                gating,
                False,
                {
                    "processes": process_details(
                        runner.inventory_processes
                    )
                },
            )
        unavailable: List[str] = []
        for requirement in case.metadata.requires:
            satisfied, explanation = capability_satisfied(
                requirement, inventory
            )
            if not satisfied:
                unavailable.append(
                    "{} ({})".format(requirement, explanation)
                )
        if unavailable:
            return TestResult(
                case.case_id,
                case.category,
                "skip",
                "capability-unavailable",
                "processor capability unavailable: {}".format(
                    "; ".join(unavailable)
                ),
                False,
                False,
                {"inventory": inventory.to_dict()},
            )
    return None


def summarize_results(results: Sequence[TestResult]) -> Dict[str, Any]:
    counts = {"pass": 0, "fail": 0, "error": 0, "skip": 0}
    for result in results:
        counts[result.status] += 1
    gating_failures = [
        result
        for result in results
        if result.gating and result.status in {"fail", "error"}
    ]
    executed_gating_cases = [
        result
        for result in results
        if result.gating
        and result.executed
        and result.category not in {"prerequisite", "inventory"}
        and result.status in {"pass", "fail", "error"}
    ]
    complete = not gating_failures and bool(executed_gating_cases)
    return {
        "counts": counts,
        "gating_failures": len(gating_failures),
        "executed_gating_cases": len(executed_gating_cases),
        "complete": complete,
    }


def human_result(result: TestResult) -> str:
    if result.category == "prerequisite":
        prefix = "PREREQ-{}".format(result.status.upper())
    else:
        prefix = result.status.upper()
    gating_note = "" if result.gating else " (non-gating)"
    return "{:<12} {:<24} {}{} -- {}".format(
        prefix,
        result.reason_code,
        result.case_id,
        gating_note,
        result.message,
    )


def print_failure_output(result: TestResult) -> None:
    if result.status not in {"fail", "error"}:
        return
    processes: List[Dict[str, Any]] = []
    for key in ("compiler", "compile", "processes"):
        value = result.details.get(key)
        if isinstance(value, list):
            processes.extend(
                item for item in value if isinstance(item, dict)
            )
    for key in ("link", "runtime", "run"):
        value = result.details.get(key)
        if isinstance(value, dict):
            processes.append(value)
    for process in processes[-2:]:
        stderr = str(process.get("stderr", "")).strip()
        stdout = str(process.get("stdout", "")).strip()
        text = stderr or stdout
        if text:
            for line in text.splitlines()[-12:]:
                print("        " + line)


def run_suite(args: argparse.Namespace) -> int:
    invocation_cwd = Path.cwd().resolve()
    suite_root = Path(args.suite_root).expanduser().resolve()
    tests_root = suite_root / "tests"
    if not tests_root.is_dir():
        print("ERROR: tests directory does not exist: {}".format(tests_root), file=sys.stderr)
        return 2
    try:
        args.selected_drafts = selected_drafts(args.draft)
        validate_draft_selection(
            args.selected_drafts, args.gate_drafts
        )
        all_cases = discover_cases(tests_root)
        args.expectation_overrides = load_diagnostic_expectations(
            args.diagnostic_expectations,
            all_cases,
            invocation_cwd,
        )
        cases = select_cases(
            all_cases,
            args.selectors,
            suite_root,
            tests_root,
            invocation_cwd,
        )
        issues = [
            issue for case in cases for issue in validate_case(case)
        ]
        work_root = (
            Path(args.work_root).expanduser()
            if args.work_root
            else tests_root / ".runner-work"
        )
        with WorkArea(work_root, args.keep_work) as work:
            runner = SuiteRunner(
                args,
                suite_root,
                tests_root,
                invocation_cwd,
                work,
            )
            results: List[TestResult] = []
            prerequisite_added = False
            for case in cases:
                preliminary = pre_execution_result(case, issues, args, runner)
                if preliminary is not None:
                    results.append(preliminary)
                    continue
                gating = not case.metadata.drafts or args.gate_drafts
                result = runner.execute_case(case, gating)
                if (
                    case.category == "invalid_compile_time"
                    and runner.prerequisite_result is not None
                    and not prerequisite_added
                ):
                    results.append(runner.prerequisite_result)
                    prerequisite_added = True
                results.append(result)
            if not args.no_generated:
                results.extend(runner.generated_results())
            summary = summarize_results(results)
            payload = {
                "schema_version": 1,
                "command": "run",
                "run_id": work.run_id,
                "suite_root": str(suite_root),
                "compiler": runner.driver.display,
                "mode": args.mode,
                "selected_drafts": sorted(args.selected_drafts),
                "drafts_gating": args.gate_drafts,
                "generated_enabled": not args.no_generated,
                "diagnostic_expectations": (
                    args.expectation_overrides.disclosure(cases)
                ),
                "inventory": (
                    None
                    if runner.inventory is None
                    else runner.inventory.to_dict()
                ),
                "inventory_error": runner.inventory_error,
                "results": [result.to_dict() for result in results],
                "summary": summary,
                "work_directory": str(work.path) if args.keep_work else None,
            }
            if args.json:
                print(json.dumps(payload, indent=2, sort_keys=True))
            else:
                print("FC={}".format(runner.driver.display))
                print("mode={}".format(args.mode))
                if args.expectation_overrides.source_file is not None:
                    active_count = len(
                        args.expectation_overrides.disclosure(cases)[
                            "active_overrides"
                        ]
                    )
                    print(
                        "diagnostic-expectations={} ({} active)".format(
                            args.expectation_overrides.source_file,
                            active_count,
                        )
                    )
                for result in results:
                    print(human_result(result))
                    print_failure_output(result)
                counts = summary["counts"]
                print(
                    "\n{} passed, {} failed, {} errors, {} skipped".format(
                        counts["pass"],
                        counts["fail"],
                        counts["error"],
                        counts["skip"],
                    )
                )
                if not summary["complete"]:
                    if summary["gating_failures"]:
                        print("INCOMPLETE: gating failures occurred")
                    else:
                        print("INCOMPLETE: no gating test actually executed")
                if args.keep_work:
                    print("work: {}".format(work.path))
            if summary["gating_failures"]:
                return 1
            if not summary["complete"]:
                return 2
            return 0
    except (OSError, ValueError) as exc:
        if args.json:
            print(
                json.dumps(
                    {
                        "schema_version": 1,
                        "command": "run",
                        "fatal_error": str(exc),
                    },
                    indent=2,
                    sort_keys=True,
                )
            )
        else:
            print("ERROR: {}".format(exc), file=sys.stderr)
        return 2


def list_or_check(args: argparse.Namespace, check: bool) -> int:
    invocation_cwd = Path.cwd().resolve()
    suite_root = Path(args.suite_root).expanduser().resolve()
    tests_root = suite_root / "tests"
    try:
        if not tests_root.is_dir():
            raise ValueError(
                "tests directory does not exist: {}".format(tests_root)
            )
        all_cases = discover_cases(tests_root)
        cases = select_cases(
            all_cases,
            args.selectors,
            suite_root,
            tests_root,
            invocation_cwd,
        )
        issues = [
            issue for case in cases for issue in validate_case(case)
        ]
    except (OSError, ValueError) as exc:
        if args.json:
            print(
                json.dumps(
                    {
                        "schema_version": 1,
                        "command": "check" if check else "list",
                        "fatal_error": str(exc),
                    },
                    indent=2,
                    sort_keys=True,
                )
            )
        else:
            print("ERROR: {}".format(exc), file=sys.stderr)
        return 2
    payload = {
        "schema_version": 1,
        "command": "check" if check else "list",
        "suite_root": str(suite_root),
        "cases": [case.to_dict(tests_root) for case in cases],
        "generated_cases": generated_catalog(),
        "coverage": coverage_summary(cases),
        "issues": [issue.to_dict() for issue in issues],
        "summary": {
            "cases": len(cases),
            "errors": sum(issue.severity == "error" for issue in issues),
            "warnings": sum(issue.severity == "warning" for issue in issues),
        },
    }
    if args.json:
        print(json.dumps(payload, indent=2, sort_keys=True))
    elif check:
        for issue in issues:
            print(
                "{} {:<24} {} -- {}".format(
                    issue.severity.upper(),
                    issue.code,
                    issue.case_id,
                    issue.message,
                )
            )
        print(
            "{} cases checked, {} errors".format(
                len(cases), payload["summary"]["errors"]
            )
        )
    else:
        for case in cases:
            metadata = case.metadata
            parts = [
                case.category,
                case.case_id,
                "rules=" + ",".join(metadata.rules),
            ]
            if metadata.requires:
                parts.append("requires=" + ",".join(metadata.requires))
            if metadata.drafts:
                parts.append("draft=" + ",".join(metadata.drafts))
            if metadata.diagnostic_class:
                parts.append("diagnostic=" + metadata.diagnostic_class)
            if metadata.stop_id:
                parts.append("stop=" + metadata.stop_id)
            if metadata.images != 1:
                parts.append("images={}".format(metadata.images))
            print("\t".join(parts))
    if check and payload["summary"]["errors"]:
        return 1
    return 0


def inventory_command(args: argparse.Namespace) -> int:
    invocation_cwd = Path.cwd().resolve()
    suite_root = Path(args.suite_root).expanduser().resolve()
    tests_root = suite_root / "tests"
    work_root = (
        Path(args.work_root).expanduser()
        if args.work_root
        else tests_root / ".runner-work"
    )
    try:
        if not tests_root.is_dir():
            raise ValueError(
                "tests directory does not exist: {}".format(tests_root)
            )
        args.selected_drafts = set()
        with WorkArea(work_root, args.keep_work) as work:
            runner = SuiteRunner(
                args,
                suite_root,
                tests_root,
                invocation_cwd,
                work,
            )
            inventory = runner.probe_inventory()
            payload = {
                "schema_version": 1,
                "command": "inventory",
                "run_id": work.run_id,
                "compiler": runner.driver.display,
                "inventory": (
                    None if inventory is None else inventory.to_dict()
                ),
                "error": runner.inventory_error,
                "processes": process_details(runner.inventory_processes),
                "complete": (
                    inventory is not None
                    and inventory.max_rank is not None
                    and inventory.max_rank_error is None
                ),
                "work_directory": str(work.path) if args.keep_work else None,
            }
            if args.json:
                print(json.dumps(payload, indent=2, sort_keys=True))
            else:
                print("FC={}".format(runner.driver.display))
                if inventory is None:
                    print("ERROR processor inventory: {}".format(runner.inventory_error))
                else:
                    print(
                        "INTEGER_KINDS={}".format(
                            ",".join(map(str, inventory.integer_kinds))
                        )
                    )
                    print(
                        "REAL_KINDS={}".format(
                            ",".join(map(str, inventory.real_kinds))
                        )
                    )
                    print(
                        "LOGICAL_KINDS={}".format(
                            ",".join(map(str, inventory.logical_kinds))
                        )
                    )
                    print(
                        "CHARACTER_KINDS={}".format(
                            ",".join(map(str, inventory.character_kinds))
                        )
                    )
                    for name, value in sorted(inventory.named_kinds.items()):
                        print("{}={}".format(name.upper(), value))
                    print("MAX_RANK={}".format(inventory.max_rank))
                    print(
                        "MAX_RANK_CORANK_1={}".format(
                            inventory.max_rank_corank_1
                        )
                    )
                    if inventory.max_rank_error:
                        print(
                            "ERROR MAX_RANK inventory: {}".format(
                                inventory.max_rank_error
                            )
                        )
                    for warning in inventory.warnings:
                        print("WARNING inventory: {}".format(warning))
            return 0 if payload["complete"] else 1
    except (OSError, ValueError) as exc:
        if args.json:
            print(
                json.dumps(
                    {
                        "schema_version": 1,
                        "command": "inventory",
                        "fatal_error": str(exc),
                    },
                    indent=2,
                    sort_keys=True,
                )
            )
        else:
            print("ERROR: {}".format(exc), file=sys.stderr)
        return 2


def generate_command(args: argparse.Namespace) -> int:
    invocation_cwd = Path.cwd().resolve()
    suite_root = Path(args.suite_root).expanduser().resolve()
    tests_root = suite_root / "tests"
    output = Path(args.output).expanduser().resolve()
    work_root = (
        Path(args.work_root).expanduser()
        if args.work_root
        else tests_root / ".runner-work"
    )
    try:
        if not tests_root.is_dir():
            raise ValueError(
                "tests directory does not exist: {}".format(tests_root)
            )
        args.selected_drafts = selected_drafts(args.draft)
        validate_draft_selection(
            args.selected_drafts, args.gate_drafts
        )
        if output.exists() and not output.is_dir():
            raise ValueError("output exists and is not a directory")
        output.mkdir(parents=True, exist_ok=True)
        targets = [
            output / "processor_kinds_generated.f90",
            output / "processor_rank_generated.f90",
            output / "manifest.json",
        ]
        if not args.force and any(target.exists() for target in targets):
            raise ValueError(
                "generated output already exists; use --force to replace it"
            )
        with WorkArea(work_root, args.keep_work) as work:
            runner = SuiteRunner(
                args,
                suite_root,
                tests_root,
                invocation_cwd,
                work,
            )
            inventory = runner.probe_inventory()
            if inventory is None:
                raise ValueError(
                    runner.inventory_error or "processor inventory failed"
                )
            kind_text, counts = generate_kind_runtime_source(inventory)
            kind_path = output / "processor_kinds_generated.f90"
            kind_path.write_text(kind_text, encoding="utf-8")
            rank_details: Optional[Dict[str, Any]] = None
            rank_path: Optional[Path] = None
            if inventory.max_rank is not None:
                rank_text, rank_details = generate_rank_runtime_source(
                    inventory,
                    extended_rank=(
                        "extended-rank-limit" in args.selected_drafts
                    ),
                )
                rank_path = output / "processor_rank_generated.f90"
                rank_path.write_text(rank_text, encoding="utf-8")
            elif (output / "processor_rank_generated.f90").exists():
                (output / "processor_rank_generated.f90").unlink()
            manifest = generation_manifest(inventory, counts, rank_details)
            manifest_path = output / "manifest.json"
            manifest_path.write_text(
                json.dumps(manifest, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            results = [
                runner.execute_generated_source(
                    "@generated/processor-kinds",
                    kind_path,
                    "FGS-GENERATED-KINDS-PASS",
                    True,
                    {"counts": counts},
                )
            ]
            if rank_path is None:
                results.append(
                    TestResult(
                        "@generated/processor-rank",
                        "generated",
                        "error",
                        "language-prerequisite",
                        inventory.max_rank_error
                        or "MAX_RANK inventory unavailable",
                        True,
                        False,
                        {},
                    )
                )
            else:
                rank_gating = not (
                    rank_details
                    and rank_details.get("draft_interpretation")
                    and not args.gate_drafts
                )
                results.append(
                    runner.execute_generated_source(
                        "@generated/processor-rank",
                        rank_path,
                        "FGS-GENERATED-RANK-PASS",
                        rank_gating,
                        {"rank": rank_details},
                        rank_details.get("expected_output_lines"),
                    )
                )
            summary = summarize_results(results)
            payload = {
                "schema_version": 1,
                "command": "generate",
                "output": str(output),
                "inventory": inventory.to_dict(),
                "manifest": manifest,
                "results": [result.to_dict() for result in results],
                "summary": summary,
            }
            if args.json:
                print(json.dumps(payload, indent=2, sort_keys=True))
            else:
                print("generated: {}".format(kind_path))
                if rank_path:
                    print("generated: {}".format(rank_path))
                print("manifest: {}".format(manifest_path))
                for result in results:
                    print(human_result(result))
                    print_failure_output(result)
            return 0 if summary["complete"] else 1
    except (OSError, ValueError) as exc:
        if args.json:
            print(
                json.dumps(
                    {
                        "schema_version": 1,
                        "command": "generate",
                        "fatal_error": str(exc),
                    },
                    indent=2,
                    sort_keys=True,
                )
            )
        else:
            print("ERROR: {}".format(exc), file=sys.stderr)
        return 2


def add_suite_root(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--suite-root",
        default=str(Path(__file__).resolve().parent.parent),
        help="repository root containing tests/ (default: this repository)",
    )


def add_compiler_options(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--fc",
        default=os.environ.get("FC", "lfortran"),
        help="quoted compiler or wrapper command (default: $FC or lfortran)",
    )
    parser.add_argument(
        "--fcflags",
        default=os.environ.get("FCFLAGS", ""),
        help="quoted compiler flags (default: $FCFLAGS)",
    )
    parser.add_argument(
        "--launcher",
        default=os.environ.get("FORTRAN_TEST_LAUNCHER"),
        help=(
            "quoted runtime launcher template; use {images} and {exe}, "
            "for example 'cafrun -n {images} {exe}'"
        ),
    )
    parser.add_argument(
        "--compile-timeout",
        type=float,
        default=60.0,
        help="seconds allowed for each compile/link command (default: 60)",
    )
    parser.add_argument(
        "--run-timeout",
        type=float,
        default=20.0,
        help="seconds allowed for each executable (default: 20)",
    )
    parser.add_argument(
        "--work-root",
        help="isolated work parent (default: tests/.runner-work)",
    )
    parser.add_argument(
        "--keep-work",
        action="store_true",
        help="retain this run's unique work directory",
    )
    parser.add_argument(
        "--diagnostic-style",
        choices=["auto", "gnu", "flang", "lfortran", "intel", "nag"],
        default="auto",
        help="diagnostic record adapter (default: auto)",
    )
    parser.add_argument(
        "--diagnostic-record-regex",
        action="append",
        default=[],
        metavar="REGEX",
        help=(
            "additional vendor diagnostic-line regex; named groups file, line, "
            "column, severity, and message are recognized"
        ),
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="tests/run.sh",
        description=(
            "Compile/run auto-generic tests with metadata-aware diagnostics, "
            "processor inventory, generated cases, and ERROR STOP calibration."
        ),
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    run = subparsers.add_parser(
        "run",
        help="run selected fixtures and generated processor cases (default)",
        epilog=(
            "Runtime TEST-STOP cases are calibrated with the same literal "
            "ERROR STOP code, literal QUIET value, and optional intervening "
            "FLUSH(output_unit). Dynamic stop codes, QUIET expressions, or "
            "other intervening statements are rejected as uncalibratable."
        ),
    )
    add_suite_root(run)
    add_compiler_options(run)
    run.add_argument(
        "--mode",
        choices=["conformance", "strict"],
        default="conformance",
        help=(
            "conformance accepts a matching required diagnostic with status 0; "
            "strict requires rejection and includes enhanced checks"
        ),
    )
    run.add_argument(
        "--strict",
        action="store_true",
        help="alias for --mode strict",
    )
    run.add_argument(
        "--draft",
        action="append",
        default=[],
        metavar="ID",
        help="opt into an interpretation ID (repeat, comma-list, or 'all')",
    )
    run.add_argument(
        "--gate-drafts",
        action="store_true",
        help="make explicitly selected draft interpretation results gating",
    )
    run.add_argument(
        "--no-generated",
        action="store_true",
        help="do not inventory/generate the processor-wide runtime cases",
    )
    run.add_argument(
        "--diagnostic-expectations",
        metavar="FILE",
        help=(
            "JSON case/rule overrides with message_regexes and location "
            "marked|source|case-context"
        ),
    )
    run.add_argument("--json", action="store_true", help="emit JSON results")
    run.add_argument("selectors", nargs="*", help="test-relative paths or directories")

    listing = subparsers.add_parser(
        "list", help="list fixture metadata without invoking a compiler"
    )
    add_suite_root(listing)
    listing.add_argument("--json", action="store_true", help="emit JSON")
    listing.add_argument("selectors", nargs="*", help="paths or directories")

    check = subparsers.add_parser(
        "check", help="validate fixture metadata without invoking a compiler"
    )
    add_suite_root(check)
    check.add_argument("--json", action="store_true", help="emit JSON")
    check.add_argument("selectors", nargs="*", help="paths or directories")

    inventory = subparsers.add_parser(
        "inventory", help="probe processor kind arrays and MAX_RANK using ordinary Fortran"
    )
    add_suite_root(inventory)
    add_compiler_options(inventory)
    inventory.add_argument("--json", action="store_true", help="emit JSON")

    generate = subparsers.add_parser(
        "generate",
        help="emit, compile, and run processor-specific generated cases",
    )
    add_suite_root(generate)
    add_compiler_options(generate)
    generate.add_argument("--output", required=True, help="artifact directory")
    generate.add_argument("--force", action="store_true", help="replace generated files")
    generate.add_argument(
        "--draft",
        action="append",
        default=[],
        metavar="ID",
        help="select extended-rank-limit to exercise ranks above 15",
    )
    generate.add_argument(
        "--gate-drafts",
        action="store_true",
        help="make an extended-rank generated result gating",
    )
    generate.add_argument("--json", action="store_true", help="emit JSON")

    self_test = subparsers.add_parser(
        "self-test", help="run the runner's fake-compiler and native runtime tests"
    )
    self_test.add_argument(
        "unittest_args",
        nargs=argparse.REMAINDER,
        help="arguments forwarded to runner_selftest.py",
    )
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    arguments = list(sys.argv[1:] if argv is None else argv)
    commands = {"run", "list", "check", "inventory", "generate", "self-test"}
    if not arguments or arguments[0] not in commands:
        arguments.insert(0, "run")
    parser = build_parser()
    args = parser.parse_args(arguments)
    if args.command == "run":
        if args.strict:
            args.mode = "strict"
        return run_suite(args)
    if args.command == "list":
        return list_or_check(args, check=False)
    if args.command == "check":
        return list_or_check(args, check=True)
    if args.command == "inventory":
        return inventory_command(args)
    if args.command == "generate":
        return generate_command(args)
    if args.command == "self-test":
        script = Path(__file__).resolve().parent / "runner_selftest.py"
        completed = subprocess.run(
            [sys.executable, str(script)] + args.unittest_args,
            cwd=str(Path(__file__).resolve().parent.parent),
            check=False,
        )
        return completed.returncode
    parser.error("unknown command")
    return 2


if __name__ == "__main__":
    sys.exit(main())
