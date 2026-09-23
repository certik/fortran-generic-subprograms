! TEST-PASS: audit-language-save-identity
! TEST-RULE: 7.2 8.5.18 8.6.7 15.6.2.4 15.6.2.5
! Explicit SAVE, declaration initialization, DATA initialization, saved
! allocatable state, and saved pointer state follow the complete identity key.
! Character/PDT length, shape, bounds, and polymorphic dynamic type do not
! create additional specifics or additional saved state.
module audit_language_save_identity_m
  implicit none

  type :: base
    integer :: value
  end type

  type, extends(base) :: child
    integer :: extra
  end type

  type :: keyed(k1, k2, n)
    integer, kind :: k1, k2
    integer, len :: n
    integer :: values(n)
  end type
contains
  generic subroutine independent_state(x, y, counts, payload)
    type(integer, real), intent(in) :: x
    integer, rank(0:1), intent(in) :: y
    integer, intent(out) :: counts(5), payload
    integer, save :: explicit_hits = 0
    integer :: initialized_hits = 0
    integer :: data_hits
    integer, allocatable, save :: alloc_hits
    integer, pointer, save :: pointer_hits => null()
    data data_hits /0/

    if (.not. allocated(alloc_hits)) allocate(alloc_hits, source=0)
    if (.not. associated(pointer_hits)) allocate(pointer_hits, source=0)
    explicit_hits = explicit_hits + 1
    initialized_hits = initialized_hits + 1
    data_hits = data_hits + 1
    alloc_hits = alloc_hits + 1
    pointer_hits = pointer_hits + 1
    counts = [explicit_hits, initialized_hits, data_hits, alloc_hits, pointer_hits]

    select generic type (x)
    declared type is (integer)
      select generic rank (y)
      rank (0)
        payload = x + y
      rank (1)
        payload = x + sum(y)
      end select
    declared type is (real)
      select generic rank (y)
      rank (0)
        payload = nint(10.0*x) + y
      rank (1)
        payload = nint(10.0*x) + sum(y)
      end select
    end select
  end subroutine

  generic subroutine character_state(x, hits, payload)
    character(len=*), rank(0:1), intent(in) :: x
    integer, intent(out) :: hits, payload
    integer, save :: local_hits = 0

    local_hits = local_hits + 1
    hits = local_hits
    select generic rank (x)
    rank (0)
      payload = len_trim(x)
    rank (1)
      payload = sum(len_trim(x))
    end select
  end subroutine

  generic subroutine pdt_state(x, hits, payload)
    type(keyed(k1=[0, 1], k2=[-2, 3], n=*)), intent(in) :: x
    integer, intent(out) :: hits, payload
    integer, save :: local_hits = 0

    local_hits = local_hits + 1
    hits = local_hits
    payload = sum(x%values)
  end subroutine

  generic subroutine dynamic_state(x, hits, payload)
    class(base), rank(0:1), intent(in) :: x
    integer, intent(out) :: hits, payload
    integer, save :: local_hits = 0

    local_hits = local_hits + 1
    hits = local_hits
    select generic rank (x)
    rank (0)
      select type (x)
      type is (base)
        payload = x%value
      type is (child)
        payload = x%value + x%extra
      class default
        error stop "unexpected scalar dynamic type"
      end select
    rank (1)
      select type (x)
      type is (base)
        payload = sum(x%value)
      type is (child)
        payload = sum(x%value) + sum(x%extra)
      class default
        error stop "unexpected array dynamic type"
      end select
    end select
  end subroutine
end module

