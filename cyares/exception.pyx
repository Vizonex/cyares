cdef extern from "inc/cyares_err_lookup.h":
    bytes cyares_err_name(int status)
    bytes cyares_strerror(int status)


cdef class AresError(Exception):
    
    def __init__(self, int status) -> None:
        self.name = cyares_err_name(status)
        self.strerror = cyares_strerror(status)
        self.status = status
        super().__init__()

    def __str__(self):
        cdef object name_str = self.name.decode("utf-8", "surrogateescape")
        cdef object strerror_str = self.strerror.decode("utf-8", "surrogateescape")

        return "[%s : %i] %s" % (name_str, self.status ,strerror_str)
