! Invalid: C1510. MODULE PROCEDURE shall not name a generic.
module module_procedure_generic_m
  implicit none
  interface operator(+)
    module procedure add
  end interface
contains
  generic function add(a, b) result(c)
    type(integer, real), intent(in) :: a
    typeof(a), intent(in) :: b
    typeof(a) :: c
    c = a + b
  end function
end module
