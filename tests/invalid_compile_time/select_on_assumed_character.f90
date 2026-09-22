! Invalid: C1159. CHARACTER(LEN=*) is ordinary assumed-length character,
! not a type-generic dummy. The same spelling matches generic-intrinsic-type-spec;
! that parse is not used, so existing assumed-length declarations stay valid.
module select_on_assumed_character_m
  implicit none
contains
  generic subroutine s(x)
    character(len=*) :: x
    select generic type (x)
    declared type is (character(len=*))
      x = ""
    end select
  end subroutine
end module
