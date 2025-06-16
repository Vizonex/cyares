from cpython.exc cimport PyErr_SetObject
from cpython.bytes cimport PyBytes_FromString
from libc.stdint cimport uint64_t
from .handle cimport Handle, Channel

from ..ares cimport *
from .resulttypes cimport *

cdef class CallbackHandle(Handle):
    @staticmethod
    cdef CallbackHandle new(Channel channel, uint64_t h_id, object cb):
        cdef CallbackHandle handle = CallbackHandle.__new__(CallbackHandle)
        handle._init(channel, h_id, cb)
        return handle


    cdef void send(self, Py_buffer* qview):
        ares_send(self.channel.channel, <unsigned char*>qview.buf, <int>qview.len, __callback_handle_on_send, <void*>self)


    cdef int query(self, Py_buffer* qname, int dnsclass, int _type) except -1:
        if _type == T_A:
            ares_send(
                self.channel.channel, 
                <unsigned char*>qname.buf, 
                <int>qname.len, 
                __callback_query_on_a,
                <void*>self
            )
            return 0

        elif _type == T_AAAA:
            ares_send(
                self.channel.channel, 
                <unsigned char*>qname.buf, 
                <int>qname.len,
                __callback_query_on_aaaa,
                <void*>self
            )
            return 0

        elif _type == T_CAA:
            ares_send(
                self.channel.channel,
                 <unsigned char*>qname.buf, 
                <int>qname.len,
                __callback_query_on_caa,
                <void*>self
            )
            return 0

        elif _type == T_CNAME:
            ares_send(
                self.channel.channel,
                 <unsigned char*>qname.buf, 
                <int>qname.len,
                __callback_query_on_cname,
                <void*>self
            )
            return 0
        
        elif _type == T_MX:
            ares_send(
                self.channel.channel,
                <unsigned char*>qname.buf, 
                <int>qname.len,
                __callback_query_on_mx,
                <void*>self
            )
            return 0

        
        elif _type == T_NAPTR:
            ares_send(
                self.channel.channel,
                <unsigned char*>qname.buf, 
                <int>qname.len,
                __callback_query_on_naptr,
                <void*>self
            )
            return 0


        elif _type == T_NS:
            ares_send(
                self.channel.channel,
                <unsigned char*>qname.buf, 
                <int>qname.len,
                __callback_query_on_ns,
                <void*>self
            )
            return 0


        elif _type == T_PTR:
            ares_send(
                self.channel.channel,
                <unsigned char*>qname.buf, 
                <int>qname.len,
                __callback_query_on_ptr,
                <void*>self
            )
            return 0


        elif _type == T_SOA:
            ares_send(
                self.channel.channel,
                <unsigned char*>qname.buf, 
                <int>qname.len,
                __callback_query_on_soa,
                <void*>self
            )
            return 0

        
        elif _type == T_SRV:
            ares_send(
                self.channel.channel,
                <unsigned char*>qname.buf, 
                <int>qname.len,
                __callback_query_on_srv,
                <void*>self
            )
            return 0

        elif _type == T_TXT:
            ares_send(
                self.channel.channel,
                <unsigned char*>qname.buf, 
                <int>qname.len,
                __callback_query_on_txt,
                <void*>self
            )
            return 0
        else:
            PyErr_SetObject(ValueError, "invalid query type specified")
            return -1



    cdef int search(self, Py_buffer* qname, int dnsclass, int _type) except -1:
        pass



