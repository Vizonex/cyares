from concurrent.futures import Future as _Future

# There's a big surprise for 1.6 up ahead that will involve a new Chained Future Object.

cdef Future = _Future


