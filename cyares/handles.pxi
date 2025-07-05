from concurrent.futures import Future as _Future

# XXX: Planning to move this all to Cython in the future but for now were stuck with this...

cdef Future = _Future