cdef void __callback_handle_on_send(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef CallbackHandle handle = <CallbackHandle>arg
    if handle.alive:
        try:
            handle.do_send_callback(status, timeouts, abuf, alen)
        except BaseException as e:
            handle._throw_exception(e)
    handle.done = True

cdef void __callback_query_on_a(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef ares_addrttl[256] ttl
    cdef int ttl_size
    cdef int status
    cdef CallbackHandle handle = <CallbackHandle>arg
    if handle.alive:
        try:
            status = ares_parse_a_reply(abuf,alen, NULL, &ttl, &ttl_size)
            if status != ARES_SUCCESS:
                handle.cb(None, status)
            else:
                handle.cb([ares_query_a_result.new(ttl[i]) for i in range(ttl_size)], status)
        except BaseException as e:
            handle._throw_exception(e)
    handle.done = True





cdef void __callback_query_on_aaaa(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef ares_addr6ttl[256] ttl
    cdef int ttl_size
    cdef int status
    cdef CallbackHandle handle = <CallbackHandle>arg
    if handle.alive:
        try:
            status = ares_parse_aaaa_reply(abuf,alen, NULL, &ttl, &ttl_size)
            if status != ARES_SUCCESS:
                handle.cb(None, status)
            else:
                handle.cb([ares_query_a_result.new(ttl[i]) for i in range(ttl_size)], status)
        except BaseException as e:
            handle._throw_exception(e)
    handle.done = True



cdef void __callback_query_on_caa(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef ares_caa_reply * reply = NULL
    cdef int status
    cdef list result = []
    cdef CallbackHandle handle = <CallbackHandle>arg
    if handle.alive:
        try:
            status = ares_parse_caa_reply(abuf,alen, &reply)
            if status != ARES_SUCCESS:
                handle.cb(None, status)
            else:
                while reply != NULL:
                    result.append(ares_query_caa_result.new(reply))
                    reply = reply.next
                handle.cb(result, status)
        except BaseException as e:
            handle._throw_exception(e)
    
    if reply != NULL:
        ares_free_data(reply)

    handle.done = True



cdef void __callback_query_on_cname(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef hostent* host = NULL
    cdef int status
    cdef ares_query_cname_result result
    cdef CallbackHandle handle = <CallbackHandle>arg
    if handle.alive:
        try:
            status = ares_parse_a_reply(abuf, alen, &host, NULL, NULL)
            if status != ARES_SUCCESS:
                handle.cb(None, status)
            else:
                result = ares_query_cname_result.new(host)
                handle.cb(result, status)

        except BaseException as e:
            handle._throw_exception(e)
    
    if host != NULL:
        ares_free_hostent(host)
    handle.done = True



cdef void __callback_query_on_mx(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef ares_mx_reply* reply = NULL
    cdef int status
    cdef list result = []
    cdef CallbackHandle handle = <CallbackHandle>arg

    if handle.alive:
        try:
            status = ares_parse_mx_reply(abuf, alen, &reply)
            if status != ARES_SUCCESS:
                handle.cb(None, status)
            else:
                while reply != NULL:
                    result.append(ares_query_mx_result.new(reply))
                    reply = reply.next

                handle.cb(result, status)

        except BaseException as e:
            handle._throw_exception(e)
    
    if reply != NULL:
        ares_free_data(reply)
    handle.done = True




cdef void __callback_query_on_naptr(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef ares_naptr_reply* reply = NULL
    cdef int status
    cdef list result = []
    cdef CallbackHandle handle = <CallbackHandle>arg

    if handle.alive:
        try:
            status = ares_parse_naptr_reply(abuf, alen, &reply)
            if status != ARES_SUCCESS:
                handle.cb(None, status)
            else:
                while reply != NULL:
                    result.append(ares_query_naptr_result.new(reply))
                    reply = reply.next

                handle.cb(result, status)

        except BaseException as e:
            handle._throw_exception(e)
    
    if reply != NULL:
        ares_free_data(reply)
    handle.done = True
    

cdef void __callback_query_on_ns(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef hostent* host = NULL
    cdef int status
    cdef list result = []
    cdef Py_ssize_t i = 0
    cdef CallbackHandle handle = <CallbackHandle>arg

    if handle.alive:
        try:
            status = ares_parse_ns_reply(abuf, alen, &host)
            if status != ARES_SUCCESS:
                handle.cb(None, status)
            else:
                while host.h_aliases[i] != NULL:
                    result.append(ares_query_ns_result.new(host.h_aliases[i]))
                    i += 1
                handle.cb(result, status)

        except BaseException as e:
            handle._throw_exception(e)
    
    if host != NULL:
        ares_free_hostent(host)
    handle.done = True


cdef void __callback_query_on_ptr(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef hostent* host = NULL
    cdef int status
    cdef list aliases = []
    cdef ares_query_ptr_result result
    cdef Py_ssize_t i = 0
    cdef CallbackHandle handle = <CallbackHandle>arg

    if handle.alive:
        try:
            status = ares_parse_ptr_reply(abuf, alen, NULL, 0, AF_UNSPEC, &host)
            if status != ARES_SUCCESS:
                handle.cb(None, status)
            else:
                while host.h_aliases[i] != NULL:
                    aliases.append(PyBytes_FromString(host.h_aliases[i]))
                    i += 1
                result = ares_query_ptr_result.new(host, aliases)
                handle.cb(result, status)

        except BaseException as e:
            handle._throw_exception(e)
    
    if host != NULL:
        ares_free_hostent(host)
    handle.done = True


cdef void __callback_query_on_soa(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef ares_soa_reply* reply = NULL
    cdef int status
    cdef ares_query_soa_result result
    cdef CallbackHandle handle = <CallbackHandle>arg

    if handle.alive:
        try:
            status = ares_parse_soa_reply(abuf, alen, &reply)
            if status != ARES_SUCCESS:
                handle.cb(None, status)
            else:
                result = ares_query_soa_result.new(reply)
                handle.cb(result, status)

        except BaseException as e:
            handle._throw_exception(e)
    
    if reply != NULL:
        ares_free_data(reply)
    handle.done = True


cdef void __callback_query_on_srv(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef ares_srv_reply* reply = NULL
    cdef int status
    cdef list result = []
    cdef CallbackHandle handle = <CallbackHandle>arg

    if handle.alive:
        try:
            status = ares_parse_naptr_reply(abuf, alen, &reply)
            if status != ARES_SUCCESS:
                handle.cb(None, status)
            else:
                while reply != NULL:
                    result.append(ares_query_srv_result.new(reply))
                    reply = reply.next

                handle.cb(result, status)

        except BaseException as e:
            handle._throw_exception(e)
    
    if reply != NULL:
        ares_free_data(reply)
    handle.done = True


cdef void __callback_query_on_txt(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef ares_txt_ext* reply = NULL
    cdef int status
    cdef list result = []
    cdef ares_query_txt_result tmp_obj
    cdef CallbackHandle handle = <CallbackHandle>arg

    if handle.alive:
        try:
            status = ares_parse_txt_reply_ext(abuf, alen, &reply)
            if status != ARES_SUCCESS:
                handle.cb(None, status)
            else:
                while True:
                    if reply == NULL:
                        if tmp_obj is not None:
                            result.append(ares_query_txt_result.new(tmp_obj))
                        break
                    if reply.record_start == 1:
                        if tmp_obj is not NULL:
                            result.append(ares_query_txt_result.new(tmp_obj))
                    else:
                        tmp_obj.text += PyBytes_FromString(reply.txt)
                    reply = reply.next

                handle.cb(result, status)

        except BaseException as e:
            handle._throw_exception(e)
    
    if reply != NULL:
        ares_free_data(reply)
    handle.done = True
