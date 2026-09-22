! TEST-RULE: R708 R710 R711 C718 C1159 R1157
! TEST-DRAFT: character-generic-parse
! CHARACTER(LEN=*) without a kind array has both the long-standing ordinary
! parse and the new generic-character parse. This test intentionally depends
! on the generic parse and is therefore never an untagged conformance oracle.
module language_character_generic_parse_m
  implicit none
contains
  generic function parsed_as_generic(s) result(n)
    character(len=*), intent(in) :: s
    integer :: n
    select generic type (s)
    declared type default
      n = len(s)
    end select
  end function
end module

program language_character_generic_parse_p
  use language_character_generic_parse_m
  implicit none
  if (parsed_as_generic("parse") /= 5) error stop "character generic parse"
end program
