#!/usr/bin/env python3
"""Ordinary processor probes and generated auto-generic runtime cases."""

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple


INVENTORY_SCHEMA = 1


KIND_INVENTORY_SOURCE = r"""program fgs_processor_kind_inventory
  use, intrinsic :: iso_fortran_env, only: &
       integer_kinds, real_kinds, logical_kinds, character_kinds, &
       int8, int16, int32, int64, real16, real32, real64, real128, &
       compiler_version
  implicit none
  integer :: i

  write (*, '(a)') 'FGS-PROCESSOR-INVENTORY-V1'
  do i = 1, size(integer_kinds)
    write (*, '(a,1x,i0)') 'INTEGER_KIND', integer_kinds(i)
  end do
  do i = 1, size(real_kinds)
    write (*, '(a,1x,i0)') 'REAL_KIND', real_kinds(i)
  end do
  do i = 1, size(logical_kinds)
    write (*, '(a,1x,i0)') 'LOGICAL_KIND', logical_kinds(i)
  end do
  do i = 1, size(character_kinds)
    write (*, '(a,1x,i0)') 'CHARACTER_KIND', character_kinds(i)
  end do
  write (*, '(a,1x,i0)') 'NAMED_INT8', int8
  write (*, '(a,1x,i0)') 'NAMED_INT16', int16
  write (*, '(a,1x,i0)') 'NAMED_INT32', int32
  write (*, '(a,1x,i0)') 'NAMED_INT64', int64
  write (*, '(a,1x,i0)') 'NAMED_REAL16', real16
  write (*, '(a,1x,i0)') 'NAMED_REAL32', real32
  write (*, '(a,1x,i0)') 'NAMED_REAL64', real64
  write (*, '(a,1x,i0)') 'NAMED_REAL128', real128
  write (*, '(a,1x,i0)') 'NAMED_ASCII', selected_char_kind('ASCII')
  write (*, '(a,1x,i0)') 'NAMED_ISO_10646', selected_char_kind('ISO_10646')
  write (*, '(a,1x,a)') 'COMPILER_VERSION', compiler_version()
  write (*, '(a)') 'FGS-PROCESSOR-INVENTORY-END'
end program
"""


MAX_RANK_INVENTORY_SOURCE = r"""program fgs_processor_max_rank_inventory
  use, intrinsic :: iso_fortran_env, only: max_rank
  implicit none
  write (*, '(a)') 'FGS-MAX-RANK-INVENTORY-V1'
  write (*, '(a,1x,i0)') 'MAX_RANK', max_rank()
  write (*, '(a,1x,i0)') 'MAX_RANK_CORANK_1', max_rank(1)
  write (*, '(a)') 'FGS-MAX-RANK-INVENTORY-END'
end program
"""


FEATURE_PREREQUISITE_SOURCE = r"""module fgs_auto_generic_prerequisite_m
  use, intrinsic :: iso_fortran_env, only: integer_kinds
  implicit none
contains
  generic function fgs_plain_identity(x) result(y)
    integer, intent(in) :: x
    integer :: y
    y = x
  end function

  generic function fgs_type_identity(x) result(y)
    type(integer, real), intent(in) :: x
    typeof(x) :: y
    select generic type (x)
    declared type is (integer)
      y = x
    declared type is (real)
      y = x
    end select
  end function

  generic function fgs_kind_identity(x) result(y)
    integer(integer_kinds), intent(in) :: x
    typeof(x) :: y
    y = x
  end function

  generic function fgs_rank_value(x) result(y)
    integer, intent(in), rank(0:1) :: x
    integer :: y
    select generic rank (x)
    rank (0)
      y = x
    rank (1)
      y = size(x)
    end select
  end function
end module

program fgs_auto_generic_prerequisite
  use fgs_auto_generic_prerequisite_m
  implicit none
  integer :: values(2)
  values = [1, 2]
  if (fgs_plain_identity(3) /= 3) error stop 'plain generic prerequisite'
  if (fgs_type_identity(7) /= 7) error stop 'integer type prerequisite'
  if (fgs_type_identity(0.5) /= 0.5) error stop 'real type prerequisite'
  if (fgs_kind_identity(9) /= 9) error stop 'kind prerequisite'
  if (fgs_rank_value(4) /= 4) error stop 'scalar rank prerequisite'
  if (fgs_rank_value(values) /= 2) error stop 'array rank prerequisite'
  write (*, '(a)') 'FGS-AUTO-GENERIC-PREREQUISITE-PASS'
end program
"""


