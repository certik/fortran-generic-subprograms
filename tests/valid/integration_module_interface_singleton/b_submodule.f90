submodule (integration_module_interface_singleton_m) &
    integration_module_interface_singleton_s
  implicit none
contains
  module generic integer function singleton_impl(value)
    integer, intent(in) :: value
    singleton_impl = value + 1
  end function
end submodule
