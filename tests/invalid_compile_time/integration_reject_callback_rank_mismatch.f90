! TEST-RULE: 15.5.2.10 15.5.5.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: (dummy|actual) procedure.*(interface|characteristic|rank)|interface.*(mismatch|does not match|incompatible)|characteristics.*(differ|mismatch)|no (matching )?specific (function|procedure|subroutine)|matches the actual arguments
! TEST-ERROR-PHASE: compile
! The rank-two data argument selects the rank-two specific, whose callback
! interface has a rank-two dummy. The rank-one actual procedure therefore
! does not have the required characteristics (15.5.2.10 p1).
module integration_reject_callback_rank_mismatch_m
  implicit none
contains
  generic subroutine transform(x, action)
    integer, intent(inout), rank(1:2) :: x
    interface
      subroutine action(a)
        import :: x
        typeof(x), intent(inout), rank(rank(x)) :: a
      end subroutine
    end interface
    call action(x)
  end subroutine
end module

program integration_reject_callback_rank_mismatch_p
  use integration_reject_callback_rank_mismatch_m
  implicit none
  integer :: matrix(2, 2)
  matrix = 1
  ! TEST-ERROR-HERE
  call transform(matrix, negate_vector)
contains
  subroutine negate_vector(a)
    integer, intent(inout) :: a(:)
    a = -a
  end subroutine
end program
