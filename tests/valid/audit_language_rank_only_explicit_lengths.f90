! TEST-PASS: audit-language-rank-only-explicit-lengths
! TEST-RULE: R704 R831 R833 C717 C723 7.2 8.5.17 15.6.2.4
! Explicit length is ordinary here: only RANK contributes specializations.
module audit_language_rank_only_explicit_lengths_m
  implicit none
  type :: slab(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: payload(n)
  end type
contains
  generic subroutine inspect_character(x, observed_rank, observed_len, observed_kind, checksum)
    character(len=10), rank(0:1), intent(in) :: x
    integer, intent(out) :: observed_rank, observed_len, observed_kind, checksum

    observed_rank = rank(x)
    observed_len = len(x)
    observed_kind = kind(x)
    select generic rank (x)
    rank (0)
      checksum = len_trim(x)
    rank (1)
      checksum = sum(len_trim(x))
    end select
  end subroutine

  generic subroutine inspect_slab(x, observed_rank, observed_kind, observed_len, checksum)
    type(slab(k=kind(0), n=3)), rank(0:1), intent(in) :: x
    integer, intent(out) :: observed_rank, observed_kind, observed_len, checksum
    integer :: i

    observed_rank = rank(x)
    select generic rank (x)
    rank (0)
      observed_kind = x%k
      observed_len = x%n
      checksum = sum(x%payload)
    rank (1)
      observed_kind = x(1)%k
      observed_len = x(1)%n
      checksum = 0
      do i = 1, size(x)
        checksum = checksum + sum(x(i)%payload)
      end do
    end select
  end subroutine
end module

program audit_language_rank_only_explicit_lengths_p
  use audit_language_rank_only_explicit_lengths_m
  implicit none
  character(len=10) :: word, words(2)
  type(slab(k=kind(0), n=3)) :: one, many(2)
  integer :: observed_rank, observed_kind, observed_len, checksum

  word = "alpha"
  words = ["cat       ", "lion      "]
  call inspect_character(word, observed_rank, observed_len, observed_kind, checksum)
  if (observed_rank /= 0 .or. observed_len /= 10) error stop "character scalar selectors"
  if (observed_kind /= kind(word) .or. checksum /= 5) error stop "character scalar value"
  call inspect_character(words, observed_rank, observed_len, observed_kind, checksum)
  if (observed_rank /= 1 .or. observed_len /= 10) error stop "character array selectors"
  if (observed_kind /= kind(words) .or. checksum /= 7) error stop "character array values"

  one%payload = [1, 2, 3]
  many(1)%payload = [4, 5, 6]
  many(2)%payload = [7, 8, 9]
  call inspect_slab(one, observed_rank, observed_kind, observed_len, checksum)
  if (observed_rank /= 0 .or. observed_kind /= kind(0)) error stop "PDT scalar selectors"
  if (observed_len /= 3 .or. checksum /= 6) error stop "PDT scalar value"
  call inspect_slab(many, observed_rank, observed_kind, observed_len, checksum)
  if (observed_rank /= 1 .or. observed_kind /= kind(0)) error stop "PDT array selectors"
  if (observed_len /= 3 .or. checksum /= 39) error stop "PDT array values"

  print '(a)', 'TEST-PASS: audit-language-rank-only-explicit-lengths'
end program
