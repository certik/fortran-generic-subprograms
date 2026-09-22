#!/usr/bin/env python3
"""Self-tests for runner mechanics; these do not validate Fortran GENERIC."""

import json
import os
import shutil
import subprocess
import sys
import unittest
import uuid
from unittest import mock
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Tuple

from processor_cases import (
    FEATURE_PREREQUISITE_SOURCE,
    ProcessorInventory,
    error_stop_calibration_source,
    generate_kind_runtime_source,
    generate_rank_runtime_source,
    parse_kind_inventory,
)
from runner import DiagnosticParser, WorkArea, parse_metadata


REPOSITORY = Path(__file__).resolve().parent.parent
RUNNER = REPOSITORY / "tests" / "runner.py"
FAKE_COMPILER = (
    REPOSITORY / "tests" / "support" / "fake_fortran_compiler.py"
)
FAKE_LAUNCHER = (
    REPOSITORY / "tests" / "support" / "fake_image_launcher.py"
)
SELFTEST_ROOT = REPOSITORY / "tests" / ".selftest-work"


class RunnerSelfTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.base = SELFTEST_ROOT / (
            "selftest-{}-{}".format(os.getpid(), uuid.uuid4().hex[:10])
        )
        cls.base.mkdir(parents=True, exist_ok=False)

    @classmethod
    def tearDownClass(cls) -> None:
        shutil.rmtree(str(cls.base), ignore_errors=True)
        try:
            SELFTEST_ROOT.rmdir()
        except OSError:
            pass

    def make_suite(self, name: str) -> Path:
        suite = self.base / name
        for category in ("valid", "invalid_compile_time", "invalid_runtime"):
            (suite / "tests" / category).mkdir(parents=True, exist_ok=True)
        return suite

    def write(self, suite: Path, relative: str, text: str) -> Path:
        path = suite / "tests" / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    def fake_fc(self, relative: bool = False) -> str:
        if relative:
            script = os.path.relpath(FAKE_COMPILER, self.base)
        else:
            script = str(FAKE_COMPILER)
        return "{} {}".format(
            shlex_quote(sys.executable), shlex_quote(script)
        )

    def run_runner(
        self,
        suite: Path,
        selectors: Sequence[str],
        extra: Sequence[str] = (),
        *,
        fc: Optional[str] = None,
        cwd: Optional[Path] = None,
        env: Optional[Dict[str, str]] = None,
    ) -> Tuple[subprocess.CompletedProcess[str], Dict[str, Any]]:
        command = [
            sys.executable,
            str(RUNNER),
            "run",
            "--suite-root",
            str(suite),
            "--fc",
            fc or self.fake_fc(),
            "--no-generated",
            "--json",
        ]
        command.extend(extra)
        command.extend(selectors)
        process_env = os.environ.copy()
        if env:
            process_env.update(env)
        completed = subprocess.run(
            command,
            cwd=str(cwd or self.base),
            env=process_env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=30,
        )
        try:
            payload = json.loads(completed.stdout)
        except json.JSONDecodeError as exc:
            self.fail(
                "runner did not emit JSON: {}\nstdout:\n{}\nstderr:\n{}".format(
                    exc, completed.stdout, completed.stderr
                )
            )
        return completed, payload

    @staticmethod
    def case_result(payload: Dict[str, Any], case_id: str) -> Dict[str, Any]:
        for result in payload.get("results", []):
            if result["id"] == case_id:
                return result
        raise AssertionError("result {!r} not found".format(case_id))

    def test_inventory_accepts_zero_kinds_and_generation_is_exhaustive(self) -> None:
        output = """FGS-PROCESSOR-INVENTORY-V1
INTEGER_KIND 0
INTEGER_KIND 4
REAL_KIND 0
REAL_KIND 8
LOGICAL_KIND 0
LOGICAL_KIND 4
CHARACTER_KIND 0
CHARACTER_KIND 1
NAMED_INT8 0
NAMED_INT16 -1
NAMED_INT32 4
NAMED_INT64 -1
NAMED_REAL16 -1
NAMED_REAL32 0
NAMED_REAL64 8
NAMED_REAL128 -1
NAMED_ASCII 0
NAMED_ISO_10646 -1
COMPILER_VERSION selftest
FGS-PROCESSOR-INVENTORY-END
"""
        inventory = parse_kind_inventory(output)
        self.assertEqual(inventory.integer_kinds, [0, 4])
        self.assertEqual(inventory.named_kinds["int8"], 0)
        self.assertEqual(inventory.named_kinds["real16"], -1)
        source, counts = generate_kind_runtime_source(inventory)
        self.assertIn("integer(kind=0)", source)
        self.assertIn("real(kind=0)", source)
        self.assertIn("complex(kind=0)", source)
        self.assertIn("logical(kind=0)", source)
        self.assertIn("character(len=2, kind=0)", source)
        self.assertIn("repeat(char(0, kind=0), 2)", source)
        self.assertNotIn("achar(", source.lower())
        self.assertIn("int(1, kind=0)", source)
        self.assertIn("int(0, kind=0)", source)
        self.assertNotIn("int(7,", source)
        self.assertNotIn("int(9,", source)
        self.assertEqual(counts["integer_kinds"], 2)
        self.assertEqual(counts["complex_kinds"], 2)
        self.assertEqual(counts["kind_specializations_exercised"], 10)
        self.assertEqual(
            counts["joint_type_kind_rank_save_specializations"], 20
        )
        self.assertEqual(counts["joint_type_kind_rank_save_calls"], 40)
        self.assertIn(
            "generic function state_type_kind_rank",
            source.lower(),
        )
        self.assertIn(
            "state_type_kind_rank(character_2_rank1)",
            source,
        )
        inventory.max_rank = 24
        inventory.max_rank_corank_1 = 24
        portable, portable_details = generate_rank_runtime_source(
            inventory, extended_rank=False
        )
        extended, extended_details = generate_rank_runtime_source(
            inventory, extended_rank=True
        )
        self.assertIn("rank(0:min(15, max_rank()))", portable)
        self.assertEqual(portable_details["exercised_rank"], 15)
        self.assertEqual(portable_details["called_ranks"], list(range(16)))
        self.assertEqual(portable_details["generic_runtime_calls"], 32)
        self.assertNotIn("value_16", portable)
        self.assertIn("rank(0:max_rank())", extended)
        self.assertEqual(extended_details["exercised_rank"], 24)
        self.assertEqual(
            extended_details["called_ranks"], list(range(25))
        )
        self.assertEqual(extended_details["generic_runtime_calls"], 50)
        self.assertIn("call probe_rank(value_16,", extended)
        self.assertIn("call probe_rank(value_23,", extended)
        self.assertIn("call probe_rank(value_24,", extended)
        self.assertNotIn("signature", extended.lower())
        self.assertNotIn("100000", extended)
        self.assertIn("observed_calls", extended)
        self.assertEqual(
            extended_details["expected_output_lines"],
            [
                "FGS-GENERATED-RANK-PASS",
                "FGS-GENERATED-RANK-COUNT 25",
                "FGS-GENERATED-RANKS "
                + ",".join(str(rank) for rank in range(25)),
            ],
        )
        self.assertEqual(
            extended_details["draft_interpretation"],
            "extended-rank-limit",
        )
        inventory.max_rank = 15
        minimum_source, minimum_details = generate_rank_runtime_source(
            inventory, extended_rank=False
        )
        self.assertIn("rank(0:max_rank())", minimum_source)
        self.assertEqual(minimum_details["exercised_rank"], 15)

    def test_negative_prerequisite_is_noncirculating_core_syntax(self) -> None:
        source = FEATURE_PREREQUISITE_SOURCE.lower()
        self.assertNotIn("default kind", source)
        self.assertNotIn("max_rank", source)
        for spelling in (
            "generic function fgs_plain_identity",
            "typeof(",
            "rank(0:1)",
            "select generic",
        ):
            self.assertIn(spelling, source)

    def test_error_stop_calibration_mirrors_flush_choice(self) -> None:
        with_flush = error_stop_calibration_source(" 'code'", True)
        without_flush = error_stop_calibration_source(" 'code'", False)
        self.assertIn("flush (output_unit)", with_flush.lower())
        self.assertNotIn("flush (output_unit)", without_flush.lower())

    def test_multiline_gnu_diagnostics_and_free_form_c_lines(self) -> None:
        source = self.base / "call-marker.f90"
        source.write_text(
            """! TEST-RULE: C0
program marker
call bad() ! TEST-ERROR-HERE
stop
end
""",
            encoding="utf-8",
        )
        metadata = parse_metadata([source])
        self.assertEqual(metadata.error_markers[0].target_lines, {3})
        records = DiagnosticParser().parse(
            "{}:3:6:\n\n"
            "    3 | call bad()\n"
            "      |      1\n"
            "Error: intended multiline diagnostic\n".format(source),
            "compile",
        )
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0].line, 3)
        self.assertEqual(
            records[0].message, "intended multiline diagnostic"
        )

    def test_paths_spaces_relative_selector_wrapper_and_fixed_directory(self) -> None:
        suite = self.make_suite("suite with spaces")
        relative_compiler = self.base / "relative compiler wrapper"
        shutil.copyfile(FAKE_COMPILER, relative_compiler)
        relative_compiler.chmod(0o755)
        (self.base / "include path").mkdir(exist_ok=True)
        self.write(
            suite,
            "valid/path with spaces.f90",
            """! TEST-RULE: C1
PrOgRaM path_with_spaces
end program
""",
        )
        directory = suite / "tests" / "valid" / "fixed directory"
        directory.mkdir()
        (directory / "a_mod.f").write_text(
            """C TEST-RULE: C2
      MODULE FIXED_M
      END
""",
            encoding="utf-8",
        )
        (directory / "b_main.f90").write_text(
            """PROGRAM FIXED_MAIN
END PROGRAM
""",
            encoding="utf-8",
        )
        completed, payload = self.run_runner(
            suite,
            ["valid/path with spaces.f90", "valid/fixed directory"],
            ["--fcflags", "-I'include path'"],
            fc=shlex_quote("./" + relative_compiler.name),
            cwd=self.base,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertTrue(payload["summary"]["complete"])
        self.assertEqual(payload["summary"]["counts"]["pass"], 2)

    def test_metadata_list_and_check_need_no_compiler(self) -> None:
        suite = self.make_suite("metadata")
        self.write(
            suite,
            "valid/ordinary.f90",
            """! TEST-RULE: C10 15.6.2.4
program ordinary
end
""",
        )
        for command in ("list", "check"):
            completed = subprocess.run(
                [
                    sys.executable,
                    str(RUNNER),
                    command,
                    "--suite-root",
                    str(suite),
                    "--json",
                    "valid/ordinary.f90",
                ],
                cwd=str(self.base),
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
                timeout=10,
            )
            payload = json.loads(completed.stdout)
            self.assertEqual(completed.returncode, 0)
            self.assertEqual(payload["summary"]["errors"], 0)
            self.assertIn("C10", payload["coverage"]["rules"])

    def test_generate_command_emits_and_reports_cases(self) -> None:
        suite = self.make_suite("generate mechanics")
        output = self.base / "generated artifacts"
        completed = subprocess.run(
            [
                sys.executable,
                str(RUNNER),
                "generate",
                "--suite-root",
                str(suite),
                "--fc",
                self.fake_fc(),
                "--output",
                str(output),
                "--json",
            ],
            cwd=str(self.base),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=20,
        )
        payload = json.loads(completed.stdout)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertTrue(payload["summary"]["complete"])
        kind_source = output / "processor_kinds_generated.f90"
        rank_source = output / "processor_rank_generated.f90"
        manifest = json.loads(
            (output / "manifest.json").read_text(encoding="utf-8")
        )
        self.assertGreater(kind_source.stat().st_size, 0)
        self.assertGreater(rank_source.stat().st_size, 0)
        self.assertIn("complex(kind=0)", kind_source.read_text())
        self.assertEqual(
            manifest["generated_cases"]["processor_kinds"]["counts"][
                "complex_kinds"
            ],
            2,
        )
        self.assertEqual(
            manifest["generated_cases"]["processor_kinds"]["counts"][
                "joint_type_kind_rank_save_specializations"
            ],
            20,
        )
        rank_details = manifest["generated_cases"]["processor_rank"][
            "details"
        ]
        self.assertEqual(rank_details["called_ranks"], list(range(16)))
        self.assertEqual(rank_details["distinct_ranks_called"], 16)
        self.assertEqual(rank_details["generic_runtime_calls"], 32)
        rank_text = rank_source.read_text(encoding="utf-8")
        self.assertIn("generic subroutine probe_rank", rank_text)
        self.assertIn("call probe_rank(value_15,", rank_text)
        rank_result = self.case_result(
            payload, "@generated/processor-rank"
        )
        self.assertEqual(
            rank_result["details"]["runtime"]["stdout"].splitlines(),
            rank_details["expected_output_lines"],
        )

        extended_output = self.base / "generated extended artifacts"
        extended_env = os.environ.copy()
        extended_env["FAKE_MAX_RANK"] = "18"
        extended_completed = subprocess.run(
            [
                sys.executable,
                str(RUNNER),
                "generate",
                "--suite-root",
                str(suite),
                "--fc",
                self.fake_fc(),
                "--output",
                str(extended_output),
                "--draft",
                "extended-rank-limit",
                "--json",
            ],
            cwd=str(self.base),
            env=extended_env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=20,
        )
        extended_payload = json.loads(extended_completed.stdout)
        self.assertEqual(
            extended_completed.returncode,
            0,
            extended_completed.stderr,
        )
        extended_manifest = json.loads(
            (extended_output / "manifest.json").read_text(encoding="utf-8")
        )
        extended_details = extended_manifest["generated_cases"][
            "processor_rank"
        ]["details"]
        self.assertEqual(extended_details["called_ranks"], list(range(19)))
        self.assertEqual(extended_details["generic_runtime_calls"], 38)
        extended_rank_text = (
            extended_output / "processor_rank_generated.f90"
        ).read_text(encoding="utf-8")
        for rank in (16, 17, 18):
            self.assertIn(
                "call probe_rank(value_{},".format(rank),
                extended_rank_text,
            )
        extended_result = self.case_result(
            extended_payload, "@generated/processor-rank"
        )
        self.assertFalse(extended_result["gating"])
        self.assertEqual(
            extended_result["details"]["runtime"]["stdout"].splitlines(),
            extended_details["expected_output_lines"],
        )

    def test_diagnostic_must_be_record_not_source_echo(self) -> None:
        suite = self.make_suite("diagnostic echo")
        self.write(
            suite,
            "invalid_compile_time/echo.f90",
            """! TEST-RULE: C20
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: intended constraint violation
module echo_m
! TEST-ERROR-HERE
  integer :: offending
! FAKE-ECHO-SOURCE:
! FAKE-DIAGNOSTIC: HERE|Error|unrelated parser complaint
! FAKE-COMPILE-EXIT: 1
end module
""",
        )
        completed, payload = self.run_runner(
            suite, ["invalid_compile_time/echo.f90"]
        )
        result = self.case_result(
            payload, "invalid_compile_time/echo.f90"
        )
        self.assertEqual(completed.returncode, 1)
        self.assertEqual(result["status"], "fail")
        self.assertEqual(
            result["reason_code"], "intended-diagnostic-not-found"
        )

    def test_matching_status_zero_is_conformance_only(self) -> None:
        suite = self.make_suite("status zero")
        self.write(
            suite,
            "invalid_compile_time/reported.f90",
            """! TEST-RULE: C21
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: intended constraint violation
module reported_m
! TEST-ERROR-HERE
  integer :: offending
! FAKE-DIAGNOSTIC: HERE|Warning|intended constraint violation
end module
""",
        )
        completed, payload = self.run_runner(
            suite, ["invalid_compile_time/reported.f90"]
        )
        result = self.case_result(
            payload, "invalid_compile_time/reported.f90"
        )
        self.assertEqual(completed.returncode, 0)
        self.assertEqual(result["status"], "pass")
        strict_completed, strict_payload = self.run_runner(
            suite,
            ["invalid_compile_time/reported.f90"],
            ["--strict"],
        )
        strict_result = self.case_result(
            strict_payload, "invalid_compile_time/reported.f90"
        )
        self.assertEqual(strict_completed.returncode, 1)
        self.assertEqual(
            strict_result["reason_code"], "strict-rejection-required"
        )

    def test_custom_vendor_diagnostic_record_adapter(self) -> None:
        suite = self.make_suite("vendor diagnostic")
        self.write(
            suite,
            "invalid_compile_time/vendor.f90",
            """! TEST-RULE: C22
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: vendor intended constraint
module vendor_m
! TEST-ERROR-HERE
  integer :: offending
! FAKE-RAW-DIAGNOSTIC: VENDOR|{source}|{here}|error|vendor intended constraint
! FAKE-COMPILE-EXIT: 1
end module
""",
        )
        adapter = (
            r"^VENDOR\|(?P<file>.+)\|(?P<line>\d+)\|"
            r"(?P<severity>[^|]+)\|(?P<message>.+)$"
        )
        completed, payload = self.run_runner(
            suite,
            ["invalid_compile_time/vendor.f90"],
            ["--diagnostic-record-regex", adapter],
        )
        result = self.case_result(
            payload, "invalid_compile_time/vendor.f90"
        )
        self.assertEqual(completed.returncode, 0)
        self.assertEqual(result["status"], "pass")
        self.assertEqual(
            result["details"]["diagnostics"][0]["style"], "custom"
        )

    def test_explicit_vendor_expectation_overrides_only(self) -> None:
        suite = self.make_suite("vendor expectation override")
        case_id = "invalid_compile_time/vendor_message.f90"
        self.write(
            suite,
            case_id,
            """! TEST-RULE: C23
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: required english diagnostic
module vendor_message_m
! TEST-ERROR-HERE
  integer :: offending
! FAKE-RAW-DIAGNOSTIC: VENDOR|error|VX123 mensaje localizado
! FAKE-RAW-DIAGNOSTIC: VENDORSRC|{source}|error|VS456 mensaje localizado
! FAKE-COMPILE-EXIT: 1
end module
""",
        )
        adapter = (
            r"^VENDOR\|(?P<severity>[^|]+)\|(?P<message>.+)$"
        )
        base_options = ["--diagnostic-record-regex", adapter]

        default_run, default_payload = self.run_runner(
            suite, [case_id], base_options
        )
        default_result = self.case_result(default_payload, case_id)
        self.assertEqual(default_run.returncode, 1)
        self.assertEqual(default_result["status"], "fail")

        marked_file = suite / "marked-expectations.json"
        marked_file.write_text(
            json.dumps(
                {
                    "cases": {
                        case_id: {
                            "message_regexes": ["VX123"],
                        }
                    }
                }
            ),
            encoding="utf-8",
        )
        marked_run, marked_payload = self.run_runner(
            suite,
            [case_id],
            base_options
            + ["--diagnostic-expectations", str(marked_file)],
        )
        marked_result = self.case_result(marked_payload, case_id)
        self.assertEqual(marked_run.returncode, 1)
        self.assertEqual(marked_result["status"], "fail")

        case_file = suite / "case-expectations.json"
        case_file.write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "cases": {
                        case_id: {
                            "message_regexes": ["VX123"],
                            "location": "case-context",
                        }
                    },
                }
            ),
            encoding="utf-8",
        )
        case_run, case_payload = self.run_runner(
            suite,
            [case_id],
            base_options
            + ["--diagnostic-expectations", str(case_file)],
        )
        case_result = self.case_result(case_payload, case_id)
        self.assertEqual(case_run.returncode, 0)
        self.assertEqual(case_result["status"], "pass")
        active = case_payload["diagnostic_expectations"][
            "active_overrides"
        ]
        self.assertEqual(len(active), 1)
        self.assertEqual(active[0]["selector_type"], "case")
        self.assertEqual(active[0]["location_policy"], "case-context")
        self.assertEqual(
            active[0]["preserved_error_phase"], "compile"
        )
        self.assertEqual(
            active[0]["preserved_diagnostic_class"], "required"
        )

        rule_file = suite / "rule-expectations.json"
        rule_file.write_text(
            json.dumps(
                {
                    "rules": {
                        "C23": {
                            "message_regexes": ["VX123"],
                            "location": "case-context",
                        }
                    }
                }
            ),
            encoding="utf-8",
        )
        rule_run, rule_payload = self.run_runner(
            suite,
            [case_id],
            base_options
            + ["--diagnostic-expectations", str(rule_file)],
        )
        self.assertEqual(rule_run.returncode, 0)
        self.assertEqual(
            rule_payload["diagnostic_expectations"][
                "active_overrides"
            ][0]["selector_type"],
            "rule",
        )

        source_file = suite / "source-expectations.json"
        source_file.write_text(
            json.dumps(
                {
                    "cases": {
                        case_id: {
                            "message_regexes": ["VS456"],
                            "location": "source",
                        }
                    }
                }
            ),
            encoding="utf-8",
        )
        source_adapter = (
            r"^VENDORSRC\|(?P<file>[^|]+)\|"
            r"(?P<severity>[^|]+)\|(?P<message>.+)$"
        )
        source_run, source_payload = self.run_runner(
            suite,
            [case_id],
            [
                "--diagnostic-record-regex",
                source_adapter,
                "--diagnostic-expectations",
                str(source_file),
            ],
        )
        self.assertEqual(source_run.returncode, 0)
        self.assertEqual(
            self.case_result(source_payload, case_id)["status"],
            "pass",
        )

        invalid_documents = [
            {
                "cases": {
                    "invalid_compile_time/missing.f90": {
                        "message_regexes": ["VX123"]
                    }
                }
            },
            {
                "rules": {
                    "UNKNOWN-RULE": {
                        "message_regexes": ["VX123"]
                    }
                }
            },
            {
                "cases": {
                    case_id: {
                        "message_regexes": "VX123",
                    }
                }
            },
            {
                "cases": {
                    case_id: {
                        "message_regexes": ["["],
                    }
                }
            },
            {
                "cases": {
                    case_id: {
                        "message_regexes": ["VX123"],
                        "location": "anywhere",
                    }
                }
            },
        ]
        for index, document in enumerate(invalid_documents):
            invalid_file = suite / "invalid-{}.json".format(index)
            invalid_file.write_text(
                json.dumps(document), encoding="utf-8"
            )
            invalid_run, invalid_payload = self.run_runner(
                suite,
                [case_id],
                base_options
                + [
                    "--diagnostic-expectations",
                    str(invalid_file),
                ],
            )
            self.assertEqual(invalid_run.returncode, 2)
            self.assertIn("fatal_error", invalid_payload)

    def test_missing_source_compiler_and_timeout_are_errors(self) -> None:
        suite = self.make_suite("infrastructure")
        self.write(
            suite,
            "valid/slow.f90",
            """! TEST-RULE: C30
program slow
! FAKE-COMPILE-SLEEP: 1
end
""",
        )
        self.write(
            suite,
            "valid/slow_runtime.f90",
            """! TEST-RULE: C30
program slow_runtime
! FAKE-RUN-SLEEP: 1
end
""",
        )
        self.write(
            suite,
            "valid/compiler_127.f90",
            """! TEST-RULE: C30
program compiler_127
! FAKE-COMPILE-EXIT: 127
end
""",
        )
        missing_source, payload = self.run_runner(
            suite, ["valid/does-not-exist.f90"]
        )
        self.assertEqual(missing_source.returncode, 2)
        self.assertIn("selector does not exist", payload["fatal_error"])
        missing_compiler, payload = self.run_runner(
            suite,
            ["valid/slow.f90"],
            fc="./compiler-that-does-not-exist",
        )
        self.assertEqual(missing_compiler.returncode, 2)
        self.assertIn("does not exist", payload["fatal_error"])
        timed_out, payload = self.run_runner(
            suite,
            ["valid/slow.f90"],
            ["--compile-timeout", "0.1"],
        )
        result = self.case_result(payload, "valid/slow.f90")
        self.assertEqual(timed_out.returncode, 1)
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["reason_code"], "compiler-infrastructure")
        runtime_timeout, payload = self.run_runner(
            suite,
            ["valid/slow_runtime.f90"],
            ["--run-timeout", "0.1"],
        )
        result = self.case_result(payload, "valid/slow_runtime.f90")
        self.assertEqual(runtime_timeout.returncode, 1)
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["reason_code"], "runtime-infrastructure")
        compiler_127, payload = self.run_runner(
            suite, ["valid/compiler_127.f90"]
        )
        result = self.case_result(payload, "valid/compiler_127.f90")
        self.assertEqual(compiler_127.returncode, 1)
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["reason_code"], "compiler-infrastructure")

    def test_language_prerequisite_blocks_false_negative_pass(self) -> None:
        suite = self.make_suite("prerequisite")
        self.write(
            suite,
            "invalid_compile_time/negative.f90",
            """! TEST-RULE: C31
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: intended generic constraint
module negative_m
! TEST-ERROR-HERE
  integer :: bad
! FAKE-DIAGNOSTIC: HERE|Error|intended generic constraint
! FAKE-COMPILE-EXIT: 1
end
""",
        )
        completed, payload = self.run_runner(
            suite,
            ["invalid_compile_time/negative.f90"],
            env={"FAKE_REJECT_PREREQUISITE": "1"},
        )
        result = self.case_result(
            payload, "invalid_compile_time/negative.f90"
        )
        self.assertEqual(completed.returncode, 1)
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["reason_code"], "language-prerequisite")
        prerequisite = self.case_result(
            payload, "@prerequisite/auto-generic"
        )
        self.assertEqual(
            prerequisite["reason_code"], "language-prerequisite"
        )

    def test_compiler_signal_never_credits_diagnostic(self) -> None:
        suite = self.make_suite("compiler signal")
        self.write(
            suite,
            "invalid_compile_time/crash.f90",
            """! TEST-RULE: C32
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: intended crash constraint
module crash_m
! TEST-ERROR-HERE
  integer :: bad
! FAKE-DIAGNOSTIC: HERE|Error|intended crash constraint
! FAKE-COMPILE-SIGNAL: 15
end
""",
        )
        completed, payload = self.run_runner(
            suite, ["invalid_compile_time/crash.f90"]
        )
        result = self.case_result(
            payload, "invalid_compile_time/crash.f90"
        )
        self.assertEqual(completed.returncode, 1)
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["reason_code"], "compiler-infrastructure")

    def test_explicit_link_and_case_insensitive_program(self) -> None:
        suite = self.make_suite("explicit link")
        self.write(
            suite,
            "invalid_compile_time/link.f90",
            """! TEST-RULE: C40
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: intended_symbol
! TEST-ERROR-PHASE: link
PrOgRaM link_case
! TEST-ERROR-HERE
  call intended_symbol()
! FAKE-LINK-DIAGNOSTIC: undefined reference to intended_symbol
! FAKE-LINK-EXIT: 1
END PROGRAM
""",
        )
        self.write(
            suite,
            "invalid_compile_time/missing_main.f90",
            """! TEST-RULE: C40
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: undefined reference
! TEST-ERROR-PHASE: link
PROGRAM missing_main_case
! TEST-ERROR-HERE
  call ordinary()
! FAKE-LINK-DIAGNOSTIC: undefined reference to main
! FAKE-LINK-EXIT: 1
END PROGRAM
""",
        )
        completed, payload = self.run_runner(
            suite, ["invalid_compile_time/link.f90"]
        )
        result = self.case_result(
            payload, "invalid_compile_time/link.f90"
        )
        self.assertEqual(completed.returncode, 0)
        self.assertEqual(result["status"], "pass")
        self.assertIn("link", result["details"])
        missing_completed, missing_payload = self.run_runner(
            suite, ["invalid_compile_time/missing_main.f90"]
        )
        missing_result = self.case_result(
            missing_payload, "invalid_compile_time/missing_main.f90"
        )
        self.assertEqual(missing_completed.returncode, 1)
        self.assertEqual(
            missing_result["reason_code"], "missing-main-link"
        )

    def test_module_only_and_empty_directories_do_not_false_pass(self) -> None:
        suite = self.make_suite("directories")
        self.write(
            suite,
            "invalid_compile_time/module_only/a_mod.f90",
            """! TEST-RULE: C41
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: intended module constraint
module module_only
! TEST-ERROR-HERE
  integer :: ordinary
end module
""",
        )
        empty = suite / "tests" / "invalid_compile_time" / "empty"
        empty.mkdir()
        completed, payload = self.run_runner(
            suite, ["invalid_compile_time/module_only"]
        )
        result = self.case_result(
            payload, "invalid_compile_time/module_only"
        )
        self.assertEqual(completed.returncode, 1)
        self.assertEqual(
            result["reason_code"], "intended-diagnostic-not-found"
        )
        self.assertNotIn("link", result["details"])
        empty_completed, empty_payload = self.run_runner(
            suite, ["invalid_compile_time/empty"]
        )
        self.assertEqual(empty_completed.returncode, 2)
        self.assertIn("contains no test cases", empty_payload["fatal_error"])

    def test_capability_draft_enhanced_and_images_skips_are_explicit(self) -> None:
        suite = self.make_suite("skips")
        self.write(
            suite,
            "valid/zero_kind.f90",
            """! TEST-RULE: C50
! TEST-REQUIRES: int8
program zero_kind
end
""",
        )
        self.write(
            suite,
            "valid/unavailable_kind.f90",
            """! TEST-RULE: C51
! TEST-REQUIRES: real16
program unavailable
end
""",
        )
        self.write(
            suite,
            "valid/draft.f90",
            """! TEST-RULE: C52
! TEST-DRAFT: empty-expansion
program draft_case
end
""",
        )
        self.write(
            suite,
            "valid/images.f90",
            """! TEST-RULE: C53
! TEST-IMAGES: 2
program images
end
""",
        )
        self.write(
            suite,
            "invalid_compile_time/enhanced.f90",
            """! TEST-RULE: C54
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: enhanced intended constraint
module enhanced_m
! TEST-ERROR-HERE
  integer :: bad
end
""",
        )
        completed, payload = self.run_runner(
            suite,
            [
                "valid/zero_kind.f90",
                "valid/unavailable_kind.f90",
                "valid/draft.f90",
                "valid/images.f90",
                "invalid_compile_time/enhanced.f90",
            ],
        )
        self.assertEqual(completed.returncode, 0)
        self.assertEqual(
            self.case_result(payload, "valid/zero_kind.f90")["status"],
            "pass",
        )
        expected = {
            "valid/unavailable_kind.f90": "capability-unavailable",
            "valid/draft.f90": "unresolved-draft",
            "valid/images.f90": "multi-image-unconfigured",
            "invalid_compile_time/enhanced.f90": "enhanced-diagnostic",
        }
        for case_id, reason in expected.items():
            result = self.case_result(payload, case_id)
            self.assertEqual(result["status"], "skip")
            self.assertEqual(result["reason_code"], reason)

    def test_mutually_exclusive_character_drafts_cannot_both_gate(self) -> None:
        suite = self.make_suite("character draft readings")
        self.write(
            suite,
            "valid/generic_reading.f90",
            """! TEST-RULE: R704
! TEST-DRAFT: character-generic-parse
program generic_reading
end
""",
        )
        self.write(
            suite,
            "valid/ordinary_reading.f90",
            """! TEST-RULE: R704
! TEST-DRAFT: character-ordinary-parse
program ordinary_reading
end
""",
        )
        selectors = [
            "valid/generic_reading.f90",
            "valid/ordinary_reading.f90",
        ]
        observed, observed_payload = self.run_runner(
            suite,
            selectors,
            ["--draft", "all"],
        )
        self.assertEqual(observed.returncode, 2)
        self.assertEqual(
            [
                result["status"]
                for result in observed_payload["results"]
            ],
            ["pass", "pass"],
        )
        self.assertTrue(
            all(
                not result["gating"]
                for result in observed_payload["results"]
            )
        )

        gated, gated_payload = self.run_runner(
            suite,
            selectors,
            ["--draft", "all", "--gate-drafts"],
        )
        self.assertEqual(gated.returncode, 2)
        self.assertIn(
            "cannot gate mutually exclusive draft interpretations",
            gated_payload["fatal_error"],
        )

    def test_image_launcher_placeholders_execute_multi_image_case(self) -> None:
        suite = self.make_suite("image launcher")
        self.write(
            suite,
            "valid/images.f90",
            """! TEST-RULE: C55
! TEST-IMAGES: 3
program images
end
""",
        )
        launcher = "{} {} --images {{images}} --exe {{exe}}".format(
            shlex_quote(sys.executable),
            shlex_quote(str(FAKE_LAUNCHER)),
        )
        completed, payload = self.run_runner(
            suite,
            ["valid/images.f90"],
            ["--launcher", launcher],
        )
        result = self.case_result(payload, "valid/images.f90")
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(result["status"], "pass")

    def runtime_source(self, directives: str) -> str:
        return """! TEST-RULE: 11.6
! TEST-STOP: runtime-case
program runtime_case
  write (*, '(a)') 'TEST-STOP: runtime-case'
  error stop 'intended'
  write (*, '(a)') 'TEST-UNEXPECTED-RETURN: runtime-case'
{directives}
end program
""".format(
            directives=directives
        )

    def test_runtime_protocol_failures_and_calibrated_acceptance(self) -> None:
        suite = self.make_suite("runtime protocol")
        cases = {
            "accepted": (
                "! FAKE-RUN-OUTPUT: TEST-STOP: runtime-case\n"
                "! FAKE-RUN-EXIT: 23\n",
                "pass",
                "calibrated-error-stop",
            ),
            "exit127": (
                "! FAKE-RUN-OUTPUT: TEST-STOP: runtime-case\n"
                "! FAKE-RUN-EXIT: 127\n",
                "error",
                "runtime-infrastructure",
            ),
            "missing_marker": (
                "! FAKE-ECHO-SOURCE:\n! FAKE-RUN-EXIT: 23\n",
                "fail",
                "missing-runtime-marker",
            ),
            "omitted_stop": (
                "! FAKE-RUN-OUTPUT: TEST-STOP: runtime-case\n"
                "! FAKE-RUN-EXIT: 0\n",
                "fail",
                "error-stop-outcome-mismatch",
            ),
            "unexpected_return": (
                "! FAKE-RUN-OUTPUT: TEST-STOP: runtime-case\n"
                "! FAKE-RUN-OUTPUT: TEST-UNEXPECTED-RETURN: runtime-case\n"
                "! FAKE-RUN-EXIT: 23\n",
                "fail",
                "unexpected-runtime-return",
            ),
            "unexpected_signal": (
                "! FAKE-RUN-OUTPUT: TEST-STOP: runtime-case\n"
                "! FAKE-RUN-SIGNAL: 15\n",
                "fail",
                "error-stop-outcome-mismatch",
            ),
            "opaque_134": (
                "! FAKE-RUN-OUTPUT: TEST-STOP: runtime-case\n"
                "! FAKE-RUN-EXIT: 134\n",
                "fail",
                "error-stop-outcome-mismatch",
            ),
        }
        for name, (directives, _, _) in cases.items():
            self.write(
                suite,
                "invalid_runtime/{}.f90".format(name),
                self.runtime_source(directives),
            )
        for name, (_, status, reason) in cases.items():
            with self.subTest(name=name):
                completed, payload = self.run_runner(
                    suite, ["invalid_runtime/{}.f90".format(name)]
                )
                result = self.case_result(
                    payload, "invalid_runtime/{}.f90".format(name)
                )
                expected_return = 0 if status == "pass" else 1
                self.assertEqual(completed.returncode, expected_return)
                self.assertEqual(result["status"], status)
                self.assertEqual(result["reason_code"], reason)
                if name == "opaque_134":
                    self.assertEqual(
                        result["details"]["runtime"]["outcome"],
                        {"kind": "exit", "status": 134},
                    )

    def test_error_stop_calibration_uses_each_literal_and_quiet_form(self) -> None:
        suite = self.make_suite("literal stop calibration")
        cases = {
            "alpha": ('"alpha"', None),
            "beta": ('"beta"', None),
            "alpha_quiet": ('"alpha"', ".true."),
        }
        selectors: List[str] = []
        for name, (literal, quiet) in cases.items():
            stop_id = "literal-{}".format(name)
            quiet_clause = (
                "" if quiet is None else ", quiet = {}".format(quiet)
            )
            self.write(
                suite,
                "invalid_runtime/{}.f90".format(name),
                """! TEST-RULE: 11.6
! TEST-STOP: {stop_id}
program literal_stop
                  use, intrinsic :: iso_fortran_env, only: output_unit
                  write (output_unit, '(a)') 'TEST-STOP: {stop_id}'
                  flush (output_unit)
                  error stop {literal}{quiet_clause}
                  write (output_unit, '(a)') 'TEST-UNEXPECTED-RETURN: {stop_id}'
! FAKE-RUN-OUTPUT: TEST-STOP: {stop_id}
end program
""".format(
                    stop_id=stop_id,
                    literal=literal,
                    quiet_clause=quiet_clause,
                ),
            )
            selectors.append("invalid_runtime/{}.f90".format(name))

        completed, payload = self.run_runner(
            suite,
            selectors,
            env={"FAKE_STOP_STATUS_BY_LITERAL": "1"},
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        calibration_statuses = set()
        for name, (literal, quiet) in cases.items():
            result = self.case_result(
                payload, "invalid_runtime/{}.f90".format(name)
            )
            self.assertEqual(result["status"], "pass")
            stop_spec = result["details"]["calibration"]["stop_spec"]
            self.assertEqual(stop_spec["code_literal"], literal)
            self.assertEqual(stop_spec["quiet_literal"], quiet)
            self.assertTrue(stop_spec["flush_before_stop"])
            calibration_statuses.add(
                result["details"]["calibration"]["run"]["outcome"]["status"]
            )
        self.assertEqual(len(calibration_statuses), len(cases))

    def test_dynamic_error_stop_code_is_not_certified(self) -> None:
        suite = self.make_suite("dynamic stop code")
        self.write(
            suite,
            "invalid_runtime/dynamic.f90",
            """! TEST-RULE: 11.6
! TEST-STOP: dynamic-code
program dynamic_stop
  integer :: code
  code = 7
  write (*, '(a)') 'TEST-STOP: dynamic-code'
  error stop code
  write (*, '(a)') 'TEST-UNEXPECTED-RETURN: dynamic-code'
end program
""",
        )
        self.write(
            suite,
            "invalid_runtime/arbitrary.f90",
            """! TEST-RULE: 11.6
! TEST-STOP: arbitrary-command
program arbitrary_command
  write (*, '(a)') 'TEST-STOP: arbitrary-command'
  call unrelated()
  error stop 'literal'
  write (*, '(a)') 'TEST-UNEXPECTED-RETURN: arbitrary-command'
contains
  subroutine unrelated()
  end subroutine
end program
""",
        )
        completed, payload = self.run_runner(
            suite, ["invalid_runtime/dynamic.f90"]
        )
        result = self.case_result(
            payload, "invalid_runtime/dynamic.f90"
        )
        self.assertEqual(completed.returncode, 1)
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["reason_code"], "test-definition")
        issue_codes = {
            issue["code"] for issue in result["details"]["issues"]
        }
        self.assertIn("uncalibratable-error-stop", issue_codes)
        arbitrary_completed, arbitrary_payload = self.run_runner(
            suite, ["invalid_runtime/arbitrary.f90"]
        )
        arbitrary = self.case_result(
            arbitrary_payload, "invalid_runtime/arbitrary.f90"
        )
        self.assertEqual(arbitrary_completed.returncode, 1)
        self.assertEqual(arbitrary["status"], "error")
        self.assertIn(
            "uncalibratable-error-stop",
            {
                issue["code"]
                for issue in arbitrary["details"]["issues"]
            },
        )

    def test_native_error_stop_matches_native_calibration(self) -> None:
        compiler = shutil.which("gfortran")
        if compiler is None:
            self.skipTest("gfortran is unavailable")
        suite = self.make_suite("native error stop")
        self.write(
            suite,
            "invalid_runtime/native.f90",
            """! TEST-RULE: 11.6
! TEST-STOP: native-error-stop
program native_error_stop
  use, intrinsic :: iso_fortran_env, only: output_unit
  write (output_unit, '(a)') 'TEST-STOP: native-error-stop'
  flush (output_unit)
  error stop 'native self-test'
  write (output_unit, '(a)') 'TEST-UNEXPECTED-RETURN: native-error-stop'
end program
""",
        )
        completed, payload = self.run_runner(
            suite,
            ["invalid_runtime/native.f90"],
            fc=compiler,
        )
        result = self.case_result(
            payload, "invalid_runtime/native.f90"
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(result["reason_code"], "calibrated-error-stop")

    def test_work_area_accepts_tmp_and_preserves_configured_parent(self) -> None:
        tmp_work = WorkArea(
            Path(
                "/tmp/fortran-generic-runner-selftest"
                "/tests/.runner-work"
            ),
            keep=False,
        )
        self.assertEqual(
            tmp_work.root,
            Path(
                "/tmp/fortran-generic-runner-selftest"
                "/tests/.runner-work"
            ).resolve(),
        )

        parent = self.base / "preserved work parent"
        parent.mkdir()
        sentinel = parent / "keep.txt"
        sentinel.write_text("keep", encoding="utf-8")
        with WorkArea(parent, keep=False) as work:
            run_path = work.path
            (run_path / "artifact").write_text("owned", encoding="utf-8")
        self.assertTrue(parent.is_dir())
        self.assertEqual(sentinel.read_text(encoding="utf-8"), "keep")
        self.assertFalse(run_path.exists())

        failing_parent = self.base / "cleanup failure parent"
        failing_parent.mkdir()
        failing_work = WorkArea(failing_parent, keep=False)
        failing_work.__enter__()
        try:
            with mock.patch(
                "runner.shutil.rmtree",
                side_effect=OSError("cleanup failed"),
            ):
                with self.assertRaisesRegex(OSError, "cleanup failed"):
                    failing_work.__exit__(None, None, None)
        finally:
            shutil.rmtree(failing_work.path, ignore_errors=True)

    def test_concurrent_runs_use_distinct_work_directories(self) -> None:
        suite = self.make_suite("concurrent")
        self.write(
            suite,
            "valid/concurrent.f90",
            """! TEST-RULE: C60
program concurrent
! FAKE-COMPILE-SLEEP: 0.2
end
""",
        )
        command = [
            sys.executable,
            str(RUNNER),
            "run",
            "--suite-root",
            str(suite),
            "--fc",
            self.fake_fc(),
            "--no-generated",
            "--json",
            "valid/concurrent.f90",
        ]
        first = subprocess.Popen(
            command,
            cwd=str(self.base),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        second = subprocess.Popen(
            command,
            cwd=str(self.base),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        first_stdout, first_stderr = first.communicate(timeout=20)
        second_stdout, second_stderr = second.communicate(timeout=20)
        self.assertEqual(first.returncode, 0, first_stderr)
        self.assertEqual(second.returncode, 0, second_stderr)
        first_payload = json.loads(first_stdout)
        second_payload = json.loads(second_stdout)
        self.assertNotEqual(
            first_payload["run_id"], second_payload["run_id"]
        )
        work_parent = suite / "tests" / ".runner-work"
        self.assertTrue(work_parent.is_dir())
        self.assertEqual(list(work_parent.iterdir()), [])


def shlex_quote(value: str) -> str:
    import shlex

    return shlex.quote(value)


if __name__ == "__main__":
    unittest.main(verbosity=2)
