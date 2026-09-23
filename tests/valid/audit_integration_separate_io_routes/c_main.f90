program audit_integration_separate_io_routes_p
  use audit_integration_separate_io_routes_m
  implicit none
  type(box) :: bx, bx2
  type(bag) :: bg, bg2
  character(len=32) :: line
  integer :: unit, tag, value

  bx = 4
  bg = 5
  bx2 = 2.6
  bg2 = 1.4
  if (bx%n /= 4 .or. bg%n /= 1005) error stop "integer assignment specifics"
  if (bx2%n /= -3 .or. bg2%n /= 999) error stop "real assignment specifics"

  write(line, '(dt)') bx
  if (adjustl(line) /= 'BOX 4') error stop "box formatted output"
  write(line, '(dt)') bg
  if (adjustl(line) /= 'BAG 1005') error stop "bag formatted output"
  line = 'BOX 17'
  read(line, '(dt)') bx2
  if (bx2%n /= 17) error stop "box formatted input"
  line = 'BAG 23'
  read(line, '(dt)') bg2
  if (bg2%n /= 23) error stop "bag formatted input"

  open(newunit=unit, status='scratch', form='unformatted', action='readwrite')
  write(unit) bx
  write(unit) bg
  rewind(unit)
  read(unit) tag, value
  if (tag /= 1 .or. value /= 4) error stop "box unformatted record"
  read(unit) tag, value
  if (tag /= 2 .or. value /= 1005) error stop "bag unformatted record"
  rewind(unit)
  read(unit) bx2
  read(unit) bg2
  close(unit)
  if (bx2%n /= 4 .or. bg2%n /= 1005) error stop "unformatted defined input"
  print '(a)', 'TEST-PASS: audit-integration-separate-io-routes'
end program
