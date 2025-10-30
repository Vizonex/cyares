from cpython.bytes cimport *
from cpython.list cimport PyList_New, PyList_SET_ITEM
from cpython.ref cimport Py_DECREF

from .exception cimport AresError
from .handles cimport Future
from .resulttypes cimport *


cdef extern from "Python.h":
    # Only Required in a few places currently using to see if theres a performance increase.
    int PyObject_IsTrue(PyObject *o) except -1
    PyObject *PyObject_CallMethodOneArg(object obj, object name, object arg) except NULL
    PyObject *PyObject_CallMethodNoArgs(object obj, object name) except NULL



# TODO: In a future update we should move to ares_query_dnsrec from the old ares_query
# This will make things a bit easier. 

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



# This is for the new DNS REC Which we plan to replace query with 
# for now this will be primarly for searching...


# DNS - RECURSION Callbacks

# Extremely helpful worth a read...
# https://github.com/c-ares/c-ares/discussions/962

cdef void __callback_dns_rec__a(
    void *arg, 
    ares_status_t status,
    size_t timeouts,
    const ares_dns_record_t *dnsrec
) noexcept with gil:
    if arg == NULL:
        return
   
    cdef size_t i, size
    cdef const ares_dns_rr_t *rr = NULL
    cdef list records
    cdef ares_dns_rec_type_t rt
    cdef Future handle = <Future>arg
   
    if __cancel_check(status, handle):
        return

    # Aggressive check
    if dnsrec == NULL:
        # There was no data...
        handle.set_exception(AresError(ARES_ENODATA))
        Py_DECREF(handle)
        return
    
    try:
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            size = ares_dns_record_rr_cnt(dnsrec, ARES_SECTION_ANSWER)
            records = []
            for i in range(size):
                rr = ares_dns_record_rr_get_const(
                    dnsrec,
                    ARES_SECTION_ANSWER,
                    i
                )
                rt = ares_dns_rr_get_type(rr)

                if rt == ARES_REC_TYPE_A:
                    records.append(ares_query_a_result.new(rr))
            
            handle.set_result(records)

    except BaseException as e:
        handle.set_exception(e)
    Py_DECREF(handle)



cdef void __callback_dns_rec__aaaa(
    void *arg, 
    ares_status_t status,
    size_t timeouts,
    const ares_dns_record_t *dnsrec
) noexcept with gil:
    if arg == NULL:
        return
   
    cdef size_t i, size
    cdef const ares_dns_rr_t *rr = NULL
    cdef list records
    cdef ares_dns_rec_type_t rt
    cdef Future handle = <Future>arg
   
    if __cancel_check(status, handle):
        return

    # Aggressive check
    if dnsrec == NULL:
        # There was no data...
        handle.set_exception(AresError(ARES_ENODATA))
        Py_DECREF(handle)
        return
    
    try:
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            size = ares_dns_record_rr_cnt(dnsrec, ARES_SECTION_ANSWER)
            records = []
            for i in range(size):
                rr = ares_dns_record_rr_get_const(
                    dnsrec,
                    ARES_SECTION_ANSWER,
                    i
                )
                rt = ares_dns_rr_get_type(rr)

                if rt == ARES_REC_TYPE_AAAA:
                    print(records)
                    print("append")
                    records.append(ares_query_aaaa_result.new(rr))
                    print("append done")
            handle.set_result(records)

    except BaseException as e:
        handle.set_exception(e)
    Py_DECREF(handle)