ERROR_STOP_CALIBRATION_TEMPLATE = r"""program fgs_error_stop_calibration
  use, intrinsic :: iso_fortran_env, only: output_unit
  implicit none
  write (output_unit, '(a)') 'FGS-ERROR-STOP-CALIBRATION'
{flush_statement}
  error stop{stop_clause}
  write (output_unit, '(a)') 'FGS-CALIBRATION-UNEXPECTED-RETURN'
end program
"""


def error_stop_calibration_source(
    stop_clause: str, flush_before_stop: bool
) -> str:
    flush_statement = (
        "  flush (output_unit)" if flush_before_stop else ""
    )
    return ERROR_STOP_CALIBRATION_TEMPLATE.format(
        flush_statement=flush_statement,
        stop_clause=stop_clause,
    )


@dataclass
class ProcessorInventory:
    integer_kinds: List[int]
    real_kinds: List[int]
    logical_kinds: List[int]
    character_kinds: List[int]
    named_kinds: Dict[str, int]
    compiler_version: str = ""
    max_rank: Optional[int] = None
    max_rank_corank_1: Optional[int] = None
    max_rank_error: Optional[str] = None
    warnings: List[str] = field(default_factory=list)
    schema_version: int = INVENTORY_SCHEMA

    def capability_value(self, name: str) -> Optional[int]:
        if name in self.named_kinds:
            return self.named_kinds[name]
        counts = {
            "integer_kinds": len(self.integer_kinds),
            "real_kinds": len(self.real_kinds),
            "logical_kinds": len(self.logical_kinds),
            "character_kinds": len(self.character_kinds),
        }
        if name in counts:
            return counts[name]
        if name == "max_rank":
            return self.max_rank
        return None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "schema_version": self.schema_version,
            "integer_kinds": list(self.integer_kinds),
            "real_kinds": list(self.real_kinds),
            "logical_kinds": list(self.logical_kinds),
            "character_kinds": list(self.character_kinds),
            "named_kinds": dict(sorted(self.named_kinds.items())),
            "compiler_version": self.compiler_version,
            "max_rank": self.max_rank,
            "max_rank_corank_1": self.max_rank_corank_1,
            "max_rank_error": self.max_rank_error,
            "warnings": list(self.warnings),
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "ProcessorInventory":
        return cls(
            integer_kinds=[int(value) for value in data["integer_kinds"]],
            real_kinds=[int(value) for value in data["real_kinds"]],
            logical_kinds=[int(value) for value in data["logical_kinds"]],
            character_kinds=[int(value) for value in data["character_kinds"]],
            named_kinds={
                str(key): int(value)
                for key, value in dict(data["named_kinds"]).items()
            },
            compiler_version=str(data.get("compiler_version", "")),
            max_rank=(
                None if data.get("max_rank") is None else int(data["max_rank"])
            ),
            max_rank_corank_1=(
                None
                if data.get("max_rank_corank_1") is None
                else int(data["max_rank_corank_1"])
            ),
            max_rank_error=(
                None
                if data.get("max_rank_error") is None
                else str(data["max_rank_error"])
            ),
            warnings=[str(value) for value in data.get("warnings", [])],
            schema_version=int(data.get("schema_version", INVENTORY_SCHEMA)),
        )


