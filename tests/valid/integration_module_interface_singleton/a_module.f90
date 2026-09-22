! TEST-RULE: C1561 C1564 15.4.3.2 15.4.3.4.1 15.6.2.6
! A MODULE GENERIC interface with no generic declarations has one specific
! and contributes it to the enclosing named generic.
module integration_module_interface_singleton_m
  implicit none
  interface routed_singleton
    module generic integer function singleton_impl(value)
      integer, intent(in) :: value
    end function
  end interface
end module
