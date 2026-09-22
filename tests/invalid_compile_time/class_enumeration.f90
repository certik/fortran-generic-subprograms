! TEST-RULE: C715
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C715|CLASS.*extensible|enumeration.*not extensible
! TEST-ERROR-PHASE: compile
! Invalid: C715. Enumeration types are not extensible, so they cannot appear
! in CLASS(...).
module class_enumeration_m
  implicit none
  enumeration type :: colour
    enumerator :: red, green
  end enumeration type
  enumeration type :: fruit
    enumerator :: apple, pear
  end enumeration type
contains
  generic subroutine s(x)
      ! TEST-ERROR-HERE
      class(colour, fruit) :: x
    end subroutine
  end module
