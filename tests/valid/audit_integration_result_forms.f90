! TEST-RULE: C709 C877 7.3.2.1 8.5.8.2 8.5.17 10.1.11 15.3.3 15.6.2.4
! TEST-PASS: audit-integration-result-forms
! Nonallocatable explicit-shape and automatic array results, PDT results
! whose length follows the generated dummy, polymorphic CLASSOF results, and
! procedure-pointer results take their characteristics from each selected
! specific. Plain results use array specifications, never a RANK clause
! (C877). Every declared combination is referenced.
module audit_integration_result_forms_m
  use, intrinsic :: iso_fortran_env, only: single_precision, double_precision
  implicit none
  private
  public :: buffer, shape_base, shape_child, token_base, token_child
  public :: extents_of, flattened, paired, framed, widened
  public :: clone, declared_code, chooser
  public :: negate_integer, negate_single, negate_double

  type :: buffer(k, n)
    integer, kind :: k
    integer, len :: n
    real(k) :: values(n)
  end type

  type :: shape_base
    integer :: id = 0
  end type
  type, extends(shape_base) :: shape_child
    integer :: extra = 0
  end type
  type :: token_base
    integer :: weight = 0
  end type
  type, extends(token_base) :: token_child
    integer :: bonus = 0
  end type
contains
  generic function extents_of(x) result(extents)
    type(integer, real), intent(in), rank(1:3) :: x
    integer :: extents(rank(x))
    extents = shape(x)
  end function

  generic function flattened(x) result(flat)
    type(integer, real), intent(in), rank(1:3) :: x
    typeof(x) :: flat(size(x))
    flat = reshape(x, [size(x)])
  end function

  generic function paired(x) result(table)
    type(integer, real), intent(in), rank(0:2) :: x
    typeof(x) :: table(2, product(shape(x)))
    table(1, :) = [x]
    table(2, :) = 2*table(1, :)
  end function

  generic function framed(x, edge) result(y)
    type(integer, real), intent(in) :: x(:)
    typeof(x), intent(in) :: edge
    typeof(x) :: y(0:size(x) + 1)
    y(0) = edge
    y(1:size(x)) = x
    y(size(x) + 1) = edge
  end function

  generic function widened(x, extra) result(y)
    type(buffer(k=[single_precision, double_precision], n=*)), intent(in) :: x
    integer, intent(in) :: extra
    type(buffer(k=x%k, n=x%n + extra)) :: y
    y%values(1:x%n) = x%values
    y%values(x%n + 1:) = -1
  end function

  generic function clone(x) result(y)
    class(shape_base, token_base), intent(in), rank(0:1) :: x
    classof(x), allocatable, rank(rank(x)) :: y
    allocate(y, source=x)
  end function

  generic function declared_code(x) result(code)
    class(shape_base, token_base), intent(in), rank(0:1) :: x
    integer :: code
    select generic type (x)
    declared type is (shape_base)
      code = 10 + rank(x)
    declared type is (token_base)
      code = 20 + rank(x)
    end select
  end function

  generic function chooser(x) result(op)
    type(integer, real([single_precision, double_precision])), intent(in) :: x
    abstract interface
      function unary(a) result(b)
        import :: x
        typeof(x), intent(in) :: a
        typeof(x) :: b
      end function
    end interface
    procedure(unary), pointer :: op
    select generic type (x)
    declared type is (integer)
      op => negate_integer
    declared type is (real(single_precision))
      op => negate_single
    declared type is (real(double_precision))
      op => negate_double
    end select
  end function

  function negate_integer(a) result(b)
    integer, intent(in) :: a
    integer :: b
    b = -a
  end function

  function negate_single(a) result(b)
    real(single_precision), intent(in) :: a
    real(single_precision) :: b
    b = -a
  end function

  function negate_double(a) result(b)
    real(double_precision), intent(in) :: a
    real(double_precision) :: b
    b = -a
  end function
end module

