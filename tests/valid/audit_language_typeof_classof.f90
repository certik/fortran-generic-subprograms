! TEST-PASS: audit-language-typeof-classof
! TEST-RULE: C709 C710 C711 C712 C713 C714 10.1.11p6-7 15.6.2.4
! TYPEOF/CLASSOF are interpreted after generated dummy properties are known.
! The forward TYPEOF reference is legal because local implicit typing has
! already established its type; the later declaration confirms that type.
module audit_language_typeof_classof_m
  implicit none

  type :: base
    integer :: value
  end type

  type, extends(base) :: child
    integer :: extra
  end type
contains
  pure integer function audit_extent(n, padding)
    integer, intent(in) :: n, padding
    audit_extent = max(1, n + padding)
  end function

  generic subroutine specification_probe(x, n, values, properties, payload)
    type(integer, real), rank(1:2), intent(in) :: x
    integer, intent(in) :: n, values(n)
    integer, intent(out) :: properties(4), payload
    typeof(x), allocatable, rank(rank(x)) :: copy
    integer :: inquiry_work(size(x))
    integer :: function_work(audit_extent(size(x), n))

    allocate(copy, source=x)
    inquiry_work = 1
    function_work = 2
    properties = [rank(copy), size(copy), size(inquiry_work), size(function_work)]
    select generic type (x)
    declared type is (integer)
      payload = sum(copy) + sum(values) + sum(inquiry_work) + sum(function_work)
    declared type is (real)
      payload = nint(10.0*sum(copy)) + sum(values) + sum(inquiry_work) + sum(function_work)
    end select
  end subroutine

  generic subroutine forward_implicit(tag, result)
    implicit integer (i)
    type(integer, real), intent(in) :: tag
    integer, intent(out) :: result
    typeof(index_value) :: copy
    integer :: index_value

    index_value = 5
    copy = index_value
    select generic type (tag)
    declared type is (integer)
      result = copy + tag
    declared type is (real)
      result = copy + nint(10.0*tag)
    end select
  end subroutine

  generic subroutine class_probe(object, unlimited, code)
    type(base, child), intent(in) :: object
    class(*), intent(in) :: unlimited
    integer, intent(out) :: code
    classof(object), allocatable :: object_copy
    classof(unlimited), allocatable :: unlimited_copy

    allocate(object_copy, source=object)
    allocate(unlimited_copy, source=unlimited)
    select generic type (object)
    declared type is (base)
      select type (object_copy)
      type is (base)
        code = 100 + object_copy%value
      class default
        error stop "CLASSOF base dynamic type"
      end select
      select type (unlimited_copy)
      type is (integer)
        if (unlimited_copy /= 11) error stop "CLASSOF unlimited integer value"
      class default
        error stop "CLASSOF unlimited integer dynamic type"
      end select
    declared type is (child)
      select type (object_copy)
      type is (child)
        code = 200 + object_copy%value + object_copy%extra
      class default
        error stop "CLASSOF child dynamic type"
      end select
      select type (unlimited_copy)
      type is (real)
        if (unlimited_copy /= 2.5) error stop "CLASSOF unlimited real value"
      class default
        error stop "CLASSOF unlimited real dynamic type"
      end select
    end select
  end subroutine
end module

program audit_language_typeof_classof_p
  use audit_language_typeof_classof_m
  implicit none
  integer :: iv(3), im(1, 2), values2(2), properties(4), payload, result, code
  real :: rv(2), rm(2, 1)
  type(base) :: b
  type(child) :: c

  iv = [1, 2, 3]
  im = reshape([4, 5], [1, 2])
  rv = [1.5, 2.5]
  rm = reshape([3.0, 4.0], [2, 1])
  values2 = [6, 7]

  call specification_probe(iv, 2, values2, properties, payload)
  if (any(properties /= [1, 3, 3, 5]) .or. payload /= 32) error stop "integer rank1 specs"
  call specification_probe(im, 2, values2, properties, payload)
  if (any(properties /= [2, 2, 2, 4]) .or. payload /= 32) error stop "integer rank2 specs"
  call specification_probe(rv, 2, values2, properties, payload)
  if (any(properties /= [1, 2, 2, 4]) .or. payload /= 63) error stop "real rank1 specs"
  call specification_probe(rm, 2, values2, properties, payload)
  if (any(properties /= [2, 2, 2, 4]) .or. payload /= 93) error stop "real rank2 specs"

  call forward_implicit(7, result)
  if (result /= 12) error stop "forward implicitly typed integer"
  call forward_implicit(1.5, result)
  if (result /= 20) error stop "forward implicitly typed real"

  b%value = 4
  c%value = 5
  c%extra = 6
  call class_probe(b, 11, code)
  if (code /= 104) error stop "CLASSOF generated base"
  call class_probe(c, 2.5, code)
  if (code /= 211) error stop "CLASSOF generated child"

  print '(a)', 'TEST-PASS: audit-language-typeof-classof'
end program
