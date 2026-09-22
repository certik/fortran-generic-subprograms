! Invalid: C15137. An elemental dummy without VALUE needs an intent.
module elemental_missing_intent_m
  implicit none
contains
  elemental generic function f(x) result(y)
    integer :: x
    integer :: y
    y = x
  end function
end module
