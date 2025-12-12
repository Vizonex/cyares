from cpython.bytes cimport *
from cpython.ref cimport Py_DECREF

from .exception cimport AresError
from .handles cimport Future, CancelledError
from .resulttypes cimport *


cdef extern from "Python.h":
    # Only Required in a few places currently using to see if theres a performance increase.
    int PyObject_IsTrue(PyObject *o) except -1
    PyObject *PyObject_CallMethodOneArg(object obj, object name, object arg) except NULL
    PyObject *PyObject_CallMethodNoArgs(object obj, object name) except NULL



# Using objects instead of a normal callback can help eliminate some release after free vulnerabilities...


# Checks to see if we issued a cancel from the channel itself...
cdef bint __cancel_check(int status, Future fut) noexcept:
    if status == ARES_ECANCELLED:
        try:
            fut.cancel()
        except BaseException as e:
            fut.set_exception(e)
        # we can safely deref after the future is 
        # finished since we added a reference in Channel to keep
        # the future alive long enough.
        Py_DECREF(fut)
        return 1
    elif fut.cancelled():
        Py_DECREF(fut)
        return 1
    else:
        # supress exceptions and notify not to cacnel mid-way
        try:
            # we want the opposite effect.
            # if state is cancelled then exit
            # if state is running then continue
            return 0 if <bint>fut.set_running_or_notify_cancel() else 1
        except BaseException:
            return 0


# GET_ADDER_INFO 

cdef void __callback_getaddrinfo(
    void *arg, 
    int status,
    int timeouts,
    ares_addrinfo_t *result
) noexcept with gil:
    if arg == NULL:
        return

    cdef Future handle = <Future>arg

    if __cancel_check(status, handle):
        return
    try:
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            handle.set_result(parse_addrinfo(result))
    
    except BaseException as e:
        handle.set_exception(e)
    Py_DECREF(handle)


cdef void __callback_gethostbyname(
    void *arg, int status, int timeouts, hostent_t* _hostent
) noexcept with gil:
    if arg == NULL:
        return
    
    cdef Future handle = <Future>arg
    
    if __cancel_check(status, handle):
        return 

    try:
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            handle.set_result(parse_hostent(_hostent))
    except BaseException as e:
        handle.set_exception(e)
    Py_DECREF(handle)


cdef void __callback_nameinfo(
    void *arg,
    int status,
    int timeouts,
    char *node,
    char *service
) noexcept with gil:
    if arg == NULL:
        return

    cdef Future handle = <Future>arg
    
    if __cancel_check(status, handle):
        return 

    try:
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            handle.set_result(parse_nameinfo(node, service))
    except BaseException as e:
        handle.set_exception(e)

    Py_DECREF(handle)

cdef void __callback_gethostbyaddr(
    void *arg, int status, int timeouts, hostent_t* _hostent
) noexcept with gil:
    if arg == NULL:
        return
    
    cdef Future handle = <Future>arg
    
    if __cancel_check(status, handle):
        return 

    try:
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            handle.set_result(parse_hostent(_hostent))
    except BaseException as e:
        handle.set_exception(e)

    Py_DECREF(handle)




# Using the newer setup which is ares_query_dns_rec
# it is possible to determine what kind of DNS Record we 
# were sent back to us so a game of guessing doesn't need to be done
# as in pycares.

# For now as of 0.3.0 we will fallback but in the future re-optimize.

# DNS - RECURSION Callbacks

# Extremely helpful worth a read...
# https://github.com/c-ares/c-ares/discussions/962

cdef void __callback_dns_rec__any(
    void *arg, 
    ares_status_t status,
    size_t timeouts,
    const ares_dns_record_t *dnsrec
) noexcept with gil:
    if arg == NULL:
        return
   
    cdef size_t i, size
    cdef const ares_dns_rr_t *rr = NULL
    cdef DNSResult records
    cdef Future handle = <Future>arg
   
    if __cancel_check(status, handle):
        return
    elif dnsrec == NULL:
        # Clean reference to handle and close out assuming handle was cancelled.
        if not handle.cancelled():
            handle.cancel()

        Py_DECREF(handle)
        return

    try:
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            records , status = parse_dnsrec_any(dnsrec)
            if status != ARES_SUCCESS:
                handle.set_exception(AresError(status))
            else:
                handle.set_result(records)
    except BaseException as e:
        handle.set_exception(e)

    Py_DECREF(handle)



# This is for the new DNS REC Which we plan to replace query with 
# for now this will be primarly for searching...



