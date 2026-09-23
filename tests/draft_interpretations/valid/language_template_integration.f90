! TEST-RULE: C1582 R1601 R1602 R1608 R1625 15.6.2.4 16.1 16.5.1
! TEST-DRAFT: template-integration
! TEST-PASS: language_template_integration
! R1608 admits ordinary function/subroutine subprograms in a TEMPLATE
! subprogram part, while C1582 describes a generic subprogram as module or
! internal. This grounded interaction is quarantined until that context is
! resolved; it does not assert an unqualified normative outcome.
program language_template_integration_p
  implicit none
  template identity_template()
    public :: identity
  contains
    generic function identity(x) result(y)
      type(integer, real), intent(in) :: x
      typeof(x) :: y
      y = x
    end function
  end template
  instantiate identity_template {}

  if (identity(7) /= 7) error stop "template generic integer"
  if (identity(2.5) /= 2.5) error stop "template generic real"
  print '(a)', 'TEST-PASS: language_template_integration'
end program
