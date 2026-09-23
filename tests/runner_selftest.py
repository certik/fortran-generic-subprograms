#!/usr/bin/env python3
"""Self-tests for runner mechanics; these do not validate Fortran GENERIC."""

import json
import os
import re
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
    KIND_INVENTORY_SOURCE,
    ProcessorInventory,
    error_stop_calibration_source,
    generated_kind_details,
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
NAMED_SYSTEM_CHARACTER 1
NAMED_DEFAULT_CHARACTER 1
COMPILER_VERSION selftest
FGS-PROCESSOR-INVENTORY-END
"""
        inventory = parse_kind_inventory(output)
        self.assertEqual(inventory.integer_kinds, [0, 4])
        self.assertEqual(inventory.named_kinds["int8"], 0)
        self.assertEqual(inventory.named_kinds["real16"], -1)
        self.assertEqual(inventory.named_kinds["default_character"], 1)
        source, counts = generate_kind_runtime_source(inventory)
        self.assertIn("integer(kind=0)", source)
        self.assertIn("real(kind=0)", source)
        self.assertIn("complex(kind=0)", source)
        self.assertIn("logical(kind=0)", source)
        self.assertIn("character(len=2, kind=0)", source)
        self.assertIn("huge(integer_1)", source)
        self.assertIn("nearest(real(1, kind=0)", source)
        self.assertIn("epsilon(real(1, kind=0))", source)
        self.assertIn("logical_1 = .false.", source)
        self.assertIn("char(1, kind=0)", source)
        self.assertIn("char(6, kind=0)", source)
        self.assertNotIn("char(0, kind=0)", source)
        self.assertNotIn("achar(", source.lower())
        self.assertIn("int(1, kind=0)", source)
        self.assertIn("int(0, kind=0)", source)
        self.assertIn("-shiftr(huge(integer_1), 1)", source)
        self.assertNotIn("int(2, kind=0)", source)
        self.assertNotIn("int(-2, kind=0)", source)
        self.assertEqual(counts["integer_kinds"], 2)
        self.assertEqual(counts["complex_kinds"], 2)
        self.assertEqual(counts["kind_specializations_exercised"], 10)
        self.assertEqual(
            counts["joint_type_kind_rank_save_specializations"], 30
        )
        self.assertEqual(counts["joint_type_kind_rank_save_calls"], 60)
        self.assertEqual(counts["joint_rank2_copy_specializations"], 10)
        self.assertEqual(counts["joint_rank2_elements_checked"], 60)
        self.assertEqual(counts["kind_identity_invocations"], 20)
        self.assertEqual(counts["kind_payload_assertions"], 20)
        self.assertEqual(counts["kind_distinct_identity_payloads"], 20)
        self.assertIn(
            "generic function state_type_kind_rank",
            source.lower(),
        )
        self.assertIn("generic function copy_type_kind_rank", source.lower())
        self.assertIn("intent(in), rank(2:2) :: x", source.lower())
        self.assertIn(
            "typeof(x) :: y(size(x, dim=1), size(x, dim=2))",
            source.lower(),
        )
        self.assertNotIn("typeof(x), rank(2) :: y", source.lower())
        self.assertNotIn("rank(copy_type_kind_rank", source.lower())
        self.assertIn(
            "state_type_kind_rank(character_2_rank2)",
            source,
        )
        self.assertIn(
            "copy_type_kind_rank(character_2_rank2)",
            source,
        )
        for family, count in (
            ("integer", 2),
            ("real", 2),
            ("complex", 2),
            ("logical", 2),
            ("character", 2),
        ):
            for index in range(1, count + 1):
                self.assertIn(
                    "copy_type_kind_rank({}_{}_rank2)".format(
                        family, index
                    ),
                    source,
                )
        self.assertEqual(
            counts["logical_truth_values_checked_per_kind"], 2
        )
        self.assertEqual(
            counts["character_payload_min_ordinal"], 1
        )
        self.assertEqual(
            counts["character_payload_max_ordinal"], 6
        )
        self.assertEqual(counts["character_nonzero_ordinal_kinds"], 2)
        self.assertEqual(counts["character_opaque_fallback_kinds"], 0)
        opaque_inventory = ProcessorInventory(
            integer_kinds=list(inventory.integer_kinds),
            real_kinds=list(inventory.real_kinds),
            logical_kinds=list(inventory.logical_kinds),
            character_kinds=[0, 1, 7],
            named_kinds=dict(inventory.named_kinds),
        )
        opaque_source, opaque_counts = generate_kind_runtime_source(
            opaque_inventory
        )
        self.assertIn(
            "character_3 = repeat(char(0, kind=7), 2)",
            opaque_source,
        )
        self.assertNotIn("char(1, kind=7)", opaque_source)
        self.assertEqual(
            opaque_counts["character_nonzero_ordinal_kinds"], 2
        )
        self.assertEqual(
            opaque_counts["character_opaque_fallback_kinds"], 1
        )
        self.assertEqual(opaque_counts["kind_identity_invocations"], 22)
        self.assertEqual(opaque_counts["kind_payload_assertions"], 22)
        self.assertEqual(
            opaque_counts["kind_distinct_identity_payloads"], 21
        )
        self.assertEqual(
            opaque_counts["character_identity_invocations"], 6
        )
        self.assertEqual(
            opaque_counts["character_distinct_identity_payloads"], 5
        )
        opaque_details = generated_kind_details(opaque_inventory)
        self.assertEqual(
            opaque_details["integer_rank2_payloads"],
            [
                "HUGE(x)",
                "-HUGE(x)",
                "1 converted to the selected kind",
                "-1 converted to the selected kind",
                "0 converted to the selected kind",
                "-SHIFTR(HUGE(x), 1)",
            ],
        )
        character_policy = opaque_details["character_payload_policy"]
        self.assertEqual(
            character_policy["nonzero_ordinal_kind_values"], [0, 1]
        )
        self.assertEqual(
            character_policy["opaque_fallback_kind_values"], [7]
        )
        self.assertEqual(
            character_policy["opaque_fallback_ordinals_tested"], [0]
        )
        self.assertFalse(
            character_policy["full_repertoire_or_width_claimed"]
        )
        self.assertEqual(character_policy["identity_invocations"], 6)
        self.assertEqual(character_policy["payload_assertions"], 6)
        self.assertEqual(character_policy["distinct_identity_payloads"], 5)
        self.assertEqual(
            opaque_details["identity_check_accounting"],
            {
                "identity_invocations": 22,
                "payload_assertions": 22,
                "distinct_payload_values": 21,
                "note": (
                    "opaque character kinds receive two identity/assertion "
                    "invocations of the same portable CHAR(0) payload"
                ),
            },
        )
        inventory.max_rank = 24
        inventory.max_rank_corank_1 = 24
        portable, portable_details = generate_rank_runtime_source(
            inventory, extended_rank=False
        )
        extended, extended_details = generate_rank_runtime_source(
            inventory, extended_rank=True
        )
        for generated_source in (source, portable, extended):
            self.assertLessEqual(
                max(len(line) for line in generated_source.splitlines()),
                132,
            )
            for declaration in generated_source.splitlines():
                lowered = declaration.lower()
                if (
                    "::" not in lowered
                    or re.search(r"\brank\s*\(", lowered) is None
                ):
                    continue
                self.assertTrue(
                    any(
                        attribute in lowered
                        for attribute in (
                            "intent(",
                            "allocatable",
                            "pointer",
                            "parameter",
                        )
                    ),
                    "C877-invalid generated declaration: {}".format(
                        declaration
                    ),
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
        self.assertIn("strided_16(1:4:2, &", extended)
        self.assertNotIn("signature", extended.lower())
        self.assertNotIn("100000", extended)
        self.assertIn("observed_calls", extended)
        self.assertIn(
            "reshape([1, -2, 3, -4, 5, -6, 7, -8, 9, -10, 11, -12]",
            extended,
        )
        rank_three = extended_details["rank_oracles"][3]
        self.assertEqual(rank_three["shape"], [2, 3, 2])
        self.assertEqual(
            rank_three["fortran_element_strides"], [1, 2, 6]
        )
        self.assertEqual(rank_three["weighted_linear_sum"], -78)
        rank_four = extended_details["rank_oracles"][4]
        self.assertEqual(rank_four["shape"], [2, 3, 1, 2])
        self.assertEqual(rank_four["active_axes"], [1, 2, 4])
        self.assertEqual(
            rank_four["layouts"][1]["name"],
            "dimension-1-stride-2-section",
        )
        self.assertEqual(
            rank_four["layouts"][1]["section_subscript_strides"],
            [2, 1, 1, 1],
        )
        self.assertEqual(extended_details["max_elements_per_actual"], 12)
        self.assertEqual(
            extended_details["max_nonsingleton_dimensions"], 3
        )
        self.assertEqual(
            extended_details["active_axes_exercised"],
            list(range(1, 25)),
        )
        self.assertEqual(
            extended_details["outermost_axes_activated"],
            list(range(1, 25)),
        )
        self.assertEqual(extended_details["strided_axes_exercised"], [1])
        self.assertEqual(extended_details["strided_runtime_calls"], 24)
        self.assertEqual(extended_details["contiguous_runtime_calls"], 26)
        self.assertFalse(
            extended_details["full_stride_axis_coverage_claimed"]
        )
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
        with self.assertRaisesRegex(
            ValueError, "requires MAX_RANK greater than 15"
        ):
            generate_rank_runtime_source(
                inventory, extended_rank=True
            )

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

    def test_native_kind_inventory_probe_is_setup_portable(self) -> None:
        source_text = KIND_INVENTORY_SOURCE.lower()
        self.assertNotIn("system_character,", source_text)
        self.assertIn("selected_char_kind('system')", source_text)
        self.assertIn(
            "integer, parameter :: fgs_character_kinds", source_text
        )
        source = self.base / "native_kind_inventory.f90"
        source.write_text(KIND_INVENTORY_SOURCE, encoding="utf-8")
        compilers = [
            compiler
            for compiler in (
                shutil.which("gfortran"),
                shutil.which("flang-new"),
            )
            if compiler is not None
        ]
        if not compilers:
            self.skipTest("gfortran and flang-new are unavailable")
        for index, compiler in enumerate(compilers):
            with self.subTest(compiler=compiler):
                executable = self.base / "native-kind-inventory-{}".format(
                    index
                )
                compiled = subprocess.run(
                    [compiler, str(source), "-o", str(executable)],
                    cwd=str(self.base),
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    check=False,
                    timeout=60,
                )
                self.assertEqual(compiled.returncode, 0, compiled.stderr)
                executed = subprocess.run(
                    [str(executable)],
                    cwd=str(self.base),
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    check=False,
                    timeout=20,
                )
                self.assertEqual(executed.returncode, 0, executed.stderr)
                inventory = parse_kind_inventory(executed.stdout)
                self.assertGreater(len(inventory.character_kinds), 0)
                self.assertIn(
                    inventory.named_kinds["default_character"],
                    inventory.character_kinds,
                )

    def test_error_stop_calibration_mirrors_flush_choice(self) -> None:
        with_flush = error_stop_calibration_source(" 'code'", True)
        without_flush = error_stop_calibration_source(" 'code'", False)
        self.assertIn(
            "flush (output_unit)",
            with_flush.lower().split("error stop", 1)[0],
        )
        self.assertNotIn(
            "flush (output_unit)",
            without_flush.lower().split("error stop", 1)[0],
        )
        self.assertIn(
            "flush (output_unit)",
            without_flush.lower().split("error stop", 1)[1],
        )
        selected = error_stop_calibration_source(
            " 'code'", True, stop_image=2
        )
        selected_lower = selected.lower()
        self.assertIn("integer, parameter :: fgs_stop_image = 2", selected_lower)
        self.assertLess(
            selected_lower.index("sync all"),
            selected_lower.index("if (this_image() == fgs_stop_image)"),
        )
        self.assertIn("sync all (stat=sync_status)", selected_lower)
        self.assertIn("stat_failed_image", selected_lower)
        self.assertIn("stat_stopped_image", selected_lower)
        self.assertIn(
            "sync_status == 0 .or. sync_status == stat_stopped_image .or.",
            selected_lower,
        )
        self.assertIn(
            "sync_status == stat_failed_image", selected_lower
        )
        self.assertEqual(
            selected.count("FGS-ERROR-STOP-CALIBRATION"), 1
        )
        self.assertEqual(
            selected.count("FGS-CALIBRATION-UNEXPECTED-RETURN"), 2
        )
        self.assertIn(
            "FGS-CALIBRATION-INCONCLUSIVE: coarray-sync-status",
            selected,
        )
        self.assertEqual(selected_lower.count("flush (output_unit)"), 4)

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
! TEST-PASS: path-with-spaces
PrOgRaM path_with_spaces
print '(a)', 'TEST-PASS: path-with-spaces'
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
            """! TEST-PASS: fixed-directory
