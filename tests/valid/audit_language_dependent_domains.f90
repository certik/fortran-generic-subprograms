! TEST-PASS: audit-language-dependent-domains
! TEST-RULE: R833 8.5.17p4 10.1.12p2 15.6.2.4
! The rank domain of Y is interpreted for each earlier X specialization,
! producing the portable five-pair domain (1,0), (1,1), (2,0), (2,1), (2,2).
module audit_language_dependent_domains_m
  implicit none
  private
  public :: rank_pairs
contains
  generic subroutine rank_pairs(x, y, xr, yr, total)
    integer, rank(1:2), intent(in) :: x
    integer, rank(0:rank(x)), intent(in) :: y
    integer, intent(out) :: xr, yr, total

    xr = rank(x)
    yr = rank(y)
    select generic rank (x)
    rank (1)
      select generic rank (y)
      rank (0)
        total = sum(x) + y
      rank (1)
        total = sum(x) + sum(y)
      end select
    rank (2)
      select generic rank (y)
      rank (0)
        total = sum(x) + y
      rank (1)
        total = sum(x) + sum(y)
      rank (2)
        total = sum(x) + sum(y)
      end select
    end select
  end subroutine

end module

program audit_language_dependent_domains_p
  use audit_language_dependent_domains_m, only: rank_pairs
  implicit none
  integer :: x1(2), x2(2, 2), y1(2), y2(2, 2)
  integer :: xr, yr, total

  x1 = [2, 3]
  x2 = reshape([1, 2, 3, 4], [2, 2])
  y1 = [5, 6]
  y2 = reshape([1, 2, 3, 4], [2, 2])

  call rank_pairs(x1, 7, xr, yr, total)
  call check_rank(xr, yr, total, 1, 0, 12)
  call rank_pairs(x1, [1, 2], xr, yr, total)
  call check_rank(xr, yr, total, 1, 1, 8)
  call rank_pairs(x2, 5, xr, yr, total)
  call check_rank(xr, yr, total, 2, 0, 15)
  call rank_pairs(x2, y1, xr, yr, total)
  call check_rank(xr, yr, total, 2, 1, 21)
  call rank_pairs(x2, y2, xr, yr, total)
  call check_rank(xr, yr, total, 2, 2, 20)

  print '(a)', 'TEST-PASS: audit-language-dependent-domains'
contains
  subroutine check_rank(axr, ayr, actual, exr, eyr, expected)
    integer, intent(in) :: axr, ayr, actual, exr, eyr, expected
    if (axr /= exr .or. ayr /= eyr .or. actual /= expected) then
      error stop "dependent rank domain"
    end if
  end subroutine

end program
