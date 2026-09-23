program audit_integration_separate_save_state_p
  use audit_integration_separate_save_state_caller_one_m
  use audit_integration_separate_save_state_caller_two_m
  implicit none
  if (one_integer(1) /= 1) error stop "integer scalar, first object"
  if (two_integer() /= 2) error stop "integer scalar through renamed re-export"
  if (one_integer(3) /= 3) error stop "integer scalar state continues"
  if (two_integer_vector() /= 1) error stop "integer vector is a separate specific"
  if (one_integer_vector() /= 2) error stop "integer vector shared across objects"
  if (two_real() /= 1) error stop "real scalar is a separate specific"
  if (one_real() /= 2) error stop "real scalar shared across objects"
  if (one_real_vector() /= 1) error stop "real vector is a separate specific"
  if (two_real_vector() /= 2) error stop "real vector shared across objects"
  if (one_complex() /= 501) error stop "second generated contribution"
  if (two_complex() /= 502) error stop "second generated contribution shared"
  if (two_logical() /= 101) error stop "ordinary contribution through re-export"
  if (one_logical() /= 102) error stop "ordinary contribution shared"
  if (two_text('ab') /= 1021) error stop "re-export's own ordinary specific"
  if (two_text('xyz') /= 1032) error stop "re-export's own ordinary state"
  if (one_integer(9) /= 4) error stop "integer state after all calls"
  if (two_integer() /= 5) error stop "final integer state through alias"
  print '(a)', 'TEST-PASS: audit-integration-separate-save-state'
end program
