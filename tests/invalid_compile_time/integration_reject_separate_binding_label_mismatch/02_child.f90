submodule (integration_reject_separate_binding_label_mismatch_m) &
    integration_reject_separate_binding_label_mismatch_s
  implicit none
contains
  ! TEST-ERROR-HERE
  module generic function stamp(x) result(y) bind(c, name="fgs_integration_stamp_definition")
    integer(c_int), value :: x
    integer(c_int) :: y
    y = x + 1_c_int
  end function
end submodule