cdef void __callback_query_on_caa(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    if arg == NULL:
        return

    cdef ares_caa_reply * reply = NULL
    
    cdef list result = []
    cdef Future handle = <Future>arg
    
    if __cancel_check(status, handle):
        return

    
    try:
        status = ares_parse_caa_reply(abuf, alen, &reply)
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            while reply != NULL:
                result.append(ares_query_caa_result.old_new(reply))
                reply = reply.next
            handle.set_result(result)

    except BaseException as e:
        handle.set_exception(e)

    if reply != NULL:
        ares_free_data(reply)
    Py_DECREF(handle)



cdef void __callback_query_on_cname(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    if arg == NULL:
        return

    cdef hostent* host = NULL
    
    cdef ares_query_cname_result result
    cdef Future handle = <Future>arg
    
    if __cancel_check(status, handle):
        return
    try:
        status = ares_parse_a_reply(abuf, alen, &host, NULL, NULL)
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            result = ares_query_cname_result.old_new(host)
            handle.set_result(result)

    except BaseException as e:
        handle.set_exception(e)

    if host != NULL:
        ares_free_hostent(host)

    Py_DECREF(handle)




cdef void __callback_dns_rec__mx(
    void *arg, 
    ares_status_t status,
    size_t timeouts,
    const ares_dns_record_t *dnsrec
) noexcept with gil:
    if arg == NULL:
        return
   
    cdef size_t i, size
    cdef const ares_dns_rr_t *rr = NULL
    cdef list records
    cdef ares_dns_rec_type_t rt
    cdef Future handle = <Future>arg
   
    if __cancel_check(status, handle):
        return

    # Aggressive check
    if dnsrec == NULL:
        # There was no data...
        handle.set_exception(AresError(ARES_ENODATA))
        Py_DECREF(handle)
        return
    
    try:
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            size = ares_dns_record_rr_cnt(dnsrec, ARES_SECTION_ANSWER)
            records = []
            for i in range(size):
                rr = ares_dns_record_rr_get_const(
                    dnsrec,
                    ARES_SECTION_ANSWER,
                    i
                )
                rt = ares_dns_rr_get_type(rr)

                if rt == ARES_REC_TYPE_MX:
                    records.append(ares_query_mx_result.new(rr))
            handle.set_result(records)

    except BaseException as e:
        handle.set_exception(e)
    Py_DECREF(handle)



cdef void __callback_query_on_naptr(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    if arg == NULL:
        return

    cdef ares_naptr_reply* reply = NULL
    
    cdef list result = []
    cdef Future handle = <Future>arg

    if __cancel_check(status, handle):
        return
    try:
        status = ares_parse_naptr_reply(abuf, alen, &reply)
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            while reply != NULL:
                result.append(ares_query_naptr_result.old_new(reply))
                reply = reply.next
            handle.set_result(result)
    except BaseException as e:
        handle.set_exception(e)
        
    if reply != NULL:
        ares_free_data(reply)

    Py_DECREF(handle)


cdef void __callback_query_on_ns(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    if arg == NULL:
        return

    cdef hostent* host = NULL
    
    cdef list result = []
    cdef Py_ssize_t i = 0
    cdef Future handle = <Future>arg

    if __cancel_check(status, handle):
        return

    try:
        
        status = ares_parse_ns_reply(abuf, alen, &host)
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            while host.h_aliases[i] != NULL:
                result.append(ares_query_ns_result.old_new(host.h_aliases[i]))
                i += 1
            handle.set_result(result)

    except BaseException as e:
        handle.set_exception(e)
    
    if host != NULL:
        ares_free_hostent(host)
    
    Py_DECREF(handle)


cdef void __callback_query_on_ptr(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    if arg == NULL:
        return

    cdef hostent* host = NULL
    
    cdef list aliases = []
    cdef ares_query_ptr_result result
    cdef Py_ssize_t i = 0
    cdef Future handle = <Future>arg

    if __cancel_check(status, handle):
        return
    try:
        status = ares_parse_ptr_reply(abuf, alen, NULL, 0, AF_UNSPEC, &host)
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            while host.h_aliases[i] != NULL:
                aliases.append(PyBytes_FromString(host.h_aliases[i]))
                i += 1
            result = ares_query_ptr_result.old_new(host, aliases)
            handle.set_result(result)
    
    except BaseException as e:
        handle.set_exception(e)
        
    
    if host != NULL:
        ares_free_hostent(host)
    
    Py_DECREF(handle)
    

cdef void __callback_query_on_soa(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    if arg == NULL:
        return

    cdef ares_soa_reply* reply = NULL
    
    cdef ares_query_soa_result result
    cdef Future handle = <Future>arg

    if __cancel_check(status, handle):
        return

    try:
        status = ares_parse_soa_reply(abuf, alen, &reply)
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            result = ares_query_soa_result.old_new(reply)
            handle.set_result(result)

    except BaseException as e:
        handle.set_exception(e)


    if reply != NULL:
        ares_free_data(reply)
    
    Py_DECREF(handle)


cdef void __callback_query_on_srv(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    if arg == NULL:
        return

    cdef ares_srv_reply* reply = NULL
    
    cdef list result = []
    cdef Future handle = <Future>arg

    if __cancel_check(status, handle):
        return
    try:
        
        status = ares_parse_srv_reply(abuf, alen, &reply)
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            while reply != NULL:
                result.append(ares_query_srv_result.old_new(reply))
                reply = reply.next

            handle.set_result(result)

    except BaseException as e:
        handle.set_exception(e)
        
    if reply != NULL:
        ares_free_data(reply)
    
    Py_DECREF(handle)


cdef void __callback_query_on_txt(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    if arg == NULL:
        return
    
    cdef ares_txt_ext* reply = NULL
    
    cdef list result = []
    cdef ares_query_txt_result tmp_obj
    cdef bint initalized = False
    cdef Future handle = <Future>arg

    if __cancel_check(status, handle):
        return
    try:
        
        status = ares_parse_txt_reply_ext(abuf, alen, &reply)
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            while True:
                if reply == NULL:
                    if tmp_obj is not None:
                        result.append(ares_query_txt_result.from_object(tmp_obj))
                    break
                if reply.record_start == 1:
                    if initalized:
                        result.append(ares_query_txt_result.from_object(tmp_obj))
                    else:
                        initalized = True
                        tmp_obj = ares_query_txt_result.old_new(reply)
                else:
                    tmp_obj.text += PyBytes_FromString(<char*>reply.txt)
                reply = reply.next
            handle.set_result(result)

    except BaseException as e:
        handle.set_exception(e)


    if reply != NULL:
        ares_free_data(reply)

    Py_DECREF(handle)


# GET_ADDER_INFO 

cdef void __callback_getaddrinfo(
    void *arg, 
    int status,
    int timeouts,
    ares_addrinfo *result
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
            handle.set_result(ares_addrinfo_result.new(result))
    
    except BaseException as e:
        handle.set_exception(e)

cdef void __callback_gethostbyname(
    void *arg, int status, int timeouts, hostent* _hostent
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
            handle.set_result(ares_host_result.new(_hostent))
    except BaseException as e:
        handle.set_exception(e)

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
            handle.set_result(ares_nameinfo_result.new(node, service))
    except BaseException as e:
        handle.set_exception(e)

    Py_DECREF(handle)

cdef void __callback_gethostbyaddr(
    void *arg, int status, int timeouts, hostent* _hostent
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
            handle.set_result(ares_host_result.new(_hostent))
    except BaseException as e:
        handle.set_exception(e)

    Py_DECREF(handle)



# Using the newer setup which is ares_query_dns_rec
# it is possible to determine what kind of DNS Record we 
# were sent back to us so a game of guessing doesn't need to be done
# as in pycares.
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
    cdef list records
    cdef ares_dns_rec_type_t rt
    cdef Future handle = <Future>arg
   
    if __cancel_check(status, handle):
        return 
    elif dnsrec == NULL:
        handle.set_exception(AresError(ARES_ENODATA))
        Py_DECREF(handle)
        return

    try:
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            size = ares_dns_record_rr_cnt(dnsrec, ARES_SECTION_ANSWER)
            records = PyList_New(<Py_ssize_t>size)
            for i in range(size):
                rr = ares_dns_record_rr_get_const(
                    dnsrec,
                    ARES_SECTION_ANSWER,
                    i
                )
                rt = ares_dns_rr_get_type(rr)
                if rt == ARES_REC_TYPE_OPT:
                    PyList_SET_ITEM(records, i, ares_query_opt_result.new(rr))

                elif rt == ARES_REC_TYPE_A:
                    PyList_SET_ITEM(records , i, ares_query_a_result.new(rr))
                
                elif rt == ARES_REC_TYPE_AAAA:
                    PyList_SET_ITEM(records, i, ares_query_aaaa_result.new(rr))
                
                elif rt == ARES_REC_TYPE_CAA:
                    PyList_SET_ITEM(records, i, ares_query_caa_result.new(rr))
                
                elif rt == ARES_REC_TYPE_CNAME:
                    PyList_SET_ITEM(records, i , ares_query_cname_result.new(rr))
                
                elif rt == ARES_REC_TYPE_MX:
                    PyList_SET_ITEM(records, i, ares_query_mx_result.new(rr))
                
                elif rt == ARES_REC_TYPE_NAPTR:
                    PyList_SET_ITEM(records, i, ares_query_naptr_result.new(rr))
                
                elif rt == ARES_REC_TYPE_NS:
                    PyList_SET_ITEM(records, i, ares_query_ns_result.new(rr))
                
                elif rt == ARES_REC_TYPE_PTR:
                    PyList_SET_ITEM(records, i, ares_query_ptr_result.new(rr))
                
                elif rt == ARES_REC_TYPE_SOA:
                    PyList_SET_ITEM(records, i, ares_query_soa_result.new(rr))
                
                elif rt == ARES_REC_TYPE_SRV:
                    PyList_SET_ITEM(records, i, ares_query_srv_result.new(rr))
                
                elif rt == ARES_REC_TYPE_TXT:
                    PyList_SET_ITEM(records, i, ares_query_txt_result.new(rr, i))

                elif rt == ARES_REC_TYPE_HINFO:
                    PyList_SET_ITEM(records, i, ares_query_hinfo_result.new(rr))
                
                elif rt == ARES_REC_TYPE_SIG:
                    PyList_SET_ITEM(records, i, ares_query_sig_result.new(rr))
                
                elif rt == ARES_REC_TYPE_TLSA:
                    PyList_SET_ITEM(records, i, ares_query_tlsa_result.new(rr))
                
                elif rt == ARES_REC_TYPE_SVCB:
                    PyList_SET_ITEM(records, i, ares_query_svcb_result.new(rr))
                
                elif rt == ARES_REC_TYPE_HTTPS:
                    PyList_SET_ITEM(records, i, ares_query_https_result.new(rr))

                elif rt == ARES_REC_TYPE_URI:
                    PyList_SET_ITEM(records, i, ares_query_uri_result.new(rr))
                
                elif rt == ARES_REC_TYPE_RAW_RR:
                    PyList_SET_ITEM(records, i, ares_query_raw_rr_result.new(rr))
                
                else:
                    # UNKNOWN, IF you need more of the newer dns records or 
                    # any new ones that c-ares adds throw me an issue
                    # on github - Vizonex
                    PyList_SET_ITEM(records, i, None)

            handle.set_result(records)
    except BaseException as e:
        handle.set_exception(e)

    Py_DECREF(handle)



