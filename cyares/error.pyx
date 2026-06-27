cdef extern from "inc/cyares_err_lookup.h":
    bytes cyares_err_name(int status)
    bytes cyares_strerror(int status)

from . cimport ares

# For Compatability with pycares, here is what we will do...
ARES_SUCCESS = ares.ARES_SUCCESS
# error codes
ARES_ENODATA = ares.ARES_ENODATA
ARES_EFORMERR = ares.ARES_EFORMERR
ARES_ESERVFAIL = ares.ARES_ESERVFAIL
ARES_ENOTFOUND = ares.ARES_ENOTFOUND
ARES_ENOTIMP = ares.ARES_ENOTIMP
ARES_EREFUSED = ares.ARES_EREFUSED
ARES_EBADQUERY = ares.ARES_EBADQUERY
ARES_EBADNAME = ares.ARES_EBADNAME
ARES_EBADFAMILY = ares.ARES_EBADFAMILY
ARES_EBADRESP = ares.ARES_EBADRESP
ARES_ECONNREFUSED = ares.ARES_ECONNREFUSED
ARES_ETIMEOUT = ares.ARES_ETIMEOUT
ARES_EOF = ares.ARES_EOF
ARES_EFILE = ares.ARES_EFILE
ARES_ENOMEM = ares.ARES_ENOMEM
ARES_EDESTRUCTION = ares.ARES_EDESTRUCTION
ARES_EBADSTR = ares.ARES_EBADSTR
ARES_EBADFLAGS = ares.ARES_EBADFLAGS
ARES_ENONAME = ares.ARES_ENONAME
ARES_EBADHINTS = ares.ARES_EBADHINTS
ARES_ENOTINITIALIZED = ares.ARES_ENOTINITIALIZED
ARES_ELOADIPHLPAPI = ares.ARES_ELOADIPHLPAPI
ARES_EADDRGETNETWORKPARAMS = ares.ARES_EADDRGETNETWORKPARAMS
ARES_ECANCELLED = ares.ARES_ECANCELLED
ARES_ESERVICE = ares.ARES_ESERVICE

errorcode = {
    ARES_SUCCESS: "ARES_SUCCESS",
    # error codes
    ARES_ENODATA: "ARES_ENODATA",
    ARES_EFORMERR: "ARES_EFORMERR",
    ARES_ESERVFAIL: "ARES_ESERVFAIL",
    ARES_ENOTFOUND: "ARES_ENOTFOUND",
    ARES_ENOTIMP: "ARES_ENOTIMP",
    ARES_EREFUSED: "ARES_EREFUSED",
    ARES_EBADQUERY: "ARES_EBADQUERY",
    ARES_EBADNAME: "ARES_EBADNAME",
    ARES_EBADFAMILY: "ARES_EBADFAMILY",
    ARES_EBADRESP: "ARES_EBADRESP",
    ARES_ECONNREFUSED: "ARES_ECONNREFUSED",
    ARES_ETIMEOUT: "ARES_ETIMEOUT",
    ARES_EOF: "ARES_EOF",
    ARES_EFILE: "ARES_EFILE",
    ARES_ENOMEM: "ARES_ENOMEM",
    ARES_EDESTRUCTION: "ARES_EDESTRUCTION",
    ARES_EBADSTR: "ARES_EBADSTR",
    ARES_EBADFLAGS: "ARES_EBADFLAGS",
    ARES_ENONAME: "ARES_ENONAME",
    ARES_EBADHINTS: "ARES_EBADHINTS",
    ARES_ENOTINITIALIZED: "ARES_ENOTINITIALIZED",
    ARES_ELOADIPHLPAPI: "ARES_ELOADIPHLPAPI",
    ARES_EADDRGETNETWORKPARAMS: "ARES_EADDRGETNETWORKPARAMS",
    ARES_ECANCELLED: "ARES_ECANCELLED",
    ARES_ESERVICE: "ARES_ESERVICE",
}

cpdef object strerror(int status):
    """implemented for mirrored compatability with pycares"""
    cdef bytes data = cyares_strerror(status)
    try:
        return data.decode('ascii')
    except UnicodeDecodeError:
        return data


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



