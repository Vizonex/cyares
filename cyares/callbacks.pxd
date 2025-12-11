from .ares cimport (
    ares_addrinfo_t, 
    ares_dns_record_t, 
    ares_status_t, 
    hostent_t
)

cdef void __callback_getaddrinfo(
    void *arg, 
    int status,
    int timeouts,
    ares_addrinfo_t *result
) noexcept with gil

cdef void __callback_gethostbyname(
    void *arg, 
    int status, 
    int timeouts, 
    hostent_t* _hostent
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
    hostent_t* _hostent
) noexcept with gil


# TODO: Reseparate different dns types in a future update...

cdef void __callback_dns_rec__any(
    void *arg, 
    ares_status_t status,
    size_t timeouts,
    const ares_dns_record_t *dnsrec
) noexcept with gil