def _parse_tagged_integers(
    text: str, expected_header: str, expected_footer: str
) -> Tuple[Dict[str, List[int]], Dict[str, str]]:
    lines = text.splitlines()
    if expected_header not in lines:
        raise ValueError("probe output is missing {!r}".format(expected_header))
    if expected_footer not in lines:
        raise ValueError("probe output is missing {!r}".format(expected_footer))
    integers: Dict[str, List[int]] = {}
    strings: Dict[str, str] = {}
    active = False
    for raw_line in lines:
        line = raw_line.strip()
        if line == expected_header:
            active = True
            continue
        if line == expected_footer:
            break
        if not active or not line:
            continue
        tag, separator, value = line.partition(" ")
        if not separator:
            continue
        value = value.strip()
        try:
            integer_value = int(value, 10)
        except ValueError:
            strings[tag] = value
        else:
            integers.setdefault(tag, []).append(integer_value)
    return integers, strings


def parse_kind_inventory(text: str) -> ProcessorInventory:
    integers, strings = _parse_tagged_integers(
        text,
        "FGS-PROCESSOR-INVENTORY-V1",
        "FGS-PROCESSOR-INVENTORY-END",
    )
    array_tags = {
        "integer_kinds": "INTEGER_KIND",
        "real_kinds": "REAL_KIND",
        "logical_kinds": "LOGICAL_KIND",
        "character_kinds": "CHARACTER_KIND",
    }
    arrays: Dict[str, List[int]] = {}
    for field_name, tag in array_tags.items():
        values = integers.get(tag, [])
        if not values:
            raise ValueError("probe did not report any {}".format(field_name))
        if len(values) != len(set(values)):
            raise ValueError("probe reported duplicate {}".format(field_name))
        if any(value < 0 for value in values):
            raise ValueError(
                "supported {} contains a negative kind value".format(field_name)
            )
        arrays[field_name] = values

    named_tags = {
        "int8": "NAMED_INT8",
        "int16": "NAMED_INT16",
        "int32": "NAMED_INT32",
        "int64": "NAMED_INT64",
        "real16": "NAMED_REAL16",
        "real32": "NAMED_REAL32",
        "real64": "NAMED_REAL64",
        "real128": "NAMED_REAL128",
        "ascii": "NAMED_ASCII",
        "iso_10646": "NAMED_ISO_10646",
    }
    named: Dict[str, int] = {}
    for name, tag in named_tags.items():
        values = integers.get(tag, [])
        if len(values) != 1:
            raise ValueError("probe did not report exactly one {}".format(name))
        named[name] = values[0]

    memberships = {
        "int8": arrays["integer_kinds"],
        "int16": arrays["integer_kinds"],
        "int32": arrays["integer_kinds"],
        "int64": arrays["integer_kinds"],
        "real16": arrays["real_kinds"],
        "real32": arrays["real_kinds"],
        "real64": arrays["real_kinds"],
        "real128": arrays["real_kinds"],
        "ascii": arrays["character_kinds"],
        "iso_10646": arrays["character_kinds"],
    }
    warnings: List[str] = []
    for name, supported in memberships.items():
        value = named[name]
        if value >= 0 and value not in supported:
            warnings.append(
                "{} kind {} was absent from the processor kind array; "
                "the generated inventory union includes it".format(name, value)
            )
            supported.append(value)

    return ProcessorInventory(
        integer_kinds=arrays["integer_kinds"],
        real_kinds=arrays["real_kinds"],
        logical_kinds=arrays["logical_kinds"],
        character_kinds=arrays["character_kinds"],
        named_kinds=named,
        compiler_version=strings.get("COMPILER_VERSION", ""),
        warnings=warnings,
    )


def parse_max_rank_inventory(text: str) -> Tuple[int, int]:
    integers, _ = _parse_tagged_integers(
        text,
        "FGS-MAX-RANK-INVENTORY-V1",
        "FGS-MAX-RANK-INVENTORY-END",
    )
    max_values = integers.get("MAX_RANK", [])
    corank_values = integers.get("MAX_RANK_CORANK_1", [])
    if len(max_values) != 1 or len(corank_values) != 1:
        raise ValueError("MAX_RANK probe output is incomplete")
    return max_values[0], corank_values[0]