program audit_integration_result_forms_p
  use, intrinsic :: iso_fortran_env, only: single_precision, double_precision
  use audit_integration_result_forms_m
  implicit none
  abstract interface
    function integer_unary(a) result(b)
      integer, intent(in) :: a
      integer :: b
    end function
    function single_unary(a) result(b)
      import :: single_precision
      real(single_precision), intent(in) :: a
      real(single_precision) :: b
    end function
    function double_unary(a) result(b)
      import :: double_precision
      real(double_precision), intent(in) :: a
      real(double_precision) :: b
    end function
  end interface
  integer :: i
  integer :: iv(3), im(2, 3), ic(2, 1, 2)
  real :: rv(2), rm(3, 2), rc(1, 2, 2)
  integer, allocatable :: iextent(:), iflat(:), itable(:, :)
  real, allocatable :: rflat(:), rtable(:, :)
  type(buffer(single_precision, 3)) :: bs
  type(buffer(double_precision, 2)) :: bd
  type(buffer(single_precision, :)), allocatable :: ws
  type(buffer(double_precision, :)), allocatable :: wd
  type(shape_child) :: child_shape
  type(shape_base) :: plain_shapes(3)
  type(token_child) :: child_tokens(2)
  type(token_base) :: plain_token
  class(shape_base), allocatable :: shape_one, shape_many(:)
  class(token_base), allocatable :: token_one, token_many(:)
  procedure(integer_unary), pointer :: integer_op
  procedure(single_unary), pointer :: single_op
  procedure(double_unary), pointer :: double_op

  iv = [4, 5, 6]
  im = reshape([(i, i=1, 6)], [2, 3])
  ic = reshape([11, 12, 13, 14], [2, 1, 2])
  rv = [0.5, 1.5]
  rm = reshape([(real(i), i=1, 6)], [3, 2])
  rc = reshape([2.5, 3.5, 4.5, 5.5], [1, 2, 2])

  iextent = extents_of(iv)
  if (size(iextent) /= 1 .or. any(iextent /= [3])) error stop "integer rank1 extents"
  iextent = extents_of(im)
  if (size(iextent) /= 2 .or. any(iextent /= [2, 3])) error stop "integer rank2 extents"
  iextent = extents_of(ic)
  if (size(iextent) /= 3 .or. any(iextent /= [2, 1, 2])) then
    error stop "integer rank3 extents"
  end if
  iextent = extents_of(rv)
  if (size(iextent) /= 1 .or. any(iextent /= [2])) error stop "real rank1 extents"
  iextent = extents_of(rm)
  if (size(iextent) /= 2 .or. any(iextent /= [3, 2])) error stop "real rank2 extents"
  iextent = extents_of(rc)
  if (size(iextent) /= 3 .or. any(iextent /= [1, 2, 2])) then
    error stop "real rank3 extents"
  end if

  iflat = flattened(iv(3:1:-1))
  if (size(iflat) /= 3 .or. any(iflat /= [6, 5, 4])) error stop "integer rank1 automatic"
  iflat = flattened(im)
  if (size(iflat) /= 6 .or. any(iflat /= [1, 2, 3, 4, 5, 6])) then
    error stop "integer rank2 automatic"
  end if
  iflat = flattened(ic)
  if (size(iflat) /= 4 .or. any(iflat /= [11, 12, 13, 14])) then
    error stop "integer rank3 automatic"
  end if
  rflat = flattened(rv)
  if (size(rflat) /= 2 .or. any(rflat /= [0.5, 1.5])) error stop "real rank1 automatic"
  rflat = flattened(rm(1:3:2, :))
  if (size(rflat) /= 4 .or. any(rflat /= [1.0, 3.0, 4.0, 6.0])) then
    error stop "real rank2 automatic section"
  end if
  rflat = flattened(rc)
  if (size(rflat) /= 4 .or. any(rflat /= [2.5, 3.5, 4.5, 5.5])) then
    error stop "real rank3 automatic"
  end if

  itable = paired(9)
  if (any(shape(itable) /= [2, 1]) .or. any(itable(:, 1) /= [9, 18])) then
    error stop "integer scalar two-row result"
  end if
  itable = paired(iv)
  if (any(shape(itable) /= [2, 3])) error stop "integer rank1 two-row shape"
  if (any(itable(1, :) /= [4, 5, 6]) .or. any(itable(2, :) /= [8, 10, 12])) then
    error stop "integer rank1 two-row values"
  end if
  itable = paired(im)
  if (any(shape(itable) /= [2, 6])) error stop "integer rank2 two-row shape"
  if (any(itable(2, :) /= [2, 4, 6, 8, 10, 12])) error stop "integer rank2 two-row values"
  rtable = paired(0.25)
  if (any(shape(rtable) /= [2, 1]) .or. any(rtable(:, 1) /= [0.25, 0.5])) then
    error stop "real scalar two-row result"
  end if
  rtable = paired(rv)
  if (any(shape(rtable) /= [2, 2]) .or. any(rtable(2, :) /= [1.0, 3.0])) then
    error stop "real rank1 two-row result"
  end if
  rtable = paired(rm)
  if (any(shape(rtable) /= [2, 6])) error stop "real rank2 two-row shape"
  if (any(rtable(1, :) /= [1.0, 2.0, 3.0, 4.0, 5.0, 6.0])) then
    error stop "real rank2 two-row values"
  end if

  iflat = framed(iv, -1)
  if (size(iflat) /= 5 .or. any(iflat /= [-1, 4, 5, 6, -1])) then
    error stop "integer framed automatic bounds"
  end if
  rflat = framed(rv(2:1:-1), 9.0)
  if (size(rflat) /= 4 .or. any(rflat /= [9.0, 1.5, 0.5, 9.0])) then
    error stop "real framed automatic bounds"
  end if

  bs%values = [1.0_single_precision, 2.0_single_precision, 3.0_single_precision]
  bd%values = [7.0_double_precision, 8.0_double_precision]
  ws = widened(bs, 2)
  if (ws%n /= 5 .or. size(ws%values) /= 5) error stop "single PDT result length"
  if (any(ws%values /= [1.0_single_precision, 2.0_single_precision, &
      3.0_single_precision, -1.0_single_precision, -1.0_single_precision])) then
    error stop "single PDT result values"
  end if
  wd = widened(bd, 1)
  if (wd%n /= 3 .or. size(wd%values) /= 3) error stop "double PDT result length"
  if (any(wd%values /= [7.0_double_precision, 8.0_double_precision, &
      -1.0_double_precision])) error stop "double PDT result values"
  wd = widened(bd, 0)
  if (wd%n /= 2 .or. any(wd%values /= bd%values)) error stop "double PDT zero extension"

  child_shape = shape_child(id=4, extra=40)
  plain_shapes = [shape_base(1), shape_base(2), shape_base(3)]
  child_tokens = [token_child(weight=5, bonus=50), token_child(weight=6, bonus=60)]
  plain_token = token_base(weight=8)

  allocate(shape_one, source=clone(child_shape))
  select type (shape_one)
  type is (shape_child)
    if (shape_one%id /= 4 .or. shape_one%extra /= 40) error stop "scalar shape clone data"
  class default
    error stop "scalar shape clone dynamic type"
  end select
  allocate(shape_many, source=clone(plain_shapes))
  if (size(shape_many) /= 3) error stop "shape vector clone size"
  select type (shape_many)
  type is (shape_base)
    if (any(shape_many%id /= [1, 2, 3])) error stop "shape vector clone data"
  class default
    error stop "shape vector clone dynamic type"
  end select
  allocate(token_one, source=clone(plain_token))
  select type (token_one)
  type is (token_base)
    if (token_one%weight /= 8) error stop "scalar token clone data"
  class default
    error stop "scalar token clone dynamic type"
  end select
  allocate(token_many, source=clone(child_tokens))
  if (size(token_many) /= 2) error stop "token vector clone size"
  select type (token_many)
  type is (token_child)
    if (any(token_many%weight /= [5, 6]) .or. any(token_many%bonus /= [50, 60])) then
      error stop "token vector clone data"
    end if
  class default
    error stop "token vector clone dynamic type"
  end select
  if (declared_code(clone(child_shape)) /= 10) error stop "scalar shape declared result"
  if (declared_code(clone(plain_shapes)) /= 11) error stop "vector shape declared result"
  if (declared_code(clone(plain_token)) /= 20) error stop "scalar token declared result"
  if (declared_code(clone(child_tokens)) /= 21) error stop "vector token declared result"

  integer_op => chooser(3)
  if (.not. associated(integer_op, negate_integer)) error stop "integer pointer result target"
  if (integer_op(7) /= -7) error stop "integer pointer result call"
  single_op => chooser(1.0_single_precision)
  if (.not. associated(single_op, negate_single)) error stop "single pointer result target"
  if (single_op(2.5_single_precision) /= -2.5_single_precision) then
    error stop "single pointer result call"
  end if
  double_op => chooser(1.0_double_precision)
  if (.not. associated(double_op, negate_double)) error stop "double pointer result target"
  if (double_op(4.25_double_precision) /= -4.25_double_precision) then
    error stop "double pointer result call"
  end if
  print '(a)', 'TEST-PASS: audit-integration-result-forms'
end program
