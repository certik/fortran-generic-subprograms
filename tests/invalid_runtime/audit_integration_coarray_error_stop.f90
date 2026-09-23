! TEST-RULE: 5.3.6 5.3.7 11.4 11.7.3 11.7.11 15.6.2.4 17.10.2.38 17.10.2.41
! TEST-IMAGES: 2
! TEST-STOP-IMAGE: 1
! TEST-STOP: coarray-rank-specialization
! After an initial SYNC ALL, image 1 calls the rank-two coarray specific,
! which prints the marker, flushes, and initiates error termination; image 2
! calls the rank-one specific and waits in a final SYNC ALL that image 1
! never reaches. Error termination is then initiated on every image
! (5.3.7 p1), so no image prints the unexpected-return marker. The runner's
! selected-image calibration for TEST-STOP-IMAGE mirrors this topology.
! The final SYNC ALL has STAT= so that an ERROR STOP implemented as normal
! termination cannot be masked: image 1 would then be a stopped image
! (5.3.6), image 2 would receive STAT_STOPPED_IMAGE and continue
! (11.7.11 p5-p6), and it prints and flushes the unexpected-return marker.
! Without STAT=, image 2 would instead initiate error termination itself
! (11.7.11 p11). A status of zero or STAT_FAILED_IMAGE also proves that image
! 1 did not initiate error termination (5.3.6), so it is reported the same
! way. Any other status is a processor-dependent error condition
! (11.7.11 p13) that can reflect error termination still propagating
! (5.3.7 p3). It proves neither conformance nor a violation, so image 2
! prints and flushes an explicit inconclusive line, which the runner never
! credits as a pass, and only then waits in a SYNC ALL without STAT= so the
! images can finish.
module audit_integration_coarray_error_stop_m
  use, intrinsic :: iso_fortran_env, only: output_unit
  implicit none
contains
  generic subroutine require_vector(x)
    integer, intent(in), rank(1:2) :: x[*]
    select generic rank (x)
    rank (1)
      if (any(x < 0)) error stop "unreachable vector error"
    rank (2)
      print '(a)', 'TEST-STOP: coarray-rank-specialization'
      flush(output_unit)
      error stop "rank-two coarray specialization rejected"
    end select
  end subroutine
end module

program audit_integration_coarray_error_stop_p
  use, intrinsic :: iso_fortran_env, only: output_unit, stat_failed_image, &
    stat_stopped_image
  use audit_integration_coarray_error_stop_m, only: require_vector
  implicit none
  integer :: vector(2)[*]
  integer :: matrix(2, 2)[*]
  integer :: sync_status
  if (num_images() /= 2) error stop "requires exactly two images"
  vector = this_image()
  matrix = this_image()
  sync all
  if (this_image() == 1) then
    call require_vector(matrix)
  else
    call require_vector(vector)
  end if
  sync all (stat=sync_status)
  if (sync_status == 0 .or. sync_status == stat_stopped_image .or. &
      sync_status == stat_failed_image) then
    print '(a,i0)', 'coarray-rank-specialization final SYNC ALL STAT=', sync_status
    print '(a)', 'TEST-UNEXPECTED-RETURN: coarray-rank-specialization'
    flush(output_unit)
  else
    print '(a,i0)', 'TEST-INCONCLUSIVE: coarray-sync-status ', sync_status
    flush(output_unit)
    sync all
  end if
end program
