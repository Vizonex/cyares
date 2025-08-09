from .ares cimport *


cdef void __callback_query_on_a(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil


cdef void __callback_query_on_aaaa(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil


cdef void __callback_query_on_caa(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil



cdef void __callback_query_on_cname(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil



cdef void __callback_query_on_mx(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil


cdef void __callback_query_on_naptr(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil


cdef void __callback_query_on_ns(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil

cdef void __callback_query_on_ptr(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil
cdef void __callback_query_on_soa(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil

cdef void __callback_query_on_srv(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil

cdef void __callback_query_on_txt(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil

cdef void __callback_getaddrinfo(
    void *arg, 
    int status,
    int timeouts,
    ares_addrinfo *result
) noexcept with gil

cdef void __callback_gethostbyname(
    void *arg, 
    int status, 
    int timeouts, 
    hostent* _hostent
) noexcept with gil

cdef void __callback_nameinfo(
    void *arg,
    int status,
    int timeouts,
    char *node,
    char *service
) noexcept with gil

cdef void __callback_gethostbyaddr(
    void *arg, 
    int status, 
    int timeouts, 
    hostent* _hostent
) noexcept with gil

# This uses the newer dns recursion query functions to
# have better performance the only problem was that new 
# class objects had to be introduced but that's fine 
cdef void __callback_dns_rec__any(
    void *arg, 
    ares_status_t status,
    size_t timeouts,
    const ares_dns_record_t *dnsrec
) noexcept with gil