program audit_language_save_identity_p
  use audit_language_save_identity_m
  implicit none
  integer :: counts(5), payload, hits
  integer :: short_vector(-1:0), long_vector(5:7), real_vector(-2:1)
  character(len=3) :: short_text
  character(len=7) :: long_text
  character(len=2) :: short_words(-1:0)
  character(len=5) :: long_words(4:6)
  type(keyed(k1=0, k2=-2, n=1)) :: p00a
  type(keyed(k1=0, k2=-2, n=3)) :: p00b
  type(keyed(k1=0, k2=3, n=1)) :: p01a
  type(keyed(k1=0, k2=3, n=3)) :: p01b
  type(keyed(k1=1, k2=-2, n=1)) :: p10a
  type(keyed(k1=1, k2=-2, n=3)) :: p10b
  type(keyed(k1=1, k2=3, n=1)) :: p11a
  type(keyed(k1=1, k2=3, n=3)) :: p11b
  type(base) :: bscalar, barray(-1:0)
  type(child) :: cscalar, carray(3:5)

  short_vector = [2, 3]
  long_vector = [1, 2, 3]
  real_vector = [1, 2, 3, 4]

  call independent_state(3, 4, counts, payload)
  call check_state(counts, payload, 1, 7)
  call independent_state(1.5, real_vector(-2:-1), counts, payload)
  call check_state(counts, payload, 1, 18)
  call independent_state(5, short_vector, counts, payload)
  call check_state(counts, payload, 1, 10)
  call independent_state(2.5, 4, counts, payload)
  call check_state(counts, payload, 1, 29)
  call independent_state(6, long_vector, counts, payload)
  call check_state(counts, payload, 2, 12)
  call independent_state(7, 8, counts, payload)
  call check_state(counts, payload, 2, 15)
  call independent_state(3.5, 2, counts, payload)
  call check_state(counts, payload, 2, 37)
  call independent_state(0.5, real_vector, counts, payload)
  call check_state(counts, payload, 2, 15)

  short_text = "cat"
  long_text = "giraffe"
  short_words = ["a ", "bb"]
  long_words = ["c    ", "dddd ", "eeeee"]
  call character_state(short_text, hits, payload)
  if (hits /= 1 .or. payload /= 3) error stop "character scalar first length"
  call character_state(long_text, hits, payload)
  if (hits /= 2 .or. payload /= 7) error stop "character scalar second length"
  call character_state(short_words, hits, payload)
  if (hits /= 1 .or. payload /= 3) error stop "character array first shape"
  call character_state(long_words, hits, payload)
  if (hits /= 2 .or. payload /= 10) error stop "character array second shape"

  p00a%values = [1]
  p00b%values = [2, 3, 4]
  p01a%values = [5]
  p01b%values = [6, 7, 8]
  p10a%values = [9]
  p10b%values = [10, 11, 12]
  p11a%values = [13]
  p11b%values = [14, 15, 16]
  call pdt_state(p00a, hits, payload)
  if (hits /= 1 .or. payload /= 1) error stop "PDT 0,-2 first"
  call pdt_state(p11a, hits, payload)
  if (hits /= 1 .or. payload /= 13) error stop "PDT 1,3 first"
  call pdt_state(p01a, hits, payload)
  if (hits /= 1 .or. payload /= 5) error stop "PDT 0,3 first"
  call pdt_state(p10a, hits, payload)
  if (hits /= 1 .or. payload /= 9) error stop "PDT 1,-2 first"
  call pdt_state(p10b, hits, payload)
  if (hits /= 2 .or. payload /= 33) error stop "PDT 1,-2 second length"
  call pdt_state(p00b, hits, payload)
  if (hits /= 2 .or. payload /= 9) error stop "PDT 0,-2 second length"
  call pdt_state(p11b, hits, payload)
  if (hits /= 2 .or. payload /= 45) error stop "PDT 1,3 second length"
  call pdt_state(p01b, hits, payload)
  if (hits /= 2 .or. payload /= 21) error stop "PDT 0,3 second length"

  bscalar%value = 4
  cscalar%value = 5
  cscalar%extra = 6
  barray%value = [1, 2]
  carray%value = [3, 4, 5]
  carray%extra = [6, 7, 8]
  call dynamic_state(bscalar, hits, payload)
  if (hits /= 1 .or. payload /= 4) error stop "base scalar state"
  call dynamic_state(cscalar, hits, payload)
  if (hits /= 2 .or. payload /= 11) error stop "child scalar shares state"
  call dynamic_state(barray, hits, payload)
  if (hits /= 1 .or. payload /= 3) error stop "base array state"
  call dynamic_state(carray, hits, payload)
  if (hits /= 2 .or. payload /= 33) error stop "child array shares state"

  print '(a)', 'TEST-PASS: audit-language-save-identity'
contains
  subroutine check_state(actual_counts, actual_payload, expected_hit, expected_payload)
    integer, intent(in) :: actual_counts(5), actual_payload, expected_hit, expected_payload
    if (any(actual_counts /= expected_hit)) error stop "saved state category mismatch"
    if (actual_payload /= expected_payload) error stop "saved state payload mismatch"
  end subroutine
end program