PROGRAM FIXED_MAIN
PRINT '(a)', 'TEST-PASS: fixed-directory'
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
        self.assertTrue(payload["summary"]["profile_success"])
        self.assertTrue(payload["summary"]["coverage_complete"])
        self.assertEqual(payload["summary"]["counts"]["pass"], 2)

    def test_positive_completion_protocol_and_native_status_zero(self) -> None:
        suite = self.make_suite("positive completion")
        self.write(
            suite,
            "valid/missing_source_marker.f90",
            """! TEST-RULE: C3
! TEST-PASS: missing-source-marker
program missing_source_marker
end program
""",
        )
        self.write(
            suite,
            "valid/missing_runtime_marker.f90",
            """! TEST-RULE: C4
! TEST-PASS: missing-runtime-marker
program missing_runtime_marker
! FAKE-SUPPRESS-PASS:
print '(a)', 'TEST-PASS: missing-runtime-marker'
end program
""",
        )
        self.write(
            suite,
            "valid/unexpected_marker.f90",
            """! TEST-RULE: C5
! TEST-PASS: expected-marker
program unexpected_marker
! FAKE-RUN-OUTPUT: TEST-PASS: wrong-marker
print '(a)', 'TEST-PASS: expected-marker'
end program
""",
        )
        self.write(
            suite,
            "valid/images.f90",
            """! TEST-RULE: C6
! TEST-IMAGES: 2
! TEST-PASS: image-complete
program image_complete
print '(a)', 'TEST-PASS: image-complete'
end program
""",
        )

        missing_source, missing_source_payload = self.run_runner(
            suite, ["valid/missing_source_marker.f90"]
        )
        missing_source_result = self.case_result(
            missing_source_payload, "valid/missing_source_marker.f90"
        )
        self.assertEqual(missing_source.returncode, 1)
        self.assertEqual(missing_source_result["status"], "error")
        self.assertIn(
            "missing-pass-source-marker",
            {
                issue["code"]
                for issue in missing_source_result["details"]["issues"]
            },
        )

        missing_runtime, missing_runtime_payload = self.run_runner(
            suite, ["valid/missing_runtime_marker.f90"]
        )
        missing_runtime_result = self.case_result(
            missing_runtime_payload, "valid/missing_runtime_marker.f90"
        )
        self.assertEqual(missing_runtime.returncode, 1)
        self.assertEqual(
            missing_runtime_result["reason_code"],
            "missing-completion-marker",
        )
        self.assertEqual(
            missing_runtime_result["details"]["completion_protocol"],
            {
                "marker": "TEST-PASS: missing-runtime-marker",
                "expected_count": 1,
                "actual_count": 0,
                "unexpected_markers": [],
            },
        )

        unexpected, unexpected_payload = self.run_runner(
            suite, ["valid/unexpected_marker.f90"]
        )
        self.assertEqual(unexpected.returncode, 1)
        self.assertEqual(
            self.case_result(
                unexpected_payload, "valid/unexpected_marker.f90"
            )["reason_code"],
            "unexpected-completion-marker",
        )

        launcher = "{} {} --images {{images}} --exe {{exe}}".format(
            shlex_quote(sys.executable),
            shlex_quote(str(FAKE_LAUNCHER)),
        )
        short_launch, short_payload = self.run_runner(
            suite,
            ["valid/images.f90"],
            ["--launcher", launcher],
            env={"FAKE_LAUNCH_ONCE": "1"},
        )
        short_result = self.case_result(
            short_payload, "valid/images.f90"
        )
        self.assertEqual(short_launch.returncode, 1)
        self.assertEqual(
            short_result["reason_code"], "completion-marker-count"
        )
        self.assertEqual(
            short_result["details"]["completion_protocol"]["actual_count"],
            1,
        )

        compiler = shutil.which("gfortran")
        if compiler is None:
            return
        native_suite = self.make_suite("native status zero assertion")
        self.write(
            native_suite,
            "valid/error_stop_zero.f90",
            """! TEST-RULE: 11.4
! TEST-PASS: native-status-zero
program native_status_zero
  error stop 0, quiet=.true.
  print '(a)', 'TEST-PASS: native-status-zero'
end program
""",
        )
        native, native_payload = self.run_runner(
            native_suite,
            ["valid/error_stop_zero.f90"],
            fc=compiler,
        )
        native_result = self.case_result(
            native_payload, "valid/error_stop_zero.f90"
        )
        self.assertEqual(native.returncode, 1, native.stderr)
        self.assertEqual(
            native_result["reason_code"], "missing-completion-marker"
        )
        self.assertEqual(
            native_result["details"]["runtime"]["outcome"],
            {"kind": "exit", "status": 0},
        )

    def test_pass_marker_requires_main_execution_context(self) -> None:
        suite = self.make_suite("pass marker scope")
        helper_case = "valid/internal_helper_marker.f90"
        helper_source = """! TEST-RULE: 11.4
! TEST-PASS: internal-helper-marker
program internal_helper_marker
  call helper()
  error stop 0, quiet=.true.
contains
  subroutine helper()
    print '(a)', 'TEST-PASS: internal-helper-marker'
  end subroutine
end program
"""
        helper_path = self.write(suite, helper_case, helper_source)
        template_helper_case = "valid/template_helper_marker.f90"
        self.write(
            suite,
            template_helper_case,
            """! TEST-RULE: R1601 R1602 R1608
! TEST-DRAFT: template-integration
! TEST-PASS: template-helper-marker
program template_helper_marker
  implicit none
  template helper_template()
    public :: helper
  contains
    generic subroutine helper()
      print '(a)', 'TEST-PASS: template-helper-marker'
    end subroutine
  end template
  instantiate helper_template {}
  call helper()
end program
""",
        )
        valid_template_case = "valid/template_main_marker.f90"
        self.write(
            suite,
            valid_template_case,
            """! TEST-RULE: R1601 R1602 R1608
! TEST-DRAFT: template-integration
! TEST-PASS: template-main-marker
program template_main_marker
  implicit none
  template identity_template()
    public :: identity
  contains
    generic function identity(x) result(y)
      integer, intent(in) :: x
      integer :: y
      y = x
    end function
  end template
  instantiate identity_template {}
  if (identity(7) /= 7) error stop 'template identity'
  print '(a)', 'TEST-PASS: template-main-marker'
end program
""",
        )

        rejected, rejected_payload = self.run_runner(
            suite, [helper_case]
        )
        rejected_result = self.case_result(rejected_payload, helper_case)
        self.assertEqual(rejected.returncode, 1)
        self.assertEqual(rejected_result["status"], "error")
        self.assertFalse(rejected_result["executed"])
        self.assertIn(
            "missing-pass-source-marker",
            {
                issue["code"]
                for issue in rejected_result["details"]["issues"]
            },
        )

        template_rejected, template_rejected_payload = self.run_runner(
            suite,
            [template_helper_case],
            ["--draft", "template-integration"],
        )
        template_rejected_result = self.case_result(
            template_rejected_payload, template_helper_case
        )
        self.assertEqual(template_rejected.returncode, 2)
        self.assertIn(
            "missing-pass-source-marker",
            {
                issue["code"]
                for issue in template_rejected_result["details"]["issues"]
            },
        )

        template_valid, template_valid_payload = self.run_runner(
            suite,
            [valid_template_case],
            ["--draft", "template-integration"],
        )
        self.assertEqual(template_valid.returncode, 0, template_valid.stderr)
        self.assertEqual(
            self.case_result(
                template_valid_payload, valid_template_case
            )["status"],
            "pass",
        )

        compiler = shutil.which("gfortran")
        if compiler is not None:
            executable = self.base / "internal-helper-marker.exe"
            compiled = subprocess.run(
                [compiler, str(helper_path), "-o", str(executable)],
                cwd=str(self.base),
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
                timeout=30,
            )
            self.assertEqual(compiled.returncode, 0, compiled.stderr)
            native = subprocess.run(
                [str(executable)],
                cwd=str(self.base),
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
                timeout=10,
            )
            self.assertEqual(native.returncode, 0, native.stderr)
            self.assertEqual(
                native.stdout.splitlines(),
                ["TEST-PASS: internal-helper-marker"],
            )

    def test_metadata_list_and_check_need_no_compiler(self) -> None:
        suite = self.make_suite("metadata")
        self.write(
            suite,
            "valid/ordinary.f90",
            """! TEST-RULE: C10 15.6.2.4
! TEST-PASS: ordinary
program ordinary
print '(a)', 'TEST-PASS: ordinary'
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
            self.assertEqual(
                [
                    generated["id"]
                    for generated in payload["generated_cases"]
                ],
                [
                    "@generated/processor-kinds",
                    "@generated/processor-rank",
                    "@generated/processor-rank-extended",
                ],
            )

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
        self.assertTrue(payload["summary"]["profile_success"])
        self.assertTrue(payload["summary"]["coverage_complete"])
        kind_source = output / "processor_kinds_generated.f90"
        rank_source = output / "processor_rank_generated.f90"
        manifest = json.loads(
            (output / "manifest.json").read_text(encoding="utf-8")
        )
        self.assertEqual(manifest["schema_version"], 2)
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
            30,
        )
        kind_details = manifest["generated_cases"]["processor_kinds"][
            "details"
        ]
        self.assertIn("HUGE", kind_details["numeric_kind_tag_policy"])
        self.assertEqual(
            kind_details["character_payload_policy"][
                "nonzero_ordinal_kind_values"
            ],
            [0, 1],
        )
        self.assertEqual(
            kind_details["character_payload_policy"][
                "opaque_fallback_kind_values"
            ],
            [],
        )
        self.assertFalse(
            kind_details["character_payload_policy"][
                "full_repertoire_or_width_claimed"
            ]
        )
        self.assertEqual(
            kind_details["identity_check_accounting"],
            {
                "identity_invocations": 20,
                "payload_assertions": 20,
                "distinct_payload_values": 20,
                "note": (
                    "opaque character kinds receive two identity/assertion "
                    "invocations of the same portable CHAR(0) payload"
                ),
            },
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
        portable_extended_details = extended_manifest["generated_cases"][
            "processor_rank"
        ]["details"]
        extended_case_manifest = extended_manifest["generated_cases"][
            "processor_rank_extended"
        ]
        extended_details = extended_case_manifest["details"]
        self.assertEqual(
            portable_extended_details["called_ranks"], list(range(16))
        )
        self.assertEqual(extended_details["called_ranks"], list(range(19)))
        self.assertEqual(extended_details["generic_runtime_calls"], 38)
        self.assertEqual(extended_case_manifest["status"], "generated")
        self.assertTrue(extended_case_manifest["selected"])
        self.assertTrue(extended_case_manifest["available"])
        portable_extended_text = (
            extended_output / "processor_rank_generated.f90"
        ).read_text(encoding="utf-8")
        extended_rank_path = (
            extended_output / "processor_rank_extended_generated.f90"
        )
        extended_rank_text = extended_rank_path.read_text(encoding="utf-8")
        self.assertNotIn("value_16", portable_extended_text)
        for rank in (16, 17, 18):
            self.assertIn(
                "call probe_rank(value_{},".format(rank),
                extended_rank_text,
            )
        portable_result = self.case_result(
            extended_payload, "@generated/processor-rank"
        )
        extended_result = self.case_result(
            extended_payload, "@generated/processor-rank-extended"
        )
        self.assertTrue(portable_result["gating"])
        self.assertFalse(extended_result["gating"])
        self.assertEqual(
            extended_result["details"]["runtime"]["stdout"].splitlines(),
            extended_details["expected_output_lines"],
        )

        literal_output = self.base / "generated literal artifacts"
        literal_completed = subprocess.run(
            [
                sys.executable,
                str(RUNNER),
                "generate",
                "--suite-root",
                str(suite),
                "--fc",
                self.fake_fc(),
                "--output",
                str(literal_output),
                "--draft",
                "literal-rank-limit",
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
        literal_payload = json.loads(literal_completed.stdout)
        literal_manifest = json.loads(
            (literal_output / "manifest.json").read_text(encoding="utf-8")
        )
        literal_details = literal_manifest["generated_cases"][
            "processor_rank"
        ]["details"]
        literal_result = self.case_result(
            literal_payload, "@generated/processor-rank"
        )
        self.assertEqual(literal_completed.returncode, 0)
        self.assertEqual(literal_details["called_ranks"], list(range(16)))
        self.assertIsNone(literal_details["draft_interpretation"])
        self.assertTrue(literal_result["gating"])
        literal_extended = literal_manifest["generated_cases"][
            "processor_rank_extended"
        ]
        self.assertFalse(literal_extended["selected"])
        self.assertEqual(literal_extended["status"], "not-selected")
        self.assertFalse(
            (
                literal_output
                / "processor_rank_extended_generated.f90"
            ).exists()
        )

        unavailable_output = self.base / "generated unavailable extended"
        unavailable_completed = subprocess.run(
            [
                sys.executable,
                str(RUNNER),
                "generate",
                "--suite-root",
                str(suite),
                "--fc",
                self.fake_fc(),
                "--output",
                str(unavailable_output),
                "--draft",
                "extended-rank-limit",
                "--json",
            ],
            cwd=str(self.base),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=20,
        )
        unavailable_payload = json.loads(unavailable_completed.stdout)
        unavailable_result = self.case_result(
            unavailable_payload, "@generated/processor-rank-extended"
        )
        self.assertEqual(unavailable_completed.returncode, 0)
        self.assertEqual(unavailable_result["status"], "skip")
        self.assertEqual(
            unavailable_result["reason_code"],
            "extended-rank-unavailable",
        )
        self.assertTrue(
            self.case_result(
                unavailable_payload, "@generated/processor-rank"
            )["gating"]
        )
        self.assertTrue(unavailable_payload["summary"]["profile_success"])
        self.assertFalse(
            unavailable_payload["summary"]["coverage_complete"]
        )
        unavailable_manifest = json.loads(
            (unavailable_output / "manifest.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(
            unavailable_manifest["generated_cases"][
                "processor_rank_extended"
            ]["status"],
            "unavailable",
        )

        cleanup_completed = subprocess.run(
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
                "--force",
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
        self.assertEqual(cleanup_completed.returncode, 0)
        self.assertFalse(extended_rank_path.exists())
        cleanup_manifest = json.loads(
            (extended_output / "manifest.json").read_text(encoding="utf-8")
        )
        self.assertEqual(
            cleanup_manifest["generated_cases"][
                "processor_rank_extended"
            ]["status"],
            "not-selected",
        )

    def test_run_keeps_portable_rank_case_independently_gating(self) -> None:
        suite = self.make_suite("generated rank run profiles")

        def run_generated(
            drafts: Sequence[str],
            *,
            max_rank: int,
            gate: bool = False,
        ) -> Tuple[subprocess.CompletedProcess[str], Dict[str, Any]]:
            command = [
                sys.executable,
                str(RUNNER),
                "run",
                "--suite-root",
                str(suite),
                "--fc",
                self.fake_fc(),
                "--json",
            ]
            for draft in drafts:
                command.extend(["--draft", draft])
            if gate:
                command.append("--gate-drafts")
            environment = os.environ.copy()
            environment["FAKE_MAX_RANK"] = str(max_rank)
            completed = subprocess.run(
                command,
                cwd=str(self.base),
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
                timeout=30,
            )
            return completed, json.loads(completed.stdout)

        observed, observed_payload = run_generated(
            ["extended-rank-limit"], max_rank=18
        )
        portable = self.case_result(
            observed_payload, "@generated/processor-rank"
        )
        extended = self.case_result(
            observed_payload, "@generated/processor-rank-extended"
        )
        self.assertEqual(observed.returncode, 0, observed.stderr)
        self.assertTrue(portable["gating"])
        self.assertEqual(
            portable["details"]["rank"]["called_ranks"], list(range(16))
        )
        self.assertFalse(extended["gating"])
        self.assertEqual(
            extended["details"]["rank"]["called_ranks"], list(range(19))
        )

        gated, gated_payload = run_generated(
            ["extended-rank-limit"], max_rank=18, gate=True
        )
        self.assertEqual(gated.returncode, 0, gated.stderr)
        self.assertTrue(
            self.case_result(
                gated_payload, "@generated/processor-rank"
            )["gating"]
        )
        self.assertTrue(
            self.case_result(
                gated_payload, "@generated/processor-rank-extended"
            )["gating"]
        )

        literal, literal_payload = run_generated(
            ["literal-rank-limit"], max_rank=18
        )
        self.assertEqual(literal.returncode, 0, literal.stderr)
        self.assertTrue(
            self.case_result(
                literal_payload, "@generated/processor-rank"
            )["gating"]
        )
        self.assertFalse(
            any(
                result["id"] == "@generated/processor-rank-extended"
                for result in literal_payload["results"]
            )
        )

        unavailable, unavailable_payload = run_generated(
            ["extended-rank-limit"], max_rank=15
        )
        unavailable_extended = self.case_result(
            unavailable_payload, "@generated/processor-rank-extended"
        )
        self.assertEqual(unavailable.returncode, 0, unavailable.stderr)
        self.assertEqual(unavailable_extended["status"], "skip")
        self.assertTrue(
            self.case_result(
                unavailable_payload, "@generated/processor-rank"
            )["gating"]
        )

    def test_native_ordinary_matrix_copy_residuals(self) -> None:
        compiler = shutil.which("gfortran")
        if compiler is None:
            self.skipTest("gfortran is unavailable")
        suite = self.make_suite("ordinary matrix copy residuals")
        self.write(
            suite,
            "valid/matrix_copy_residuals.f90",
            """! TEST-RULE: C877-RESIDUAL
! TEST-PASS: matrix-copy-residuals
module matrix_copy_residuals_m
  use, intrinsic :: iso_fortran_env, only: int64, real64
  implicit none
contains
  function copy_integer(x) result(y)
    integer(int64), intent(in) :: x(:, :)
    integer(int64) :: y(size(x, dim=1), size(x, dim=2))
    y = x
  end function

  function copy_integer_rank4(x) result(y)
    integer(int64), intent(in) :: x(:, :, :, :)
    integer(int64) :: y(size(x, dim=1), size(x, dim=2), &
      size(x, dim=3), size(x, dim=4))
    y = x
  end function

  function copy_real(x) result(y)
    real(real64), intent(in) :: x(:, :)
    real(real64) :: y(size(x, dim=1), size(x, dim=2))
    y = x
  end function

  function copy_complex(x) result(y)
    complex(real64), intent(in) :: x(:, :)
    complex(real64) :: y(size(x, dim=1), size(x, dim=2))
    y = x
  end function

  function copy_logical(x) result(y)
    logical, intent(in) :: x(:, :)
    logical :: y(size(x, dim=1), size(x, dim=2))
    y = x
  end function

  function copy_character(x) result(y)
    character(len=*), intent(in) :: x(:, :)
    character(len=len(x(1, 1))) :: &
      y(size(x, dim=1), size(x, dim=2))
    y = x
  end function
end module

program matrix_copy_residuals
  use, intrinsic :: iso_fortran_env, only: int64, real64
  use matrix_copy_residuals_m
  implicit none
  integer(int64) :: iv(2, 3), ic(2, 3)
  integer(int64) :: ib(4, 3)
  integer(int64) :: i4(2, 3, 1, 2), i4b(4, 3, 1, 2)
  integer(int64) :: i4c(2, 3, 1, 2)
  real(real64) :: rv(2, 3), rc(2, 3)
  real(real64) :: rb(4, 3)
  complex(real64) :: zv(2, 3), zc(2, 3)
  complex(real64) :: zb(4, 3)
  logical :: lv(2, 3), lc(2, 3)
  logical :: lb(4, 3)
  character(len=2) :: cv(2, 3), cc(2, 3)
  character(len=2) :: cb(4, 3)

  iv = reshape([huge(0_int64), -huge(0_int64), 1_int64, &
                -1_int64, 2_int64, -2_int64], [2, 3])
  rv = reshape([nearest(1.0_real64, 1.0_real64), &
                -nearest(1.0_real64, 1.0_real64), &
                epsilon(1.0_real64), -epsilon(1.0_real64), &
                3.0_real64 / 7.0_real64, &
                -3.0_real64 / 7.0_real64], [2, 3])
  zv = reshape([cmplx(rv(1, 1), rv(2, 1), kind=real64), &
                cmplx(rv(1, 2), rv(2, 2), kind=real64), &
                cmplx(rv(1, 3), rv(2, 3), kind=real64), &
                cmplx(-rv(1, 1), rv(2, 1), kind=real64), &
                cmplx(rv(1, 2), -rv(2, 2), kind=real64), &
                cmplx(-rv(1, 3), -rv(2, 3), kind=real64)], [2, 3])
  lv = reshape([.true., .false., .false., .true., .true., .false.], &
               [2, 3])
  cv = reshape(['a1', 'b2', 'c3', 'd4', 'e5', 'f6'], [2, 3])
  i4 = reshape([1_int64, -2_int64, 3_int64, -4_int64, 5_int64, &
                -6_int64, 7_int64, -8_int64, 9_int64, -10_int64, &
                11_int64, -12_int64], [2, 3, 1, 2])

  ic = copy_integer(iv)
  rc = copy_real(rv)
  zc = copy_complex(zv)
  lc = copy_logical(lv)
  cc = copy_character(cv)
  if (any(ic /= iv)) error stop 'contiguous integer matrix payload'
  if (any(rc /= rv)) error stop 'contiguous real matrix payload'
  if (any(zc /= zv)) error stop 'contiguous complex matrix payload'
  if (any(lc .neqv. lv)) error stop 'contiguous logical matrix payload'
  if (any(cc /= cv)) error stop 'contiguous character matrix payload'

  ib = 99_int64
  rb = 99.0_real64
  zb = cmplx(99.0_real64, -99.0_real64, kind=real64)
  lb = .false.
  cb = 'zz'
  i4b = 99_int64
  ib(1:4:2, :) = iv
  rb(1:4:2, :) = rv
  zb(1:4:2, :) = zv
  lb(1:4:2, :) = lv
  cb(1:4:2, :) = cv
  i4b(1:4:2, :, :, :) = i4
  if (is_contiguous(ib(1:4:2, :))) error stop 'integer section contiguous'
  if (is_contiguous(cb(1:4:2, :))) error stop 'character section contiguous'

  ic = copy_integer(ib(1:4:2, :))
  rc = copy_real(rb(1:4:2, :))
  zc = copy_complex(zb(1:4:2, :))
  lc = copy_logical(lb(1:4:2, :))
  cc = copy_character(cb(1:4:2, :))
  i4c = copy_integer_rank4(i4b(1:4:2, :, :, :))

  if (any(ic /= iv)) error stop 'integer matrix payload'
  if (kind(ic) /= int64) error stop 'integer matrix kind'
  if (rank(ic) /= 2) error stop 'integer matrix rank'
  if (any(shape(ic) /= [2, 3])) error stop 'integer matrix shape'
  if (any(rc /= rv)) error stop 'real matrix payload'
  if (kind(rc) /= real64) error stop 'real matrix kind'
  if (rank(rc) /= 2) error stop 'real matrix rank'
  if (any(shape(rc) /= [2, 3])) error stop 'real matrix shape'
  if (any(zc /= zv)) error stop 'complex matrix payload'
  if (kind(zc) /= real64) error stop 'complex matrix kind'
  if (rank(zc) /= 2) error stop 'complex matrix rank'
  if (any(shape(zc) /= [2, 3])) error stop 'complex matrix shape'
  if (any(lc .neqv. lv)) error stop 'logical matrix payload'
  if (rank(lc) /= 2) error stop 'logical matrix rank'
  if (any(shape(lc) /= [2, 3])) error stop 'logical matrix shape'
  if (any(cc /= cv)) error stop 'character matrix payload'
  if (len(cc(1, 1)) /= 2) error stop 'character matrix length'
  if (kind(cc) /= kind('a')) error stop 'character matrix kind'
  if (rank(cc) /= 2) error stop 'character matrix rank'
  if (any(shape(cc) /= [2, 3])) error stop 'character matrix shape'
  if (any(i4c /= i4)) error stop 'rank-four matrix payload'
  if (rank(i4c) /= 4) error stop 'rank-four matrix rank'
  if (any(shape(i4c) /= [2, 3, 1, 2])) &
    error stop 'rank-four matrix shape'
  print '(a)', 'TEST-PASS: matrix-copy-residuals'
end program
""",
        )
        completed, payload = self.run_runner(
            suite,
            ["valid/matrix_copy_residuals.f90"],
            fc=compiler,
        )
        result = self.case_result(
            payload, "valid/matrix_copy_residuals.f90"
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(result["status"], "pass")
        self.assertEqual(
            result["details"]["completion_protocol"]["actual_count"], 1
        )

    def test_invalid_max_rank_inventory_never_generates_smaller_case(self) -> None:
        suite = self.make_suite("invalid max rank inventory")
        scenarios = {
            "rank14": {
                "FAKE_MAX_RANK": "14",
                "expected": "below the required minimum 15",
            },
            "corank13": {
                "FAKE_MAX_RANK": "15",
                "FAKE_MAX_RANK_CORANK_1": "13",
                "expected": "below the required minimum 14",
            },
            "unsupported": {
                "FAKE_REJECT_MAX_RANK": "1",
                "expected": "did not compile",
            },
        }
        for name, scenario in scenarios.items():
            with self.subTest(command="run", scenario=name):
                environment = os.environ.copy()
                environment.update(
                    {
                        key: value
                        for key, value in scenario.items()
                        if key.startswith("FAKE_")
                    }
                )
                completed = subprocess.run(
                    [
                        sys.executable,
                        str(RUNNER),
                        "run",
                        "--suite-root",
                        str(suite),
                        "--fc",
                        self.fake_fc(),
                        "--json",
                    ],
                    cwd=str(self.base),
                    env=environment,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    check=False,
                    timeout=20,
                )
                payload = json.loads(completed.stdout)
                rank_result = self.case_result(
                    payload, "@generated/processor-rank"
                )
                self.assertEqual(completed.returncode, 1)
                self.assertEqual(
                    rank_result["reason_code"],
                    "invalid-max-rank-inventory",
                )
                self.assertIn(scenario["expected"], rank_result["message"])
                self.assertFalse(payload["summary"]["profile_success"])

            with self.subTest(command="generate", scenario=name):
                output = self.base / "invalid-rank-{}".format(name)
                environment = os.environ.copy()
                environment.update(
                    {
                        key: value
                        for key, value in scenario.items()
                        if key.startswith("FAKE_")
                    }
                )
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
                    env=environment,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    check=False,
                    timeout=20,
                )
                payload = json.loads(completed.stdout)
                self.assertEqual(completed.returncode, 2)
                self.assertIn(scenario["expected"], payload["fatal_error"])
                self.assertFalse(
                    (output / "processor_rank_generated.f90").exists()
                )

        inventory_output = """FGS-PROCESSOR-INVENTORY-V1
INTEGER_KIND 4
REAL_KIND 4
LOGICAL_KIND 4
CHARACTER_KIND 1
NAMED_INT8 -1
NAMED_INT16 -1
NAMED_INT32 4
NAMED_INT64 -1
NAMED_REAL16 -1
NAMED_REAL32 4
NAMED_REAL64 -1
NAMED_REAL128 -1
NAMED_ASCII 1
NAMED_ISO_10646 -1
NAMED_SYSTEM_CHARACTER 1
NAMED_DEFAULT_CHARACTER 1
COMPILER_VERSION direct invalid inventory
FGS-PROCESSOR-INVENTORY-END
"""
        direct_inventory = parse_kind_inventory(inventory_output)
        direct_inventory.max_rank = 14
        direct_inventory.max_rank_corank_1 = 14
        with self.assertRaisesRegex(ValueError, "required minimum 15"):
            generate_rank_runtime_source(
                direct_inventory, extended_rank=False
            )
        direct_inventory.max_rank = 15
        direct_inventory.max_rank_corank_1 = 13
        with self.assertRaisesRegex(ValueError, "required minimum 14"):
            generate_rank_runtime_source(
                direct_inventory, extended_rank=False
            )
        direct_inventory.max_rank_corank_1 = 14
        direct_inventory.max_rank_error = "MAX_RANK unsupported"
        with self.assertRaisesRegex(ValueError, "inventory is invalid"):
            generate_rank_runtime_source(
                direct_inventory, extended_rank=False
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

    def test_diagnostic_only_compile_can_omit_object_but_link_cannot(self) -> None:
        suite = self.make_suite("diagnostic only artifacts")
        right_case = "invalid_compile_time/right_no_object.f90"
        wrong_case = "invalid_compile_time/wrong_no_object.f90"
        self.write(
            suite,
            right_case,
            """! TEST-RULE: C21A
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: intended diagnostic-only constraint
module right_no_object_m
! TEST-ERROR-HERE
  integer :: offending
! FAKE-DIAGNOSTIC: HERE|Warning|intended diagnostic-only constraint
! FAKE-NO-OBJECT:
end module
""",
        )
        self.write(
            suite,
            wrong_case,
            """! TEST-RULE: C21B
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: intended diagnostic-only constraint
module wrong_no_object_m
! TEST-ERROR-HERE
  integer :: offending
! FAKE-DIAGNOSTIC: HERE|Warning|unrelated diagnostic
! FAKE-NO-OBJECT:
end module
""",
        )
        link_directory = (
            suite / "tests" / "invalid_compile_time" / "link_no_object"
        )
        link_directory.mkdir()
        (link_directory / "a_helper.f90").write_text(
            """module link_no_object_m
! FAKE-NO-OBJECT:
end module
""",
            encoding="utf-8",
        )
        (link_directory / "b_main.f90").write_text(
            """! TEST-RULE: C21C
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: intended_link_symbol
! TEST-ERROR-PHASE: link
program link_no_object
! TEST-ERROR-HERE
  call intended_link_symbol()
! FAKE-LINK-DIAGNOSTIC: undefined reference to intended_link_symbol
! FAKE-LINK-EXIT: 1
end program
""",
            encoding="utf-8",
        )

        conformance, conformance_payload = self.run_runner(
            suite, [right_case]
        )
        conformance_result = self.case_result(
            conformance_payload, right_case
        )
        self.assertEqual(conformance.returncode, 0)
        self.assertEqual(conformance_result["status"], "pass")
        self.assertEqual(
            conformance_result["details"]["compiler"][0]["outcome"],
            {"kind": "exit", "status": 0},
        )

        strict, strict_payload = self.run_runner(
            suite, [right_case], ["--strict"]
        )
        strict_result = self.case_result(strict_payload, right_case)
        self.assertEqual(strict.returncode, 1)
        self.assertEqual(
            strict_result["reason_code"], "strict-rejection-required"
        )

        unrelated, unrelated_payload = self.run_runner(
            suite, [wrong_case]
        )
        unrelated_result = self.case_result(
            unrelated_payload, wrong_case
        )
        self.assertEqual(unrelated.returncode, 1)
        self.assertEqual(
            unrelated_result["reason_code"],
            "intended-diagnostic-not-found",
        )

        link_run, link_payload = self.run_runner(
            suite, ["invalid_compile_time/link_no_object"]
        )
        link_result = self.case_result(
            link_payload, "invalid_compile_time/link_no_object"
        )
        self.assertEqual(link_run.returncode, 1)
        self.assertEqual(link_result["status"], "error")
        self.assertEqual(
            link_result["reason_code"], "compiler-infrastructure"
        )
        self.assertIn("expected artifact was not produced", link_result["message"])
        self.assertNotIn("link", link_result["details"])

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
! TEST-PASS: slow
program slow
! FAKE-COMPILE-SLEEP: 1
print '(a)', 'TEST-PASS: slow'
end
""",
        )
        self.write(
            suite,
            "valid/slow_runtime.f90",
            """! TEST-RULE: C30
! TEST-PASS: slow-runtime
program slow_runtime
! FAKE-RUN-SLEEP: 1
print '(a)', 'TEST-PASS: slow-runtime'
end
""",
        )
        self.write(
            suite,
            "valid/compiler_127.f90",
            """! TEST-RULE: C30
! TEST-PASS: compiler-127
program compiler_127
! FAKE-COMPILE-EXIT: 127
print '(a)', 'TEST-PASS: compiler-127'
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

    def test_c_companions_are_lazy_compiled_and_linked_by_fortran(self) -> None:
        suite = self.make_suite("c companion policies")

        def write_mixed_case(name: str, c_directives: str = "") -> str:
            case_id = "valid/{}".format(name)
            directory = suite / "tests" / case_id
            directory.mkdir()
            marker = "{}-pass".format(name)
            (directory / "a_main.f90").write_text(
                """! TEST-RULE: C-BIND-{name}
! TEST-PASS: {marker}
program {name}
print '(a)', 'TEST-PASS: {marker}'
end program
""".format(
                    name=name.replace("-", "_"),
                    marker=marker,
                ),
                encoding="utf-8",
            )
            (directory / "b_helper.c").write_text(
                """// TEST-RULE: THIS-C-METADATA-MUST-BE-IGNORED
// program this_is_not_a_fortran_main
int helper(void) {{ return 42; }}
{directives}
""".format(
                    directives=c_directives
                ),
                encoding="utf-8",
            )
            return case_id

        mixed_id = write_mixed_case("mixed")
        compile_failure_id = write_mixed_case(
            "c-compile-failure", "// FAKE-COMPILE-EXIT: 3"
        )
        link_failure_id = write_mixed_case(
            "c-link-failure", "// FAKE-LINK-EXIT: 4"
        )
        self.write(
            suite,
            "valid/ordinary_only.f90",
            """! TEST-RULE: C-ONLY-FORTRAN
! TEST-PASS: ordinary-only
program ordinary_only
print '(a)', 'TEST-PASS: ordinary-only'
end program
""",
        )

        mixed, mixed_payload = self.run_runner(
            suite,
            [mixed_id],
            [
                "--cc",
                self.fake_fc(),
                "--cflags=-DSELFTEST_CFLAG=1",
            ],
        )
        mixed_result = self.case_result(mixed_payload, mixed_id)
        self.assertEqual(mixed.returncode, 0, mixed.stderr)
        self.assertEqual(mixed_result["status"], "pass")
        compile_commands = [
            process["command"]
            for process in mixed_result["details"]["compiler"]
        ]
        self.assertEqual(len(compile_commands), 2)
        self.assertTrue(
            any(
                any(argument.endswith("b_helper.c") for argument in command)
                for command in compile_commands
            )
        )
        self.assertTrue(
            any(
                "-DSELFTEST_CFLAG=1" in command
                for command in compile_commands
            )
        )
        link_command = mixed_result["details"]["link"]["command"]
        self.assertEqual(
            sum(argument.endswith(".o") for argument in link_command), 2
        )
        listed = subprocess.run(
            [
                sys.executable,
                str(RUNNER),
                "list",
                "--suite-root",
                str(suite),
                "--json",
                mixed_id,
            ],
            cwd=str(self.base),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=10,
        )
        listed_payload = json.loads(listed.stdout)
        listed_case = listed_payload["cases"][0]
        self.assertEqual(listed_case["metadata"]["rules"], ["C-BIND-mixed"])
        self.assertEqual(len(listed_case["fortran_sources"]), 1)
        self.assertEqual(len(listed_case["c_sources"]), 1)
        self.assertTrue(listed_case["has_program"])

        missing_cc, missing_cc_payload = self.run_runner(
            suite,
            [mixed_id],
            ["--cc", "./configured-c-compiler-is-missing"],
        )
        missing_cc_result = self.case_result(missing_cc_payload, mixed_id)
        self.assertEqual(missing_cc.returncode, 1)
        self.assertEqual(missing_cc_result["status"], "error")
        self.assertEqual(
            missing_cc_result["reason_code"], "compiler-infrastructure"
        )
        self.assertIn("C compiler unavailable", missing_cc_result["message"])
        self.assertFalse(
            missing_cc_payload["summary"]["coverage_complete"]
        )

        ordinary, ordinary_payload = self.run_runner(
            suite,
            ["valid/ordinary_only.f90"],
            ["--cc", "./configured-c-compiler-is-missing"],
        )
        self.assertEqual(ordinary.returncode, 0, ordinary.stderr)
        self.assertEqual(
            self.case_result(
                ordinary_payload, "valid/ordinary_only.f90"
            )["status"],
            "pass",
        )

        compile_failure, compile_failure_payload = self.run_runner(
            suite,
            [compile_failure_id],
            ["--cc", self.fake_fc()],
        )
        self.assertEqual(compile_failure.returncode, 1)
        self.assertEqual(
            self.case_result(
                compile_failure_payload, compile_failure_id
            )["reason_code"],
            "test-compile-failure",
        )

        link_failure, link_failure_payload = self.run_runner(
            suite,
            [link_failure_id],
            ["--cc", self.fake_fc()],
        )
        self.assertEqual(link_failure.returncode, 1)
        self.assertEqual(
            self.case_result(
                link_failure_payload, link_failure_id
            )["reason_code"],
            "test-link-failure",
        )

    def test_native_mixed_c_fortran_callback_control(self) -> None:
        compiler = shutil.which("gfortran")
        c_compiler = shutil.which("cc")
        if compiler is None or c_compiler is None:
            self.skipTest("native Fortran and C compilers are required")
        suite = self.make_suite("native c callback")
        directory = suite / "tests" / "valid" / "native_callback"
        directory.mkdir()
        (directory / "callback.f90").write_text(
            """! TEST-RULE: C-BIND-NATIVE
! TEST-PASS: native-c-callback
module native_callback_m
  use, intrinsic :: iso_c_binding, only: c_int
  implicit none
contains
  integer(c_int) function fgs_value() bind(c, name='fgs_value')
    fgs_value = 42_c_int
  end function
end module

program native_callback
  use, intrinsic :: iso_c_binding, only: c_int
  implicit none
  interface
    integer(c_int) function call_fgs() bind(c, name='call_fgs')
      import c_int
    end function
  end interface
  if (call_fgs() /= 42_c_int) error stop 'C callback mismatch'
  print '(a)', 'TEST-PASS: native-c-callback'
end program
""",
            encoding="utf-8",
        )
        (directory / "companion.c").write_text(
            """extern int fgs_value(void);
int call_fgs(void) {
    return fgs_value();
}
""",
            encoding="utf-8",
        )
        completed, payload = self.run_runner(
            suite,
            ["valid/native_callback"],
            ["--cc", c_compiler],
            fc=compiler,
        )
        result = self.case_result(
            payload, "valid/native_callback"
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(result["status"], "pass")
        self.assertEqual(
            result["details"]["completion_protocol"]["actual_count"], 1
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
! TEST-PASS: zero-kind
program zero_kind
print '(a)', 'TEST-PASS: zero-kind'
end
""",
        )
        self.write(
            suite,
            "valid/unavailable_kind.f90",
            """! TEST-RULE: C51
! TEST-REQUIRES: real16
! TEST-PASS: unavailable-kind
program unavailable
print '(a)', 'TEST-PASS: unavailable-kind'
end
""",
        )
        self.write(
            suite,
            "valid/draft.f90",
            """! TEST-RULE: C52
! TEST-DRAFT: empty-expansion
! TEST-PASS: draft-case
program draft_case
print '(a)', 'TEST-PASS: draft-case'
end
""",
        )
        self.write(
            suite,
            "valid/images.f90",
            """! TEST-RULE: C53
! TEST-IMAGES: 2
! TEST-PASS: images-unconfigured
program images
print '(a)', 'TEST-PASS: images-unconfigured'
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
! TEST-PASS: generic-reading
program generic_reading
print '(a)', 'TEST-PASS: generic-reading'
end
""",
        )
        self.write(
            suite,
            "valid/ordinary_reading.f90",
            """! TEST-RULE: R704
! TEST-DRAFT: character-ordinary-parse
! TEST-PASS: ordinary-reading
program ordinary_reading
print '(a)', 'TEST-PASS: ordinary-reading'
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
        self.assertEqual(observed.returncode, 0)
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

    def test_literal_and_extended_rank_readings_only_conflict_when_gating(self) -> None:
        suite = self.make_suite("rank draft readings")
        self.write(
            suite,
            "valid/literal.f90",
            """! TEST-RULE: C826
! TEST-DRAFT: literal-rank-limit
! TEST-PASS: literal-rank-reading
program literal_rank_reading
print '(a)', 'TEST-PASS: literal-rank-reading'
end program
""",
        )
        self.write(
            suite,
            "valid/extended.f90",
            """! TEST-RULE: C826
! TEST-DRAFT: extended-rank-limit
! TEST-PASS: extended-rank-reading
program extended_rank_reading
print '(a)', 'TEST-PASS: extended-rank-reading'
end program
""",
        )
        selectors = ["valid/literal.f90", "valid/extended.f90"]
        options = [
            "--draft",
            "literal-rank-limit",
            "--draft",
            "extended-rank-limit",
        ]
        observed, observed_payload = self.run_runner(
            suite, selectors, options
        )
        self.assertEqual(observed.returncode, 0)
        self.assertTrue(observed_payload["summary"]["profile_success"])
        self.assertTrue(observed_payload["summary"]["coverage_complete"])
        self.assertEqual(
            observed_payload["summary"]["executed_observation_cases"], 2
        )

        gated, gated_payload = self.run_runner(
            suite, selectors, options + ["--gate-drafts"]
        )
        self.assertEqual(gated.returncode, 2)
        self.assertIn(
            "cannot gate mutually exclusive draft interpretations",
            gated_payload["fatal_error"],
        )

    def test_selected_draft_enhanced_negative_executes_as_observation(self) -> None:
        suite = self.make_suite("selected enhanced draft")
        case_id = "invalid_compile_time/literal_rank.f90"
        self.write(
            suite,
            case_id,
            """! TEST-RULE: C826
! TEST-DRAFT: literal-rank-limit
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: literal rank limit diagnostic
module literal_rank_m
! TEST-ERROR-HERE
  integer :: offending
! FAKE-DIAGNOSTIC: HERE|Warning|literal rank limit diagnostic
end module
""",
        )
        unselected, unselected_payload = self.run_runner(
            suite, [case_id]
        )
        self.assertEqual(unselected.returncode, 2)
        self.assertEqual(
            self.case_result(unselected_payload, case_id)["reason_code"],
            "unresolved-draft",
        )

        selected, selected_payload = self.run_runner(
            suite,
            [case_id],
            ["--draft", "literal-rank-limit"],
        )
        selected_result = self.case_result(selected_payload, case_id)
        self.assertEqual(selected.returncode, 0, selected.stderr)
        self.assertEqual(selected_result["status"], "pass")
        self.assertEqual(
            selected_result["reason_code"],
            "enhanced-diagnostic-observed",
        )
        self.assertFalse(selected_result["gating"])
        self.assertTrue(selected_result["executed"])

        strict, strict_payload = self.run_runner(
            suite,
            [case_id],
            ["--draft", "literal-rank-limit", "--strict"],
        )
        strict_result = self.case_result(strict_payload, case_id)
        self.assertEqual(strict.returncode, 0)
        self.assertEqual(strict_result["status"], "fail")
        self.assertEqual(
            strict_result["reason_code"], "strict-rejection-required"
        )
        self.assertEqual(
            strict_payload["summary"]["observation_failures"], 1
        )

        gated, gated_payload = self.run_runner(
            suite,
            [case_id],
            [
                "--draft",
                "literal-rank-limit",
                "--strict",
                "--gate-drafts",
            ],
        )
        self.assertEqual(gated.returncode, 1)
        self.assertEqual(
            gated_payload["summary"]["gating_failures"], 1
        )
        self.assertFalse(gated_payload["summary"]["profile_success"])

    def test_profile_success_and_coverage_completeness_are_independent(self) -> None:
        suite = self.make_suite("summary semantics")
        self.write(
            suite,
            "valid/pass.f90",
            """! TEST-RULE: C56
! TEST-PASS: summary-pass
program summary_pass
print '(a)', 'TEST-PASS: summary-pass'
end program
""",
        )
        self.write(
            suite,
            "valid/skip.f90",
            """! TEST-RULE: C57
! TEST-REQUIRES: real16
! TEST-PASS: summary-skip
program summary_skip
print '(a)', 'TEST-PASS: summary-skip'
end program
""",
        )
        self.write(
            suite,
            "valid/observation_failure.f90",
            """! TEST-RULE: C58
! TEST-DRAFT: empty-expansion
! TEST-PASS: observation-failure
program observation_failure
! FAKE-RUN-EXIT: 9
print '(a)', 'TEST-PASS: observation-failure'
end program
""",
        )
        expected_summary_keys = {
            "counts",
            "gating_failures",
            "observation_failures",
            "coverage_cases",
            "executed_cases",
            "executed_gating_cases",
            "executed_observation_cases",
            "unexecuted_cases",
            "skipped_cases",
            "has_executed_cases",
            "profile_success",
            "coverage_complete",
        }

        mixed, mixed_payload = self.run_runner(
            suite, ["valid/pass.f90", "valid/skip.f90"]
        )
        mixed_summary = mixed_payload["summary"]
        self.assertEqual(mixed.returncode, 0)
        self.assertEqual(set(mixed_summary), expected_summary_keys)
        self.assertTrue(mixed_summary["profile_success"])
        self.assertFalse(mixed_summary["coverage_complete"])
        self.assertEqual(mixed_summary["executed_cases"], 1)
        self.assertEqual(mixed_summary["skipped_cases"], 1)

        skipped, skipped_payload = self.run_runner(
            suite, ["valid/skip.f90"]
        )
        skipped_summary = skipped_payload["summary"]
        self.assertEqual(skipped.returncode, 2)
        self.assertFalse(skipped_summary["has_executed_cases"])
        self.assertFalse(skipped_summary["profile_success"])
        self.assertFalse(skipped_summary["coverage_complete"])

        observed, observed_payload = self.run_runner(
            suite,
            ["valid/observation_failure.f90"],
            ["--draft", "empty-expansion"],
        )
        observed_summary = observed_payload["summary"]
        observed_result = self.case_result(
            observed_payload, "valid/observation_failure.f90"
        )
        self.assertEqual(observed.returncode, 0)
        self.assertEqual(observed_result["status"], "fail")
        self.assertFalse(observed_result["gating"])
        self.assertTrue(observed_summary["profile_success"])
        self.assertTrue(observed_summary["coverage_complete"])
        self.assertEqual(observed_summary["observation_failures"], 1)
        self.assertEqual(observed_summary["gating_failures"], 0)

        gated, gated_payload = self.run_runner(
            suite,
            ["valid/observation_failure.f90"],
            ["--draft", "empty-expansion", "--gate-drafts"],
        )
        gated_summary = gated_payload["summary"]
        self.assertEqual(gated.returncode, 1)
        self.assertFalse(gated_summary["profile_success"])
        self.assertTrue(gated_summary["coverage_complete"])
        self.assertEqual(gated_summary["gating_failures"], 1)

    def test_image_launcher_placeholders_execute_multi_image_case(self) -> None:
        suite = self.make_suite("image launcher")
        self.write(
            suite,
            "valid/images.f90",
            """! TEST-RULE: C55
! TEST-IMAGES: 3
! TEST-PASS: three-images
program images
print '(a)', 'TEST-PASS: three-images'
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

    def test_stop_image_metadata_validation(self) -> None:
        suite = self.make_suite("stop image validation")
        self.write(
            suite,
            "valid/not_runtime_negative.f90",
            """! TEST-RULE: 11.4
! TEST-STOP-IMAGE: 1
! TEST-PASS: not-runtime-negative
program not_runtime_negative
print '(a)', 'TEST-PASS: not-runtime-negative'
end program
""",
        )
        self.write(
            suite,
            "invalid_compile_time/not_runtime_negative.f90",
            """! TEST-RULE: 11.4
! TEST-STOP-IMAGE: 1
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: selected image metadata invalid here
module stop_image_compile_negative
! TEST-ERROR-HERE
  integer :: offending
end module
""",
        )
        for name, image_text in (
            ("zero", "0"),
            ("too_large", "4"),
            ("not_integer", "image_one"),
            ("missing_fallback", "1"),
        ):
            self.write(
                suite,
                "invalid_runtime/{}.f90".format(name),
                """! TEST-RULE: 11.4
! TEST-IMAGES: 3
! TEST-STOP-IMAGE: {image}
! TEST-STOP: invalid-stop-image
program invalid_stop_image
  write (*, '(a)') 'TEST-STOP: invalid-stop-image'
  error stop 'invalid stop image metadata'
  write (*, '(a)') 'TEST-UNEXPECTED-RETURN: invalid-stop-image'
end program
""".format(
                    image=image_text
                ),
            )

        for case_id in (
            "valid/not_runtime_negative.f90",
            "invalid_compile_time/not_runtime_negative.f90",
        ):
            completed, payload = self.run_runner(suite, [case_id])
            result = self.case_result(payload, case_id)
            self.assertEqual(completed.returncode, 1)
            self.assertEqual(result["status"], "error")
            self.assertIn(
                "unexpected-stop-image",
                {
                    issue["code"]
                    for issue in result["details"]["issues"]
                },
            )

        for name, expected_code in (
            ("zero", "invalid-stop-image"),
            ("too_large", "invalid-stop-image"),
            ("not_integer", "metadata-parse"),
            ("missing_fallback", "missing-inconclusive-source-marker"),
        ):
            case_id = "invalid_runtime/{}.f90".format(name)
            completed, payload = self.run_runner(suite, [case_id])
            result = self.case_result(payload, case_id)
            self.assertEqual(completed.returncode, 1)
            self.assertEqual(result["status"], "error")
            self.assertIn(
                expected_code,
                {
                    issue["code"]
                    for issue in result["details"]["issues"]
                },
            )

    def test_selected_image_calibration_topology_status_and_cache(self) -> None:
        suite = self.make_suite("selected image calibration")

        def selected_source(
            stop_id: str, stop_image: int, runtime_status: int
        ) -> str:
            return """! TEST-RULE: 5.3.7 11.4 11.7.3
! TEST-IMAGES: 3
! TEST-STOP-IMAGE: {stop_image}
! TEST-STOP: {stop_id}
program selected_image_stop
  use, intrinsic :: iso_fortran_env, only: output_unit
  implicit none
  integer :: sync_status
  sync all
  if (this_image() == {stop_image}) then
    write (output_unit, '(a)') 'TEST-STOP: {stop_id}'
    flush (output_unit)
    error stop 'selected image calibration'
  else
    sync all (stat=sync_status)
    if (sync_status == 0) then
      write (output_unit, '(a)') 'TEST-UNEXPECTED-RETURN: {stop_id}'
      flush (output_unit)
    else
      write (output_unit, '(a,1x,i0)') &
        'TEST-INCONCLUSIVE: coarray-sync-status', sync_status
      flush (output_unit)
      sync all
    end if
  end if
! FAKE-RUN-OUTPUT-IMAGE: {stop_image}|TEST-STOP: {stop_id}
! FAKE-RUN-EXIT-IMAGE: {stop_image}|{runtime_status}
end program
""".format(
                stop_id=stop_id,
                stop_image=stop_image,
                runtime_status=runtime_status,
            )

        cases = (
            ("selected_one_a", 1, 41),
            ("selected_two", 2, 42),
            ("selected_one_b", 1, 41),
        )
        selectors: List[str] = []
        for name, stop_image, runtime_status in cases:
            case_id = "invalid_runtime/{}.f90".format(name)
            self.write(
                suite,
                case_id,
                selected_source(name, stop_image, runtime_status),
            )
            selectors.append(case_id)
        all_image_id = "invalid_runtime/all_images.f90"
        self.write(
            suite,
            all_image_id,
            """! TEST-RULE: 5.3.7 11.4
! TEST-IMAGES: 3
! TEST-STOP: all-images
program all_image_stop
  use, intrinsic :: iso_fortran_env, only: output_unit
  write (output_unit, '(a)') 'TEST-STOP: all-images'
  flush (output_unit)
  error stop 'selected image calibration'
  write (output_unit, '(a)') 'TEST-UNEXPECTED-RETURN: all-images'
! FAKE-RUN-OUTPUT: TEST-STOP: all-images
! FAKE-RUN-EXIT: 23
end program
""",
        )
        selectors.append(all_image_id)
        duplicate_id = "invalid_runtime/duplicate_selected_marker.f90"
        duplicate_text = selected_source(
            "duplicate-selected-marker", 3, 44
        )
        duplicate_directive = (
            "! FAKE-RUN-OUTPUT-IMAGE: 3|"
            "TEST-STOP: duplicate-selected-marker"
        )
        duplicate_text = duplicate_text.replace(
            duplicate_directive,
            duplicate_directive + "\n" + duplicate_directive,
        )
        duplicate_text += (
            "! FAKE-RUN-OUTPUT-IMAGE: 1|"
            "TEST-INCONCLUSIVE: coarray-sync-status 44\n"
        )
        self.write(suite, duplicate_id, duplicate_text)
        other_status_id = "invalid_runtime/other_sync_status.f90"
        self.write(
            suite,
            other_status_id,
            selected_source("other-sync-status", 2, 42),
        )
        runtime_inconclusive_id = (
            "invalid_runtime/runtime_inconclusive.f90"
        )
        runtime_inconclusive_text = selected_source(
            "runtime-inconclusive", 2, 42
        )
        runtime_inconclusive_text = runtime_inconclusive_text.replace(
            "! FAKE-RUN-EXIT-IMAGE: 2|42",
            "! FAKE-RUN-EXIT-IMAGE: 2|42\n"
            "! FAKE-RUN-OUTPUT-IMAGE: 1|"
            "TEST-INCONCLUSIVE: coarray-sync-status 42",
        )
        self.write(
            suite,
            runtime_inconclusive_id,
            runtime_inconclusive_text,
        )
        precedence_id = "invalid_runtime/inconclusive_precedence.f90"
        precedence_text = selected_source(
            "inconclusive-precedence", 2, 42
        )
        precedence_text = precedence_text.replace(
            "! FAKE-RUN-EXIT-IMAGE: 2|42",
            "! FAKE-RUN-EXIT-IMAGE: 2|42\n"
            "! FAKE-RUN-OUTPUT-IMAGE: 1|"
            "TEST-INCONCLUSIVE: coarray-sync-status 42\n"
            "! FAKE-RUN-OUTPUT-IMAGE: 3|"
            "TEST-UNEXPECTED-RETURN: inconclusive-precedence",
        )
        self.write(suite, precedence_id, precedence_text)

        launcher = "{} {} --images {{images}} --exe {{exe}}".format(
            shlex_quote(sys.executable),
            shlex_quote(str(FAKE_LAUNCHER)),
        )
        completed, payload = self.run_runner(
            suite,
            selectors,
            ["--launcher", launcher],
            env={
                "FAKE_CALIBRATION_STATUS_IMAGE_1": "41",
                "FAKE_CALIBRATION_STATUS_IMAGE_2": "42",
            },
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        listed = subprocess.run(
            [
                sys.executable,
                str(RUNNER),
                "list",
                "--suite-root",
                str(suite),
                "--json",
            ]
            + selectors,
            cwd=str(self.base),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=10,
        )
        listed_payload = json.loads(listed.stdout)
        listed_stop_images = {
            case["id"]: case["metadata"]["stop_image"]
            for case in listed_payload["cases"]
        }
        self.assertTrue(
            all(
                case["metadata"]["stop_image_explicit"]
                for case in listed_payload["cases"]
                if case["id"] != all_image_id
            )
        )
        self.assertFalse(
            next(
                case["metadata"]["stop_image_explicit"]
                for case in listed_payload["cases"]
                if case["id"] == all_image_id
            )
        )
        first = self.case_result(
            payload, "invalid_runtime/selected_one_a.f90"
        )
        second = self.case_result(
            payload, "invalid_runtime/selected_two.f90"
        )
        third = self.case_result(
            payload, "invalid_runtime/selected_one_b.f90"
        )
        all_images = self.case_result(payload, all_image_id)
        for result, image, status in (
            (first, 1, 41),
            (second, 2, 42),
            (third, 1, 41),
        ):
            self.assertEqual(result["status"], "pass")
            self.assertEqual(
                listed_stop_images[result["id"]], image
            )
            calibration = result["details"]["calibration"]
            self.assertEqual(calibration["scope"], "selected-image")
            self.assertEqual(calibration["stop_image"], image)
            self.assertEqual(
                result["details"]["runtime"]["outcome"],
                {"kind": "exit", "status": status},
            )
        self.assertFalse(first["details"]["calibration"]["cached"])
        self.assertFalse(second["details"]["calibration"]["cached"])
        self.assertTrue(third["details"]["calibration"]["cached"])
        self.assertEqual(all_images["status"], "pass")
        self.assertFalse(all_images["details"]["calibration"]["cached"])
        self.assertEqual(
            all_images["details"]["calibration"]["scope"], "all-images"
        )
        self.assertIsNone(
            all_images["details"]["calibration"]["stop_image"]
        )
        self.assertEqual(
            first["details"]["calibration"]["run"]["outcome"],
            {"kind": "exit", "status": 41},
        )
        self.assertEqual(
            second["details"]["calibration"]["run"]["outcome"],
            {"kind": "exit", "status": 42},
        )

        mismatch, mismatch_payload = self.run_runner(
            suite,
            ["invalid_runtime/selected_two.f90"],
            ["--launcher", launcher],
            env={"FAKE_CALIBRATION_STATUS_IMAGE_2": "43"},
        )
        mismatch_result = self.case_result(
            mismatch_payload, "invalid_runtime/selected_two.f90"
        )
        self.assertEqual(mismatch.returncode, 1)
        self.assertEqual(
            mismatch_result["reason_code"], "error-stop-outcome-mismatch"
        )

        sync_return, sync_return_payload = self.run_runner(
            suite,
            ["invalid_runtime/selected_two.f90"],
            ["--launcher", launcher],
            env={
                "FAKE_CALIBRATION_STATUS_IMAGE_2": "0",
                "FAKE_CALIBRATION_SYNC_RETURNS": "1",
                "FAKE_LAUNCH_SELECTED_IMAGE": "2",
            },
        )
        sync_return_result = self.case_result(
            sync_return_payload, "invalid_runtime/selected_two.f90"
        )
        self.assertEqual(sync_return.returncode, 1)
        self.assertEqual(
            sync_return_result["reason_code"],
            "error-stop-calibration-failure",
        )
        self.assertIn("returned unexpectedly", sync_return_result["message"])

        other_status, other_status_payload = self.run_runner(
            suite,
            [other_status_id],
            ["--launcher", launcher],
            env={
                "FAKE_CALIBRATION_STATUS_IMAGE_2": "0",
                "FAKE_CALIBRATION_SYNC_STATUS": "42",
                "FAKE_CALIBRATION_PROPAGATION_STATUS": "42",
                "FAKE_LAUNCH_SELECTED_IMAGE": "2",
            },
        )
        other_status_result = self.case_result(
            other_status_payload, other_status_id
        )
        self.assertEqual(other_status.returncode, 1)
        self.assertEqual(other_status_result["status"], "error")
        self.assertEqual(
            other_status_result["reason_code"],
            "calibration-inconclusive",
        )
        self.assertEqual(
            other_status_result["details"]["calibration"][
                "inconclusive_lines"
            ],
            ["FGS-CALIBRATION-INCONCLUSIVE: coarray-sync-status 42"],
        )
        self.assertEqual(
            other_status_result["details"]["calibration"][
                "evidence_class"
            ],
            "inconclusive",
        )
        self.assertEqual(
            other_status_result["details"]["calibration"]["run"]["outcome"],
            {"kind": "exit", "status": 42},
        )

        runtime_inconclusive, runtime_inconclusive_payload = self.run_runner(
            suite,
            [runtime_inconclusive_id],
            ["--launcher", launcher],
            env={
                "FAKE_CALIBRATION_STATUS_IMAGE_2": "42",
                "FAKE_LAUNCH_SELECTED_IMAGE": "2",
                "FAKE_CONTINUE_AFTER_NONZERO": "1",
            },
        )
        runtime_inconclusive_result = self.case_result(
            runtime_inconclusive_payload,
            runtime_inconclusive_id,
        )
        self.assertEqual(runtime_inconclusive.returncode, 1)
        self.assertEqual(runtime_inconclusive_result["status"], "error")
        self.assertEqual(
            runtime_inconclusive_result["reason_code"],
            "runtime-inconclusive",
        )
        self.assertEqual(
            runtime_inconclusive_result["details"][
                "runtime_inconclusive_lines"
            ],
            ["TEST-INCONCLUSIVE: coarray-sync-status 42"],
        )
        self.assertEqual(
            runtime_inconclusive_result["details"]["runtime_evidence"][
                "classification"
            ],
            "inconclusive",
        )
        self.assertEqual(
            runtime_inconclusive_result["details"]["runtime"]["outcome"],
            {"kind": "exit", "status": 42},
        )
        self.assertEqual(
            runtime_inconclusive_result["details"]["runtime"][
                "stdout"
            ].splitlines(),
            [
                "TEST-STOP: runtime-inconclusive",
                "TEST-INCONCLUSIVE: coarray-sync-status 42",
            ],
        )
        self.assertEqual(
            runtime_inconclusive_result["details"]["calibration"]["run"][
                "outcome"
            ],
            {"kind": "exit", "status": 42},
        )

        precedence, precedence_payload = self.run_runner(
            suite,
            [precedence_id],
            ["--launcher", launcher],
            env={
                "FAKE_CALIBRATION_STATUS_IMAGE_2": "42",
                "FAKE_LAUNCH_SELECTED_IMAGE": "2",
                "FAKE_CONTINUE_AFTER_NONZERO": "1",
            },
        )
        precedence_result = self.case_result(
            precedence_payload, precedence_id
        )
        self.assertEqual(precedence.returncode, 1)
        self.assertEqual(precedence_result["status"], "fail")
        self.assertEqual(
            precedence_result["reason_code"],
            "unexpected-runtime-return",
        )

        duplicate_runtime, duplicate_runtime_payload = self.run_runner(
            suite,
            [duplicate_id],
            ["--launcher", launcher],
            env={"FAKE_CALIBRATION_STATUS_IMAGE_3": "44"},
        )
        duplicate_runtime_result = self.case_result(
            duplicate_runtime_payload, duplicate_id
        )
        self.assertEqual(duplicate_runtime.returncode, 1)
        self.assertEqual(
            duplicate_runtime_result["reason_code"],
            "runtime-marker-count",
        )
        self.assertEqual(
            duplicate_runtime_result["details"]["runtime_protocol"][
                "matching_marker_count"
            ],
            2,
        )
        self.assertEqual(
            duplicate_runtime_result["details"][
                "runtime_inconclusive_lines"
            ],
            ["TEST-INCONCLUSIVE: coarray-sync-status 44"],
        )

        duplicate_calibration, duplicate_calibration_payload = self.run_runner(
            suite,
            ["invalid_runtime/selected_two.f90"],
            ["--launcher", launcher],
            env={
                "FAKE_CALIBRATION_STATUS_IMAGE_2": "42",
                "FAKE_CALIBRATION_DUPLICATE_MARKER": "1",
            },
        )
        duplicate_calibration_result = self.case_result(
            duplicate_calibration_payload,
            "invalid_runtime/selected_two.f90",
        )
        self.assertEqual(duplicate_calibration.returncode, 1)
        self.assertEqual(
            duplicate_calibration_result["reason_code"],
            "error-stop-calibration-failure",
        )
        self.assertIn(
            "expected exactly one",
            duplicate_calibration_result["message"],
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
                "fail",
                "error-stop-outcome-mismatch",
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
                if name == "accepted":
                    self.assertEqual(
                        result["details"]["calibration"]["scope"],
                        "all-images",
                    )
                    self.assertIsNone(
                        result["details"]["calibration"]["stop_image"]
                    )
                if name == "opaque_134":
                    self.assertEqual(
                        result["details"]["runtime"]["outcome"],
                        {"kind": "exit", "status": 134},
                    )

    def test_error_stop_calibration_uses_each_literal_and_quiet_form(self) -> None:
        suite = self.make_suite("literal stop calibration")
        cases = {
            "absent": ("error stop", "none", None, None),
            "integer": ("error stop 0", "integer-literal", "0", None),
            "character": (
                'error stop "alpha"',
                "character-literal",
                '"alpha"',
                None,
            ),
            "quiet_only": (
                "error stop, quiet = .true.",
                "none",
                None,
                ".true.",
            ),
            "integer_quiet": (
                "error stop -7, quiet = .false.",
                "integer-literal",
                "-7",
                ".false.",
            ),
        }
        selectors: List[str] = []
        for name, (statement, _, _, _) in cases.items():
            stop_id = "literal-{}".format(name)
            self.write(
                suite,
                "invalid_runtime/{}.f90".format(name),
                """! TEST-RULE: 11.6
! TEST-STOP: {stop_id}
program literal_stop
                  use, intrinsic :: iso_fortran_env, only: output_unit
                  write (output_unit, '(a)') 'TEST-STOP: {stop_id}'
                  flush (output_unit)
                  {statement}
                  write (output_unit, '(a)') 'TEST-UNEXPECTED-RETURN: {stop_id}'
! FAKE-RUN-OUTPUT: TEST-STOP: {stop_id}
end program
""".format(
                    stop_id=stop_id,
                    statement=statement,
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
        for name, (_, code_form, literal, quiet) in cases.items():
            result = self.case_result(
                payload, "invalid_runtime/{}.f90".format(name)
            )
            self.assertEqual(result["status"], "pass")
            stop_spec = result["details"]["calibration"]["stop_spec"]
            self.assertEqual(stop_spec["code_form"], code_form)
            self.assertEqual(stop_spec["code_literal"], literal)
            self.assertEqual(stop_spec["quiet_literal"], quiet)
            self.assertTrue(stop_spec["flush_before_stop"])
            calibration_statuses.add(
                result["details"]["calibration"]["run"]["outcome"]["status"]
            )
        self.assertGreaterEqual(len(calibration_statuses), 3)

    def test_error_stop_status_zero_126_127_and_partial_image_reachability(self) -> None:
        suite = self.make_suite("reserved stop statuses")
        for status in (0, 126, 127):
            self.write(
                suite,
                "invalid_runtime/status_{}.f90".format(status),
                self.runtime_source(
                    "! FAKE-RUN-OUTPUT: TEST-STOP: runtime-case\n"
                    "! FAKE-RUN-EXIT: {}\n".format(status)
                ),
            )
            completed, payload = self.run_runner(
                suite,
                ["invalid_runtime/status_{}.f90".format(status)],
                env={"FAKE_CALIBRATION_STATUS": str(status)},
            )
            result = self.case_result(
                payload, "invalid_runtime/status_{}.f90".format(status)
            )
            self.assertEqual(completed.returncode, 0, completed.stderr)
            self.assertEqual(result["status"], "pass")
            self.assertEqual(
                result["details"]["runtime"]["outcome"],
                {"kind": "exit", "status": status},
            )

        mismatch, mismatch_payload = self.run_runner(
            suite,
            ["invalid_runtime/status_126.f90"],
            env={"FAKE_CALIBRATION_STATUS": "127"},
        )
        mismatch_result = self.case_result(
            mismatch_payload, "invalid_runtime/status_126.f90"
        )
        self.assertEqual(mismatch.returncode, 1)
        self.assertEqual(
            mismatch_result["reason_code"], "error-stop-outcome-mismatch"
        )

        no_evidence, no_evidence_payload = self.run_runner(
            suite,
            ["invalid_runtime/status_126.f90"],
            env={
                "FAKE_CALIBRATION_STATUS": "126",
                "FAKE_CALIBRATION_NO_MARKER": "1",
            },
        )
        no_evidence_result = self.case_result(
            no_evidence_payload, "invalid_runtime/status_126.f90"
        )
        self.assertEqual(no_evidence.returncode, 1)
        self.assertEqual(
            no_evidence_result["reason_code"],
            "error-stop-calibration-failure",
        )
        self.assertIn(
            "reachability marker", no_evidence_result["message"]
        )

        multi_source = self.runtime_source(
            "! FAKE-RUN-OUTPUT: TEST-STOP: runtime-case\n"
            "! FAKE-RUN-EXIT: 23\n"
        ).replace(
            "! TEST-STOP: runtime-case",
            "! TEST-STOP: runtime-case\n! TEST-IMAGES: 3",
            1,
        )
        self.write(
            suite, "invalid_runtime/partial_images.f90", multi_source
        )
        launcher = "{} {} --images {{images}} --exe {{exe}}".format(
            shlex_quote(sys.executable),
            shlex_quote(str(FAKE_LAUNCHER)),
        )
        partial, partial_payload = self.run_runner(
            suite,
            ["invalid_runtime/partial_images.f90"],
            ["--launcher", launcher],
            env={"FAKE_LAUNCH_ONCE": "1"},
        )
        partial_result = self.case_result(
            partial_payload, "invalid_runtime/partial_images.f90"
        )
        self.assertEqual(partial.returncode, 0, partial.stderr)
        self.assertEqual(partial_result["status"], "pass")
        self.assertEqual(
            partial_result["details"]["runtime"]["stdout"].splitlines(),
            ["TEST-STOP: runtime-case"],
        )

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

    def test_native_error_stop_zero_is_calibrated_as_status_zero(self) -> None:
        compiler = shutil.which("gfortran")
        if compiler is None:
            self.skipTest("gfortran is unavailable")
        suite = self.make_suite("native error stop zero")
        self.write(
            suite,
            "invalid_runtime/native_zero.f90",
            """! TEST-RULE: 11.4
! TEST-STOP: native-error-stop-zero
program native_error_stop_zero
  use, intrinsic :: iso_fortran_env, only: output_unit
  write (output_unit, '(a)') 'TEST-STOP: native-error-stop-zero'
  flush (output_unit)
  error stop 0, quiet=.true.
  write (output_unit, '(a)') &
    'TEST-UNEXPECTED-RETURN: native-error-stop-zero'
end program
""",
        )
        completed, payload = self.run_runner(
            suite,
            ["invalid_runtime/native_zero.f90"],
            fc=compiler,
        )
        result = self.case_result(
            payload, "invalid_runtime/native_zero.f90"
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(result["reason_code"], "calibrated-error-stop")
        self.assertEqual(
            result["details"]["calibration"]["run"]["outcome"],
            {"kind": "exit", "status": 0},
        )
        self.assertEqual(
            result["details"]["runtime"]["outcome"],
            {"kind": "exit", "status": 0},
        )

    def test_native_selected_image_calibration_source_compiles(self) -> None:
        compiler = shutil.which("gfortran")
        if compiler is None:
            self.skipTest("gfortran is unavailable")
        source = self.base / "selected_image_calibration.f90"
        obj = self.base / "selected_image_calibration.o"
        source.write_text(
            error_stop_calibration_source(
                " 'selected image'",
                True,
                stop_image=1,
            ),
            encoding="utf-8",
        )
        completed = subprocess.run(
            [
                compiler,
                "-fcoarray=single",
                "-c",
                str(source),
                "-o",
                str(obj),
            ],
            cwd=str(self.base),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=30,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertTrue(obj.is_file())

    def test_work_area_preserves_configured_parent(self) -> None:
        configured_root = (
            self.base / "configured root" / "tests" / ".runner-work"
        )
        configured_work = WorkArea(configured_root, keep=False)
        self.assertEqual(
            configured_work.root,
            configured_root.resolve(),
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
! TEST-PASS: concurrent
program concurrent
! FAKE-COMPILE-SLEEP: 0.2
print '(a)', 'TEST-PASS: concurrent'
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