def generated_kind_counts(inventory: ProcessorInventory) -> Dict[str, int]:
    integer_count = len(inventory.integer_kinds)
    real_count = len(inventory.real_kinds)
    logical_count = len(inventory.logical_kinds)
    character_count = len(inventory.character_kinds)
    intrinsic_kind_cases = (
        integer_count
        + 2 * real_count
        + logical_count
        + character_count
    )
    joint_specializations = 2 * intrinsic_kind_cases
    return {
        "integer_kinds": integer_count,
        "real_kinds": real_count,
        "complex_kinds": real_count,
        "logical_kinds": logical_count,
        "character_kinds": character_count,
        "kind_specializations_exercised": intrinsic_kind_cases,
        "kind_value_checks": intrinsic_kind_cases,
        "kind_result_checks": intrinsic_kind_cases,
        "kind_save_state_specializations": intrinsic_kind_cases,
        "type_save_state_specializations": 4,
        "rank_save_state_specializations": 2,
        "joint_type_kind_rank_type_families": 5,
        "joint_type_kind_rank_ranks": 2,
        "joint_type_kind_rank_save_specializations": joint_specializations,
        "joint_type_kind_rank_save_calls": 2 * joint_specializations,
    }


def generate_kind_runtime_source(
    inventory: ProcessorInventory,
) -> Tuple[str, Dict[str, int]]:
    lines: List[str] = [
        "module fgs_generated_processor_kinds_m",
        "  implicit none",
    ]
    for name, values in (
        ("fgs_integer_kinds", inventory.integer_kinds),
        ("fgs_real_kinds", inventory.real_kinds),
        ("fgs_logical_kinds", inventory.logical_kinds),
        ("fgs_character_kinds", inventory.character_kinds),
    ):
        lines.append(
            "  integer, parameter :: {}({}) = [ &".format(name, len(values))
        )
        for index, value in enumerate(values):
            suffix = ", &" if index + 1 < len(values) else " ]"
            lines.append("       {}{}".format(value, suffix))
    lines.extend(
        [
        "contains",
        "  generic function id_integer(x) result(y)",
        "    integer(fgs_integer_kinds), intent(in) :: x",
        "    typeof(x) :: y",
        "    y = x",
        "  end function",
        "",
        "  generic function state_integer(x) result(n)",
        "    integer(fgs_integer_kinds), intent(in) :: x",
        "    integer :: n",
        "    integer, save :: calls = 0",
        "    calls = calls + 1",
        "    n = calls",
        "  end function",
        "",
        "  generic function id_real(x) result(y)",
        "    real(fgs_real_kinds), intent(in) :: x",
        "    typeof(x) :: y",
        "    y = x",
        "  end function",
        "",
        "  generic function state_real(x) result(n)",
        "    real(fgs_real_kinds), intent(in) :: x",
        "    integer :: n",
        "    integer, save :: calls = 0",
        "    calls = calls + 1",
        "    n = calls",
        "  end function",
        "",
        "  generic function id_complex(x) result(y)",
        "    complex(fgs_real_kinds), intent(in) :: x",
        "    typeof(x) :: y",
        "    y = x",
        "  end function",
        "",
        "  generic function state_complex(x) result(n)",
        "    complex(fgs_real_kinds), intent(in) :: x",
        "    integer :: n",
        "    integer, save :: calls = 0",
        "    calls = calls + 1",
        "    n = calls",
        "  end function",
        "",
        "  generic function id_logical(x) result(y)",
        "    logical(fgs_logical_kinds), intent(in) :: x",
        "    typeof(x) :: y",
        "    y = x",
        "  end function",
        "",
        "  generic function state_logical(x) result(n)",
        "    logical(fgs_logical_kinds), intent(in) :: x",
        "    integer :: n",
        "    integer, save :: calls = 0",
        "    calls = calls + 1",
        "    n = calls",
        "  end function",
        "",
        "  generic function id_character(x) result(y)",
        "    character(len=*, kind=fgs_character_kinds), intent(in) :: x",
        "    character(len=len(x), kind=kind(x)) :: y",
        "    y = x",
        "  end function",
        "",
        "  generic function state_character(x) result(n)",
        "    character(len=*, kind=fgs_character_kinds), intent(in) :: x",
        "    integer :: n",
        "    integer, save :: calls = 0",
        "    calls = calls + 1",
        "    n = calls",
        "  end function",
        "",
        "  generic function state_type(x) result(n)",
        "    type(integer, real, complex, logical), intent(in) :: x",
        "    integer :: n",
        "    integer, save :: calls = 0",
        "    calls = calls + 1",
        "    n = calls",
        "  end function",
        "",
        "  generic function state_rank(x) result(n)",
        "    integer, intent(in), rank(0:1) :: x",
        "    integer :: n",
        "    integer, save :: calls = 0",
        "    calls = calls + 1",
        "    n = calls",
        "  end function",
        "",
        "  generic function state_type_kind_rank(x) result(n)",
        "    type(integer(fgs_integer_kinds), real(fgs_real_kinds), &",
        "         complex(fgs_real_kinds), logical(fgs_logical_kinds), &",
        "         character(*, kind=fgs_character_kinds)), &",
        "         intent(in), rank(0:1) :: x",
        "    integer :: n",
        "    integer, save :: calls = 0",
        "    calls = calls + 1",
        "    n = calls",
        "  end function",
        "end module",
        "",
        "program fgs_generated_processor_kinds",
        "  use fgs_generated_processor_kinds_m",
        "  implicit none",
        ]
    )

    joint_actuals: List[Tuple[str, str]] = []
    for index, kind in enumerate(inventory.integer_kinds, 1):
        lines.append("  integer(kind={}) :: integer_{}".format(kind, index))
        lines.append(
            "  integer(kind={}) :: integer_{}_rank1(2)".format(kind, index)
        )
        joint_actuals.extend(
            [
                ("integer_{}".format(index), "integer-scalar-{}".format(index)),
                (
                    "integer_{}_rank1".format(index),
                    "integer-rank1-{}".format(index),
                ),
            ]
        )
    for index, kind in enumerate(inventory.real_kinds, 1):
        lines.append("  real(kind={}) :: real_{}".format(kind, index))
        lines.append("  real(kind={}) :: real_{}_rank1(2)".format(kind, index))
        lines.append("  complex(kind={}) :: complex_{}".format(kind, index))
        lines.append(
            "  complex(kind={}) :: complex_{}_rank1(2)".format(kind, index)
        )
        joint_actuals.extend(
            [
                ("real_{}".format(index), "real-scalar-{}".format(index)),
                ("real_{}_rank1".format(index), "real-rank1-{}".format(index)),
                (
                    "complex_{}".format(index),
                    "complex-scalar-{}".format(index),
                ),
                (
                    "complex_{}_rank1".format(index),
                    "complex-rank1-{}".format(index),
                ),
            ]
        )
    for index, kind in enumerate(inventory.logical_kinds, 1):
        lines.append("  logical(kind={}) :: logical_{}".format(kind, index))
        lines.append(
            "  logical(kind={}) :: logical_{}_rank1(2)".format(kind, index)
        )
        joint_actuals.extend(
            [
                ("logical_{}".format(index), "logical-scalar-{}".format(index)),
                (
                    "logical_{}_rank1".format(index),
                    "logical-rank1-{}".format(index),
                ),
            ]
        )
    for index, kind in enumerate(inventory.character_kinds, 1):
        lines.append(
            "  character(len=2, kind={}) :: character_{}".format(kind, index)
        )
        lines.append(
            "  character(len=2, kind={}) :: character_{}_rank1(2)".format(
                kind, index
            )
        )
        joint_actuals.extend(
            [
                (
                    "character_{}".format(index),
                    "character-scalar-{}".format(index),
                ),
                (
                    "character_{}_rank1".format(index),
                    "character-rank1-{}".format(index),
                ),
            ]
        )
    lines.extend(
        [
            "  integer :: rank_one(1)",
            "",
            "  rank_one = 1",
        ]
    )

    for index, kind in enumerate(inventory.integer_kinds, 1):
        name = "integer_{}".format(index)
        lines.extend(
            [
                "  {} = int(1, kind={})".format(name, kind),
                "  {0}_rank1 = [{0}, int(0, kind={1})]".format(name, kind),
                "  if (id_integer({0}) /= {0}) error stop 'integer value {1}'".format(
                    name, index
                ),
                "  if (kind(id_integer({})) /= {}) error stop 'integer kind {}'".format(
                    name, kind, index
                ),
                "  if (state_integer({}) /= 1) error stop 'integer state first {}'".format(
                    name, index
                ),
                "  if (state_integer({}) /= 2) error stop 'integer state second {}'".format(
                    name, index
                ),
            ]
        )

    for index, kind in enumerate(inventory.real_kinds, 1):
        real_name = "real_{}".format(index)
        complex_name = "complex_{}".format(index)
        lines.extend(
            [
                "  {0} = real(1, kind={1}) / real(4, kind={1})".format(
                    real_name, kind
                ),
                "  {0}_rank1 = [{0}, real(3, kind={1}) / real(4, kind={1})]".format(
                    real_name, kind
                ),
                "  if (id_real({0}) /= {0}) error stop 'real value {1}'".format(
                    real_name, index
                ),
                "  if (kind(id_real({})) /= {}) error stop 'real kind {}'".format(
                    real_name, kind, index
                ),
                "  if (state_real({}) /= 1) error stop 'real state first {}'".format(
                    real_name, index
                ),
                "  if (state_real({}) /= 2) error stop 'real state second {}'".format(
                    real_name, index
                ),
                "  {0} = cmplx(real(1, kind={1}), -real(1, kind={1}), kind={1})".format(
                    complex_name, kind
                ),
                (
                    "  {0}_rank1 = [{0}, cmplx(real(2, kind={1}), "
                    "real(1, kind={1}), kind={1})]"
                ).format(
                    complex_name, kind
                ),
                "  if (id_complex({0}) /= {0}) error stop 'complex value {1}'".format(
                    complex_name, index
                ),
                "  if (kind(id_complex({})) /= {}) error stop 'complex kind {}'".format(
                    complex_name, kind, index
                ),
                "  if (state_complex({}) /= 1) error stop 'complex state first {}'".format(
                    complex_name, index
                ),
                "  if (state_complex({}) /= 2) error stop 'complex state second {}'".format(
                    complex_name, index
                ),
            ]
        )

    for index, kind in enumerate(inventory.logical_kinds, 1):
        name = "logical_{}".format(index)
        lines.extend(
            [
                "  {} = .true.".format(name),
                "  {}_rank1 = [.true., .false.]".format(name),
                "  if (id_logical({0}) .neqv. {0}) error stop 'logical value {1}'".format(
                    name, index
                ),
                "  if (kind(id_logical({})) /= {}) error stop 'logical kind {}'".format(
                    name, kind, index
                ),
                "  if (state_logical({}) /= 1) error stop 'logical state first {}'".format(
                    name, index
                ),
                "  if (state_logical({}) /= 2) error stop 'logical state second {}'".format(
                    name, index
                ),
            ]
        )

    for index, kind in enumerate(inventory.character_kinds, 1):
        name = "character_{}".format(index)
        lines.extend(
            [
                "  {0} = repeat(char(0, kind={1}), 2)".format(name, kind),
                "  {0}_rank1 = {0}".format(name),
                "  if (id_character({0}) /= {0}) error stop 'character value {1}'".format(
                    name, index
                ),
                "  if (len(id_character({})) /= 2) error stop 'character length {}'".format(
                    name, index
                ),
                "  if (kind(id_character({})) /= {}) error stop 'character kind {}'".format(
                    name, kind, index
                ),
                "  if (state_character({}) /= 1) error stop 'character state first {}'".format(
                    name, index
                ),
                "  if (state_character({}) /= 2) error stop 'character state second {}'".format(
                    name, index
                ),
            ]
        )

    lines.extend(
        [
            "  if (state_type(1) /= 1) error stop 'type integer first'",
            "  if (state_type(1) /= 2) error stop 'type integer second'",
            "  if (state_type(1.0) /= 1) error stop 'type real first'",
            "  if (state_type(1.0) /= 2) error stop 'type real second'",
            "  if (state_type(cmplx(1.0, -1.0)) /= 1) error stop 'type complex first'",
            "  if (state_type(cmplx(1.0, -1.0)) /= 2) error stop 'type complex second'",
            "  if (state_type(.true.) /= 1) error stop 'type logical first'",
            "  if (state_type(.true.) /= 2) error stop 'type logical second'",
            "  if (state_rank(1) /= 1) error stop 'rank scalar first'",
            "  if (state_rank(1) /= 2) error stop 'rank scalar second'",
            "  if (state_rank(rank_one) /= 1) error stop 'rank one first'",
            "  if (state_rank(rank_one) /= 2) error stop 'rank one second'",
        ]
    )
    for actual, label in joint_actuals:
        lines.append(
            "  if (state_type_kind_rank({}) /= 1) "
            "error stop 'joint {} first'".format(actual, label)
        )
    for actual, label in joint_actuals:
        lines.append(
            "  if (state_type_kind_rank({}) /= 2) "
            "error stop 'joint {} second'".format(actual, label)
        )
    lines.extend(
        [
            "  write (*, '(a)') 'FGS-GENERATED-KINDS-PASS'",
            "end program",
            "",
        ]
    )
    return "\n".join(lines), generated_kind_counts(inventory)


