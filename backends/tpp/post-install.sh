# TPP post install
# disable DNS. This works for TPP, but doesn't work for other backends, not
# sure why. But that is why it is a TPP only thing.
resolvectl dns eth0 ""

