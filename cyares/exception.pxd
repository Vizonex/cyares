cdef class AresError(Exception):
    cdef:
        # Allow python access but not-alterable access
        readonly int status
        readonly bytes strerror
        readonly bytes name