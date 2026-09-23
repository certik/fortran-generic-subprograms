program audit_integration_separate_io_singleton_p
  use audit_integration_separate_io_singleton_m
  implicit none
  type(box) :: item, copy
  character(len=32) :: line
  integer :: unit, status, raw

  item = 4
  if (item%n /= 40) error stop "MODULE GENERIC defined assignment"
  write(line, '(dt)') item
  if (adjustl(line) /= 'BOX 40') error stop "formatted defined output"
  line = 'BOX 73'
  read(line, '(dt)') copy
  if (copy%n /= 73) error stop "formatted defined input"

  open(newunit=unit, status='scratch', form='unformatted', action='readwrite')
  write(unit) item
  rewind(unit)
  read(unit) raw
  if (raw /= -40) error stop "unformatted defined output record"
  rewind(unit)
  read(unit) copy
  if (copy%n /= 40) error stop "unformatted defined input"
  close(unit, iostat=status)
  if (status /= 0) error stop "scratch close"
  print '(a)', 'TEST-PASS: audit-integration-separate-io-singleton'
end program