def generate_rank_runtime_source(
    inventory: ProcessorInventory, extended_rank: bool
) -> Tuple[str, Dict[str, Any]]:
    if inventory.max_rank is None:
        raise ValueError("MAX_RANK inventory is unavailable")
    if inventory.max_rank < 0:
        raise ValueError("MAX_RANK returned a negative value")
    if inventory.max_rank <= 15:
        exercised_rank = inventory.max_rank
        rank_expression = "max_rank()"
        interpretation = None
    elif extended_rank:
        exercised_rank = inventory.max_rank
        rank_expression = "max_rank()"
        interpretation = "extended-rank-limit"
    else:
        exercised_rank = min(15, inventory.max_rank)
        rank_expression = "min(15, max_rank())"
        interpretation = None
    if exercised_rank < 1:
        raise ValueError("processor maximum rank is below one")

    called_ranks = list(range(exercised_rank + 1))
    rank_list = ",".join(str(rank) for rank in called_ranks)
    expected_output_lines = [
        "FGS-GENERATED-RANK-PASS",
        "FGS-GENERATED-RANK-COUNT {}".format(len(called_ranks)),
        "FGS-GENERATED-RANKS {}".format(rank_list),
    ]
    lines: List[str] = [
        "module fgs_generated_processor_rank_m",
        "  use, intrinsic :: iso_fortran_env, only: max_rank",
        "  implicit none",
        "contains",
        "  generic subroutine probe_rank(x, observed_rank, observed_size, &",
        "                                observed_sum, observed_calls)",
        "    integer, intent(in), rank(0:{}) :: x".format(rank_expression),
        "    integer, intent(out) :: observed_rank, observed_size",
        "    integer, intent(out) :: observed_sum, observed_calls",
        "    integer :: dimension",
        "    integer, save :: calls = 0",
        "    calls = calls + 1",
        "    observed_rank = rank(x)",
        "    observed_calls = calls",
        "    select generic rank (x)",
        "    rank (0)",
        "      observed_size = 1",
        "      observed_sum = x",
        "    rank default",
        "      observed_size = size(x)",
        "      observed_sum = sum(x)",
        "      if (maxval(x) /= 1) error stop 'rank maximum value'",
        "      if (minval(x) /= -1) error stop 'rank minimum value'",
        "      if (size(x, dim=1) /= 2) error stop 'rank first extent'",
        "      do dimension = 2, rank(x)",
        "        if (size(x, dim=dimension) /= 1) &",
        "          error stop 'rank trailing extent'",
        "      end do",
        "    end select",
        "  end subroutine",
        "end module",
        "",
        "program fgs_generated_processor_rank",
        "  use, intrinsic :: iso_fortran_env, only: max_rank",
        "  use fgs_generated_processor_rank_m",
        "  implicit none",
        "  integer, parameter :: exercised_rank = {}".format(rank_expression),
        "  integer :: observed_rank, observed_size, observed_sum, observed_calls",
    ]
    for rank in called_ranks:
        lines.append(
            "  integer, allocatable, rank({}) :: value_{}".format(rank, rank)
        )
    lines.extend(
        [
            "",
            "  if (max_rank() /= {}) error stop 'MAX_RANK changed after inventory'".format(
                inventory.max_rank
            ),
            "  if (exercised_rank /= {}) error stop 'exercised rank mismatch'".format(
                exercised_rank
            ),
            "  allocate(value_0)",
            "  value_0 = 1",
        ]
    )
    for rank in called_ranks[1:]:
        shape = [2] + [1] * (rank - 1)
        dimensions = ", ".join(str(extent) for extent in shape)
        lines.extend(
            [
                "  allocate(value_{}({}))".format(rank, dimensions),
                "  value_{0} = reshape([1, -1], [{1}])".format(
                    rank, dimensions
                ),
            ]
        )
    for calls in (1, 2):
        for rank in called_ranks:
            expected_size = 1 if rank == 0 else 2
            expected_sum = 1 if rank == 0 else 0
            lines.extend(
                [
                    "  call probe_rank(value_{}, observed_rank, observed_size, &".format(
                        rank
                    ),
                    "                  observed_sum, observed_calls)",
                    "  if (observed_rank /= {}) "
                    "error stop 'rank {} observed rank call {}'".format(
                        rank, rank, calls
                    ),
                    "  if (observed_size /= {}) "
                    "error stop 'rank {} observed size call {}'".format(
                        expected_size, rank, calls
                    ),
                    "  if (observed_sum /= {}) "
                    "error stop 'rank {} observed sum call {}'".format(
                        expected_sum, rank, calls
                    ),
                    "  if (observed_calls /= {}) "
                    "error stop 'rank {} observed calls {}'".format(
                        calls, rank, calls
                    ),
                ]
            )
    lines.extend(
        [
            "  write (*, '(a)') 'FGS-GENERATED-RANK-PASS'",
            "  write (*, '(a)') 'FGS-GENERATED-RANK-COUNT {}'".format(
                len(called_ranks)
            ),
            "  write (*, '(a)') 'FGS-GENERATED-RANKS {}'".format(rank_list),
            "end program",
            "",
        ]
    )
    source = "\n".join(lines)
    details: Dict[str, Any] = {
        "processor_max_rank": inventory.max_rank,
        "processor_max_rank_corank_1": inventory.max_rank_corank_1,
        "exercised_rank": exercised_rank,
        "rank_expression": rank_expression,
        "portable_c826_bound": 15,
        "draft_interpretation": interpretation,
        "called_ranks": called_ranks,
        "distinct_ranks_called": len(called_ranks),
        "generic_runtime_calls": 2 * len(called_ranks),
        "expected_output_lines": expected_output_lines,
    }
    return source, details


def generation_manifest(
    inventory: ProcessorInventory,
    kind_counts: Dict[str, int],
    rank_details: Optional[Dict[str, Any]],
) -> Dict[str, Any]:
    return {
        "schema_version": 1,
        "inventory": inventory.to_dict(),
        "generated_cases": {
            "processor_kinds": {
                "source": "processor_kinds_generated.f90",
                "counts": dict(kind_counts),
            },
            "processor_rank": (
                None
                if rank_details is None
                else {
                    "source": "processor_rank_generated.f90",
                    "details": dict(rank_details),
                }
            ),
        },
    }
