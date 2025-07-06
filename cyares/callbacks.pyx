from cpython.bytes cimport *
from cpython.list cimport PyList_New, PyList_SET_ITEM

from .exception cimport AresError
from .resulttypes cimport *

include "handles.pxi"


# TODO: In a future update we should move to ares_query_dnsrec from the old ares_query
# This will make things a bit easier. 

# Using objects instead of a normal callback can help eliminate some release after free vulnerabilities...



# Checks to see if we issued a cancel from the channel itself...
cdef bint __cancel_check(int status, object fut) noexcept:
    if fut.cancelled():
        return 1
    if status == ARES_ECANCELLED:
        try:
            fut.cancel()
        except BaseException as e:
            fut.set_exception(e)
        return 1
    else:
        return 0


cdef void __callback_query_on_a(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    if arg == NULL:
        return
    cdef ares_addrttl[256] ttl
    cdef int ttl_size
    cdef object handle = <object>arg
    if __cancel_check(status, handle):
        return

    try:
        status = ares_parse_a_reply(abuf, alen, NULL, ttl, &ttl_size)
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            handle.set_result([ares_query_a_result.old_new(&ttl[i]) for i in range(ttl_size)])
    except BaseException as e:
        handle.set_exception(e)




cdef void __callback_query_on_aaaa(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    if arg == NULL:
        return

    cdef ares_addr6ttl[256] ttl
    cdef int ttl_size
    
    
    cdef object handle = <object>arg

    if __cancel_check(status, handle):
        return
    
    try:
        status = ares_parse_aaaa_reply(abuf,alen, NULL, ttl, &ttl_size)
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            handle.set_result([ares_query_aaaa_result.old_new(&ttl[i]) for i in range(ttl_size)])

    except BaseException as e:
        handle.set_exception(e)
    
    



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
    cdef object handle = <object>arg
    
    if __cancel_check(status, handle):
        return

    
    try:
        status = ares_parse_caa_reply(abuf,alen, &reply)
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
    cdef object handle = <object>arg
    
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




cdef void __callback_query_on_mx(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    if arg == NULL:
        return

    cdef ares_mx_reply* reply = NULL
    
    cdef list result = []
    cdef object handle = <object>arg

    if __cancel_check(status, handle):
        return
    try:
        status = ares_parse_mx_reply(abuf, alen, &reply)
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            while reply != NULL:
                result.append(ares_query_mx_result.new(reply))
                reply = reply.next
            handle.set_result(result)
    except BaseException as e:
        handle.set_exception(e)

    if reply != NULL:
        ares_free_data(reply)




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
    cdef object handle = <object>arg

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
    cdef object handle = <object>arg

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
    cdef object handle = <object>arg

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
    cdef object handle = <object>arg

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
    cdef object handle = <object>arg

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
    cdef object handle = <object>arg

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


# GET_ADDER_INFO 

cdef void __callback_getaddrinfo(
    void *arg, 
    int status,
    int timeouts,
    ares_addrinfo *result
) noexcept with gil:
    if arg == NULL:
        return

    cdef object handle = <object>arg

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
    
    cdef object handle = <object>arg
    
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

    cdef object handle = <object>arg
    
    if __cancel_check(status, handle):
        return 

    try:
        if status != ARES_SUCCESS:
            handle.set_exception(AresError(status))
        else:
            handle.set_result(ares_nameinfo_result.new(node, service))
    except BaseException as e:
        handle.set_exception(e)


# This is for the new DNS REC Which we plan to replace query with 
# for now this will be primarly for searching...


# DNS - RECURSION Callbacks

# Extremely helpful worth a read...
# https://github.com/c-ares/c-ares/discussions/962


# cdef void __callback_dns_rec__a(
#     void *arg,
#     ares_status_t status,
#     size_t timeouts,
#     const ares_dns_record_t *dnsrec
# ) noexcept with gil:
#     if arg == NULL:
#         return
    
#     cdef object handle = <object>arg
#     cdef size_t i, size
#     cdef const ares_dns_rr_t *rr = NULL
#     cdef list records

#     if __cancel_check(status, handle):
#         return 
#     elif dnsrec == NULL:
#         return

#     try:
#         if status != ARES_SUCCESS:
#             handle.set_exception(AresError(status))
#         else:
#             size = ares_dns_record_rr_cnt(dnsrec, ARES_SECTION_ANSWER)
#             records = PyList_New(<Py_ssize_t>size)
#             for i in range(size):
#                 rr = ares_dns_record_rr_get_const(
#                     dnsrec,
#                     ARES_SECTION_ANSWER,
#                 )
                

                
