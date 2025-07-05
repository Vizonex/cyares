from libc.stdint cimport uint8_t, uint16_t, uint32_t
from libc.time cimport time_t

# NOTE: If needed We can always make a seperate 
# windows and unix branch

# We need private.h otherwise were screwed...
cdef extern from  "ares_private.h" nogil:
    ctypedef struct ares_channeldata:
        pass 

cdef extern from "inc/cares_headers.h" nogil:
    
    ctypedef long suseconds_t
    ctypedef int h_addrtype_t
    ctypedef int h_length_t
    ctypedef short sa_family_t
    ctypedef uint16_t in_port_t

    struct in_addr:
        uint32_t s_addr

    struct in6_addr:
        uint8_t s6_addr[16]

    struct timeval:
        time_t      tv_sec
        suseconds_t tv_usec

    struct hostent:
       char* h_name
       char** h_aliases
       h_addrtype_t h_addrtype
       h_length_t   h_length
       char** h_addr_list

    struct sockaddr:
        sa_family_t sa_family


    struct sockaddr_in:
        sa_family_t       sin_family
        in_port_t         sin_port
        in_addr    sin_addr

    struct sockaddr_in6:
        sa_family_t  sin6_family
        in_port_t    sin6_port
        uint32_t     sin6_flowinfo
        in6_addr     sin6_addr
        uint32_t     sin6_scope_id 

    int INET_ADDRSTRLEN
    int INET6_ADDRSTRLEN

    int C_IN
    int C_CHAOS
    int C_HS
    int C_NONE
    int C_ANY
    int T_A 
    int T_AAAA 
    int T_ANY 
    int T_CAA
    int T_CNAME
    int T_MX
    int T_NAPTR
    int T_NS
    int T_PTR
    int T_SOA
    int T_SRV
    int T_TXT
    
    ctypedef int ares_socket_t
    ctypedef int ares_socklen_t

    int ARES_SUCCESS            

    int ARES_ENODATA            
    int ARES_EFORMERR           
    int ARES_ESERVFAIL          
    int ARES_ENOTFOUND          
    int ARES_ENOTIMP            
    int ARES_EREFUSED           
    int ARES_EBADQUERY          
    int ARES_EBADNAME           
    int ARES_EBADFAMILY         
    int ARES_EBADRESP           
    int ARES_ECONNREFUSED       
    int ARES_ETIMEOUT           
    int ARES_EOF                
    int ARES_EFILE              
    int ARES_ENOMEM             
    int ARES_EDESTRUCTION       
    int ARES_EBADSTR            
    int ARES_EBADFLAGS          
    int ARES_ENONAME            
    int ARES_EBADHINTS          
    int ARES_ENOTINITIALIZED    
    int ARES_ELOADIPHLPAPI           
    int ARES_EADDRGETNETWORKPARAMS   
    int ARES_ECANCELLED         
    int ARES_ESERVICE

    # To Bypass Problems with flag names allow me to sprinkle some name aliasing

    int _ARES_FLAG_USEVC "ARES_FLAG_USEVC"      
    int _ARES_FLAG_PRIMARY "ARES_FLAG_PRIMARY"      
    int _ARES_FLAG_IGNTC "ARES_FLAG_IGNTC"
    int _ARES_FLAG_NORECURSE "ARES_FLAG_NORECURSE"
    int _ARES_FLAG_STAYOPEN  "ARES_FLAG_STAYOPEN"   
    int _ARES_FLAG_NOSEARCH "ARES_FLAG_NOSEARCH"   
    int _ARES_FLAG_NOALIASES "ARES_FLAG_NOALIASES"    
    int _ARES_FLAG_NOCHECKRESP "ARES_FLAG_NOCHECKRESP"   
    int _ARES_FLAG_EDNS "ARES_FLAG_EDNS" 
    int _ARES_FLAG_NO_DFLT_SVR "ARES_FLAG_NO_DFLT_SVR"

    int ARES_OPT_FLAGS          
    int ARES_OPT_TIMEOUT        
    int ARES_OPT_TRIES          
    int ARES_OPT_NDOTS          
    int ARES_OPT_UDP_PORT       
    int ARES_OPT_TCP_PORT       
    int ARES_OPT_SERVERS        
    int ARES_OPT_DOMAINS        
    int ARES_OPT_LOOKUPS        
    int ARES_OPT_SOCK_STATE_CB  
    int ARES_OPT_SORTLIST       
    int ARES_OPT_SOCK_SNDBUF    
    int ARES_OPT_SOCK_RCVBUF    
    int ARES_OPT_TIMEOUTMS      
    int ARES_OPT_ROTATE         
    int ARES_OPT_EDNSPSZ        
    int ARES_OPT_RESOLVCONF     
    int ARES_OPT_EVENT_THREAD   

    # More Name Aliases...

    int ARES_NI_NOFQDN     
    int ARES_NI_NUMERICHOST         
    int ARES_NI_NAMEREQD    
    int ARES_NI_NUMERICSERV       
    int ARES_NI_DGRAM       
    int ARES_NI_TCP           
    int ARES_NI_UDP     
    int ARES_NI_SCTP             
    int ARES_NI_DCCP          
    int ARES_NI_NUMERICSCOPE          
    int ARES_NI_LOOKUPHOST       
    int ARES_NI_LOOKUPSERVICE           
    int ARES_NI_IDN  
    int ARES_NI_IDN_ALLOW_UNASSIGNED
    int ARES_NI_IDN_USE_STD3_ASCII_RULES

    int ARES_AI_CANONNAME               
    int ARES_AI_NUMERICHOST             
    int ARES_AI_PASSIVE                 
    int ARES_AI_NUMERICSERV             
    int ARES_AI_V4MAPPED                
    int ARES_AI_ALL                     
    int ARES_AI_ADDRCONFIG              
    int ARES_AI_IDN                     
    int ARES_AI_IDN_ALLOW_UNASSIGNED    
    int ARES_AI_IDN_USE_STD3_ASCII_RULES 
    int ARES_AI_CANONIDN                
    int ARES_AI_MASK 

    int ARES_GETSOCK_MAXNUM 

    int ARES_GETSOCK_READABLE(int, int)
    int ARES_GETSOCK_WRITABLE(int, int)

    int ARES_LIB_INIT_ALL

    
    int ARES_SOCKET_BAD 

    struct ares_addrinfo:
        ares_addrinfo_cname *cnames
        ares_addrinfo_node  *nodes
        char* name

    ctypedef enum ares_bool_t:
        ARES_FALSE = 0,
        ARES_TRUE  = 1

    ctypedef void (*ares_sock_state_cb)(void *data,
                                   ares_socket_t socket_fd,
                                   int readable,
                                   int writable) with gil

    ctypedef void (*ares_callback)(void *arg,
                              int status,
                              int timeouts,
                              unsigned char *abuf,
                              int alen) with gil

    ctypedef void (*ares_host_callback)(
            # NOTE: defining hostent variable name would throw an error so I had to skip it - Vizonex  
            void *arg, int status, int timeouts, hostent*) with gil

    ctypedef void (*ares_nameinfo_callback)(void *arg,
                                       int status,
                                       int timeouts,
                                       char *node,
                                       char *service) with gil

    ctypedef int  (*ares_sock_create_callback)(ares_socket_t socket_fd,
                                          int type,
                                          void *data) with gil

    
    ctypedef struct ares_channel_t:
        pass

    struct ares_server_failover_options:
        unsigned short retry_chance
        size_t         retry_delay
    

    # Values for ARES_OPT_EVENT_THREAD
    ctypedef enum ares_evsys_t:
        # Default (best choice) event system
        ARES_EVSYS_DEFAULT = 0,
        # Win32 IOCP/AFD_POLL event system
        ARES_EVSYS_WIN32 = 1,
        # Linux epoll
        ARES_EVSYS_EPOLL = 2,
        # BSD/MacOS kqueue
        ARES_EVSYS_KQUEUE = 3,
        # POSIX poll()
        ARES_EVSYS_POLL = 4,
        # last fallback on Unix-like systems, select()
        ARES_EVSYS_SELECT = 5
    
    
    
    union _S6_ANONYMOUS_UNION:
        unsigned char _S6_u8[16]
 
    struct ares_in6_addr:
        _S6_ANONYMOUS_UNION _S6_un


    union ares_addr_union:
        in_addr       addr4
        ares_in6_addr addr6

    struct ares_addr:
        int family
        ares_addr_union addr
    
    
    struct apattern:
        ares_addr addr
        unsigned char mask


    struct ares_options:
        int flags
        int timeout # in seconds or milliseconds, depending on options
        int tries
        int ndots
        unsigned short udp_port # host byte order
        unsigned short tcp_port # host byte order
        int socket_send_buffer_size
        int socket_receive_buffer_size
        in_addr *servers
        int nservers
        char **domains
        int ndomains
        char *lookups
        ares_sock_state_cb sock_state_cb
        void *sock_state_cb_data
        apattern *sortlist
        int nsort
        int ednspsz
        char *resolvconf_path
        char *hosts_path
        int udp_max_queries
        int maxtimeout # in milliseconds
        unsigned int qcache_max_ttl # Maximum TTL for query cache, 0=disabled */
        ares_evsys_t evsys
        ares_server_failover_options server_failover_opts
  
    
    

    struct ares_addrttl:
        in_addr ipaddr
        int ttl

    struct ares_addr6ttl:
        ares_in6_addr ip6addr
        int ttl

    struct ares_caa_reply:
        ares_caa_reply  *next
        int critical
        unsigned char* property
        size_t plength
        unsigned char* value
        size_t length


    struct ares_srv_reply:
        ares_srv_reply *next
        char *host
        unsigned short priority
        unsigned short weight
        unsigned short port
    

    struct ares_mx_reply:
        ares_mx_reply *next
        char* host
        unsigned short priority
     

    struct ares_txt_reply:
        ares_txt_reply *next
        unsigned char *txt
        size_t length
    

    struct ares_txt_ext:
        ares_txt_ext      *next
        unsigned char            *txt
        size_t                   length
        unsigned char            record_start


    struct ares_naptr_reply:
        ares_naptr_reply *next
        unsigned char* flags
        unsigned char* service
        unsigned char* regexp
        char *replacement
        unsigned short order
        unsigned short preference


    struct ares_soa_reply:
        char        *nsname
        char        *hostmaster
        unsigned int serial
        unsigned int refresh
        unsigned int retry
        unsigned int expire
        unsigned int minttl
    

    # Similar to addrinfo, but with extra ttl and missing canonname.
 
    struct ares_addrinfo_node:
        int ai_ttl
        int ai_flags
        int ai_family
        int ai_socktype
        int ai_protocol
        ares_socklen_t ai_addrlen
        sockaddr *ai_addr
        ares_addrinfo_node *ai_next
    


    # alias - label of the resource record.
    # name - value (canonical name) of the resource record.
    # See RFC2181 10.1.1. CNAME terminology.

    struct ares_addrinfo_cname:
        int ttl
        char* alias
        char* name
        ares_addrinfo_cname *next
    
    
    

    struct ares_addrinfo_hints:
        int ai_flags
        int ai_family
        int ai_socktype
        int ai_protocol
    
    union ares_addr_node_union:
        in_addr       addr4
        ares_in6_addr addr6

    struct ares_addr_node:
        ares_addr_node *next
        int family
        ares_addr_node_union addr
    
    # FUNCTIONS 

    int ares_library_init(int flags)

    void ares_library_cleanup()

    const char *ares_version(int *version)

    int ares_init(ares_channel_t *channelptr)

    int ares_init_options(ares_channel_t **channelptr,
                            ares_options *options,
                                       int optmask)

    int ares_reinit(ares_channel_t* channel)

    int ares_save_options(ares_channel_t channel,
                                        ares_options *options,
                                        int *optmask)

    void ares_destroy_options(ares_options *options)

    int ares_dup(ares_channel_t *dest, ares_channel_t src)

    void ares_destroy(ares_channel_t* channel) nogil

    void ares_cancel(ares_channel_t* channel)

    void ares_set_local_ip4(ares_channel_t* channel, unsigned int local_ip)

    void ares_set_local_ip6(ares_channel_t* channel, const unsigned char* local_ip6)

    void ares_set_local_dev(ares_channel_t* channel, const char* local_dev_name)

    void ares_set_socket_callback(ares_channel_t* channel, ares_sock_create_callback callback, void *user_data)

    void ares_freeaddrinfo(ares_addrinfo* ai)

    void ares_send(ares_channel_t channel,
                                const unsigned char *qbuf,
                                int qlen,
                                ares_callback callback,
                                void *arg)

    void ares_query(ares_channel_t* channel,
                                 const char *name,
                                 int dnsclass,
                                 int type,
                                 ares_callback callback,
                                 void *arg)

    void ares_search(ares_channel_t channel,
                                  const char *name,
                                  int dnsclass,
                                  int type,
                                  ares_callback callback,
                                  void *arg)

    void ares_gethostbyname(ares_channel_t* channel,
                                         const char *name,
                                         int family,
                                         ares_host_callback callback,
                                         void *arg)

    int ares_gethostbyname_file(ares_channel_t channel,
                                             const char *name,
                                             int family,
                                            hostent **host)

    void ares_gethostbyaddr(ares_channel_t *channel,
                                         const void *addr,
                                         int addrlen,
                                         int family,
                                         ares_host_callback callback,
                                         void *arg)

    void ares_getnameinfo(ares_channel_t* channel,
                                       const sockaddr *sa,
                                       ares_socklen_t salen,
                                       int flags,
                                       ares_nameinfo_callback callback,
                                       void *arg)

    int ares_getsock(ares_channel_t* channel,
                                  ares_socket_t *socks,
                                  int numsocks)

    timeval *ares_timeout(ares_channel_t* channel,
                                            timeval *maxtv,
                                            timeval *tv)

    void ares_process_fd(ares_channel_t* channel,
                                      ares_socket_t read_fd,
                                      ares_socket_t write_fd)

    int ares_create_query(const char *name,
                                       int dnsclass,
                                       int type,
                                       unsigned short id,
                                       int rd,
                                       unsigned char **buf,
                                       int *buflen,
                                       int max_udp_size)

    int ares_mkquery(
            const char *name,
            int dnsclass,
            int type,
            unsigned short id,
            int rd,
            unsigned char **buf,
            int *buflen
    )

    int ares_expand_name(
            const unsigned char *encoded,
            const unsigned char *abuf,
            int alen,
            char **s,
            long *enclen
    )

    int ares_expand_string(
        const unsigned char *encoded,
        const unsigned char *abuf,
        int alen,
        unsigned char **s,
        long *enclen
    )

    int ares_parse_a_reply(
        const unsigned char *abuf,
        int alen,
        hostent **host,
        ares_addrttl *addrttls,
        int *naddrttls
    )

    int ares_parse_aaaa_reply(
        const unsigned char *abuf,
        int alen,
        hostent **host,
        ares_addr6ttl *addrttls,
        int *naddrttls
    )

    int ares_parse_caa_reply(
        const unsigned char* abuf,
        int alen,
        ares_caa_reply** caa_out
    )

    int ares_parse_ptr_reply(
        const unsigned char *abuf,
        int alen,
        const void *addr,
        int addrlen,
        int family,
        hostent **host
    )

    int ares_parse_ns_reply(
        const unsigned char *abuf,
        int alen,
        hostent **host
    )

    int ares_parse_srv_reply(
        const unsigned char* abuf,
        int alen,
        ares_srv_reply** srv_out
    )

    int ares_parse_mx_reply(
        const unsigned char* abuf,
        int alen,
        ares_mx_reply** mx_out)

    int ares_parse_txt_reply_ext(
        const unsigned char* abuf,
        int alen,
        ares_txt_ext** txt_out
    )

    int ares_parse_naptr_reply(
        const unsigned char* abuf,
        int alen,
        ares_naptr_reply** naptr_out
    )

    int ares_parse_soa_reply(
        const unsigned char* abuf,
        int alen,
        ares_soa_reply** soa_out
    )

    void ares_free_string(void *str)

    void ares_free_hostent(hostent *host)

    void ares_free_data(void *dataptr)

    const char *ares_strerror(int code)

    int ares_set_servers(ares_channel_t* channel, ares_addr_node *servers)

    int ares_get_servers(ares_channel_t* channel, ares_addr_node **servers)

    const char *ares_inet_ntop(int af, const void *src, char *dst,
                                            ares_socklen_t size)

    int ares_inet_pton(int af, const char *src, void *dst)

    ares_bool_t ares_threadsafety()


    # external inclusions
    unsigned short ntohs(unsigned short)


    # Meant to be safer than ares_set_servers
    int ares_set_servers_csv(ares_channel_t *channel, const char* servers)
    int ares_set_servers_ports_csv(ares_channel_t *channel, const char* servers)
    char *ares_get_servers_csv(const ares_channel_t *channel)
    

    ctypedef void (*ares_addrinfo_callback)(void *arg, int status,
                                    int timeouts,
                                    ares_addrinfo *result) noexcept with gil
 
    void ares_getaddrinfo(ares_channel_t *channel, const char *name,
                      const char* service,
                      const ares_addrinfo_hints *hints,
                      ares_addrinfo_callback callback, void *arg)

    int AF_INET
    int AF_INET6
    int AF_UNSPEC

