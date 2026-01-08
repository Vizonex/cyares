from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libc.time cimport time_t

# NOTE: If needed We can always make a seperate
# windows and unix branch

# We need private.h otherwise were screwed
cdef extern from  "ares_private.h" nogil:
    ctypedef struct ares_channeldata:
        pass
    ctypedef struct ares_addr:
        int family
        # ...
    ctypedef struct apattern:
        ares_addr addr
        unsigned char mask



cdef extern from "inc/cares_headers.h" nogil:
    """

/* hepers for ares because hostent sucks and had one job and fails it spectacularly */
typedef struct hostent hostent_t;
typedef struct ares_addrinfo ares_addrinfo_t;
#ifdef _WIN32
typedef short sa_family_t;
#endif

/* wrapper helpers for cython */
typedef void* (*cyares_amalloc)(size_t size);
typedef void (*cyares_afree)(void *ptr);
typedef void* (*cyares_arealloc)(void *ptr, size_t size);
    """
    ctypedef int h_addrtype_t
    ctypedef long suseconds_t
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

    ctypedef struct hostent_t:
        char         *h_name
        char         **h_aliases
        h_addrtype_t h_addrtype
        h_length_t   h_length
        char         **h_addr_list

    struct sockaddr:
        sa_family_t sa_family

    struct sockaddr_in:
        sa_family_t       sin_family
        in_port_t         sin_port
        in_addr           sin_addr

    struct sockaddr_in6:
        sa_family_t         sin6_family
        in_port_t           sin6_port
        uint32_t            sin6_flowinfo
        in6_addr            sin6_addr
        uint32_t            sin6_scope_id


    int INET_ADDRSTRLEN
    int INET6_ADDRSTRLEN
    int AF_INET
    int AF_INET6
    int AF_UNSPEC


    # /* DNS record types */
    ctypedef enum ares_dns_rec_type_t:
        ARES_REC_TYPE_A     = 1      #/*!< Host address. */
        ARES_REC_TYPE_NS    = 2      #/*!< Authoritative server. */
        ARES_REC_TYPE_CNAME = 5      #/*!< Canonical name. */
        ARES_REC_TYPE_SOA   = 6      #/*!< Start of authority zone. */
        ARES_REC_TYPE_PTR   = 12     #/*!< Domain name pointer. */
        ARES_REC_TYPE_HINFO = 13     #/*!< Host information. */
        ARES_REC_TYPE_MX    = 15     #/*!< Mail routing information. */
        ARES_REC_TYPE_TXT   = 16     #/*!< Text strings. */
        ARES_REC_TYPE_SIG   = 24     #/*!< RFC 2535 / RFC 2931. SIG Record */
        ARES_REC_TYPE_AAAA  = 28     #/*!< RFC 3596. Ip6 Address. */
        ARES_REC_TYPE_SRV   = 33     #/*!< RFC 2782. Server Selection. */
        ARES_REC_TYPE_NAPTR = 35     #/*!< RFC 3403. Naming Authority Pointer */
        ARES_REC_TYPE_OPT   = 41     #/*!< RFC 6891. EDNS0 option (meta-RR) */
        
        ARES_REC_TYPE_TLSA = 52      #/*!< RFC 6698. DNS-Based Authentication of Named
                                     # *   Entities (DANE) Transport Layer Security
                                     # *   (TLS) Protocol: TLSA */
        ARES_REC_TYPE_SVCB  = 64     #/*!< RFC 9460. General Purpose Service Binding */
        ARES_REC_TYPE_HTTPS = 65     #/*!< RFC 9460. Service Binding type for use with
                                     # *   HTTPS */
        ARES_REC_TYPE_ANY = 255      #/*!< Wildcard match.  Not response RR. */
        ARES_REC_TYPE_URI = 256      #/*!< RFC 7553. Uniform Resource Identifier */
        ARES_REC_TYPE_CAA = 257      #/*!< RFC 6844. Certification Authority
                                     # *   Authorization. */
        ARES_REC_TYPE_RAW_RR = 65536 #/*!< Used as an indicator that the RR record
                                     # *   is not parsed, but provided in wire
                                     # *   format */

    # DNS classes
    ctypedef enum ares_dns_class_t:
        ARES_CLASS_IN = 1
        ARES_CLASS_CHAOS = 3
        ARES_CLASS_HESOID = 4
        ARES_CLASS_NONE = 254
        ARES_CLASS_ANY = 255

    # DNS sections
    ctypedef enum ares_dns_section_t:
        ARES_SECTION_ANSWER = 1
        ARES_SECTION_AUTHORITY = 2
        ARES_SECTION_ADDITIONAL = 3

    ctypedef enum ares_dns_opcode_t:
        ARES_OPCODE_QUERY = 0
        ARES_OPCODE_IQUERY = 1
        ARES_OPCODE_STATUS = 2
        ARES_OPCODE_NOTIFY = 4
        ARES_OPCODE_UPDATE = 5

    # /* DNS Response codes */
    ctypedef enum ares_dns_rcode_t:
        ARES_RCODE_NOERROR = 0
        ARES_RCODE_FORMERR = 1
        ARES_RCODE_SERVFAIL = 2
        ARES_RCODE_NXDOMAIN = 3
        ARES_RCODE_NOTIMP = 4
        ARES_RCODE_REFUSED = 5
        ARES_RCODE_YXDOMAIN = 6
        ARES_RCODE_YXRRSET = 7
        ARES_RCODE_NXRRSET = 8
        ARES_RCODE_NOTAUTH = 9
        ARES_RCODE_NOTZONE = 10
        ARES_RCODE_DSOTYPEI = 11
        ARES_RCODE_BADSIG = 16
        ARES_RCODE_BADKEY = 17
        ARES_RCODE_BADTIME = 18
        ARES_RCODE_BADMODE = 19
        ARES_RCODE_BADNAME = 20
        ARES_RCODE_BADALG = 21
        ARES_RCODE_BADTRUNC = 22
        ARES_RCODE_BADCOOKIE = 23

    # DNS Header flags
    ctypedef enum ares_dns_flags_t:
        ARES_FLAG_QR
        ARES_FLAG_AA
        ARES_FLAG_TC
        ARES_FLAG_RD
        ARES_FLAG_RA
        ARES_FLAG_AD
        ARES_FLAG_CD

    # /* DNS RR keys for accessing record fields */
    ctypedef enum ares_dns_rr_key_t:
        # /* A record */
        ARES_RR_A_ADDR = 1

        # /* AAAA record */
        ARES_RR_AAAA_ADDR = 1

        # /* NS record */
        ARES_RR_NS_NSDNAME = 1

        # /* CNAME record */
        ARES_RR_CNAME_CNAME = 1


        # /* HINFO Record */
        ARES_RR_HINFO_CPU = 1301
        ARES_RR_HINFO_OS = 1302

        # /* SOA record */
        ARES_RR_SOA_MNAME = 1
        ARES_RR_SOA_RNAME = 2
        ARES_RR_SOA_SERIAL = 3
        ARES_RR_SOA_REFRESH = 4
        ARES_RR_SOA_RETRY = 5
        ARES_RR_SOA_EXPIRE = 6
        ARES_RR_SOA_MINIMUM = 7

        # /* PTR record */
        ARES_RR_PTR_DNAME = 1

        # /* MX record */
        ARES_RR_MX_PREFERENCE = 1
        ARES_RR_MX_EXCHANGE = 2

        # /* TXT record */
        ARES_RR_TXT_DATA = 1

        # /* SRV record */
        ARES_RR_SRV_PRIORITY = 1
        ARES_RR_SRV_WEIGHT = 2
        ARES_RR_SRV_PORT = 3
        ARES_RR_SRV_TARGET = 4

        # /* NAPTR record */
        ARES_RR_NAPTR_ORDER = 1
        ARES_RR_NAPTR_PREFERENCE = 2
        ARES_RR_NAPTR_FLAGS = 3
        ARES_RR_NAPTR_SERVICES = 4
        ARES_RR_NAPTR_REGEXP = 5
        ARES_RR_NAPTR_REPLACEMENT = 6

        # /* CAA record */
        ARES_RR_CAA_CRITICAL = 1
        ARES_RR_CAA_TAG = 2
        ARES_RR_CAA_VALUE = 3

        # /* TLSA record */
        ARES_RR_TLSA_CERT_USAGE = 5201
        ARES_RR_TLSA_SELECTOR = 5202
        ARES_RR_TLSA_MATCH = 5203
        ARES_RR_TLSA_DATA = 5204

        # /* HTTPS record */
        ARES_RR_HTTPS_PRIORITY = 6501
        ARES_RR_HTTPS_TARGET = 6502
        ARES_RR_HTTPS_PARAMS = 6503

        # /* URI record */
        ARES_RR_URI_PRIORITY = 25601
        ARES_RR_URI_WEIGHT = 25602
        ARES_RR_URI_TARGET = 25603

        # Isn't in pycares yet, found it while debugging...
        # /* OPT Record */
        ARES_RR_OPT_UDP_SIZE = 4101
        ARES_RR_OPT_VERSION = 4103
        ARES_RR_OPT_FLAGS = 4104
        ARES_RR_OPT_OPTIONS = 4105

        # /* SIG Record */
        ARES_RR_SIG_TYPE_COVERED  = 2401
        ARES_RR_SIG_ALGORITHM = 2402
        ARES_RR_SIG_LABELS = 2403
        ARES_RR_SIG_ORIGINAL_TTL = 2404,
        ARES_RR_SIG_EXPIRATION = 2405,
        ARES_RR_SIG_INCEPTION = 2406,
        ARES_RR_SIG_KEY_TAG = 2407,
        # /*! SIG Record. Signers Name. Datatype: NAME */
        ARES_RR_SIG_SIGNERS_NAME = 2408,
        # /*! SIG Record. Signature. Datatype: BIN */
        ARES_RR_SIG_SIGNATURE = 2409,


        #  /* SVCB Record */
        ARES_RR_SVCB_PRIORITY = 6401
        ARES_RR_SVCB_TARGET = 6402
        ARES_RR_SVCB_PARAMS = 6403



    # /* Opaque DNS record structures */
    ctypedef struct ares_dns_record:
        pass
    ctypedef struct ares_dns_rr_t:
        pass

    ctypedef int ares_socket_t
    ctypedef int ares_socklen_t

    int ARES_FLAG_USEVC
    int ARES_FLAG_PRIMARY
    int ARES_FLAG_IGNTC
    int ARES_FLAG_NORECURSE
    int ARES_FLAG_STAYOPEN
    int ARES_FLAG_NOSEARCH
    int ARES_FLAG_NOALIASES
    int ARES_FLAG_NOCHECKRESP
    int ARES_FLAG_EDNS
    int ARES_FLAG_NO_DFLT_SVR

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

    int ARES_LIB_INIT_ALL

    int ARES_SOCKET_BAD

    ctypedef enum ares_bool_t:
        ARES_FALSE = 0
        ARES_TRUE  = 1


    ctypedef enum ares_status_t:
        ARES_SUCCESS = 0

        # /* Server error codes (ARES_ENODATA indicates no relevant answer) */
        ARES_ENODATA   = 1
        ARES_EFORMERR  = 2
        ARES_ESERVFAIL = 3
        ARES_ENOTFOUND = 4
        ARES_ENOTIMP   = 5
        ARES_EREFUSED  = 6

        # /* Locally generated error codes */
        ARES_EBADQUERY    = 7
        ARES_EBADNAME     = 8
        ARES_EBADFAMILY   = 9
        ARES_EBADRESP     = 10
        ARES_ECONNREFUSED = 11
        ARES_ETIMEOUT     = 12
        ARES_EOF          = 13
        ARES_EFILE        = 14
        ARES_ENOMEM       = 15
        ARES_EDESTRUCTION = 16
        ARES_EBADSTR      = 17

        # /* ares_getnameinfo error codes */
        ARES_EBADFLAGS = 18

        # /* ares_getaddrinfo error codes */
        ARES_ENONAME   = 19
        ARES_EBADHINTS = 20

        # /* Uninitialized library error code */
        ARES_ENOTINITIALIZED = 21 # /* introduced in 1.7.0 */

        # /* ares_library_init error codes */
        ARES_ELOADIPHLPAPI         = 22 # /* introduced in 1.7.0 */
        ARES_EADDRGETNETWORKPARAMS = 23 # /* introduced in 1.7.0 */

        # /* More error codes */
        ARES_ECANCELLED = 24 # /* introduced in 1.7.0 */

        # /* More ares_getaddrinfo error codes */
        ARES_ESERVICE = 25 #/* ares_getaddrinfo() was passed a text service name that
                       # * is not recognized. introduced in 1.16.0 */

        ARES_ENOSERVER = 26 # /* No DNS servers were configured */



    ctypedef struct ares_dns_record_t:
        pass

    ctypedef void (*ares_sock_state_cb)(void *data,
                                   ares_socket_t socket_fd,
                                   int readable,
                                   int writable) noexcept with gil

    ctypedef void (*ares_callback_dnsrec)(
            void *arg, ares_status_t status, size_t timeouts,
            const ares_dns_record_t *dnsrec) noexcept with gil

    ctypedef void (*ares_host_callback)(void *arg,
                                   int status,
                                   int timeouts,
                                   hostent_t *hostent) noexcept with gil

    ctypedef void (*ares_nameinfo_callback)(void *arg,
                                    int status,
                                    int timeouts,
                                    char *node,
                                    char *service) noexcept with gil

    ctypedef int  (*ares_sock_create_callback)(ares_socket_t socket_fd,
                                          int type,
                                          void *data) noexcept with gil

    ctypedef void (*ares_addrinfo_callback)(
                        void *arg,
                        int status,
                        int timeouts,
                        ares_addrinfo_t *res # type: ignore
                ) noexcept with gil


    ctypedef struct ares_channel_t:
        pass


    ctypedef struct ares_server_failover_options:
            unsigned short retry_chance
            size_t         retry_delay

        # /*! Values for ARES_OPT_EVENT_THREAD */
    ctypedef enum ares_evsys_t:
        # /*! Default (best choice) event system */
        ARES_EVSYS_DEFAULT = 0
        # /*! Win32 IOCP/AFD_POLL event system */
        ARES_EVSYS_WIN32 = 1
        # /*! Linux epoll */
        ARES_EVSYS_EPOLL = 2
        # /*! BSD/MacOS kqueue */
        ARES_EVSYS_KQUEUE = 3
        # /*! POSIX poll() */
        ARES_EVSYS_POLL = 4
        # /*! last fallback on Unix-like systems, select() */
        ARES_EVSYS_SELECT = 5

    struct ares_options:
        int flags
        int timeout # in seconds or milliseconds, depending on options */
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
        unsigned int qcache_max_ttl # Maximum TTL for query cache, 0=disabled
        ares_evsys_t evsys
        ares_server_failover_options server_failover_opts

    union _S6_union_anon:
        unsigned char _S6_u8[16]

    struct ares_in6_addr:
        _S6_union_anon _S6_un

    ctypedef struct ares_addrttl:
        in_addr ipaddr
        int ttl

    ctypedef struct ares_addr6ttl:
        ares_in6_addr ip6addr
        int             ttl


    ctypedef struct ares_caa_reply:
        ares_caa_reply  *next
        int critical
        unsigned char *property
        size_t plength
        unsigned char *value
        size_t length

    ctypedef struct ares_srv_reply:
        ares_srv_reply  *next
        char                   *host
        unsigned short          priority
        unsigned short          weight
        unsigned short          port


    ctypedef struct ares_mx_reply:
        ares_mx_reply   *next
        char                   *host
        unsigned short          priority


    ctypedef struct ares_txt_reply:
        ares_txt_reply  *next
        unsigned char          *txt
        size_t                  length


    ctypedef struct ares_txt_ext:
        ares_txt_ext      *next
        unsigned char     *txt
        size_t            length
        unsigned char     record_start


    ctypedef struct ares_naptr_reply:
        ares_naptr_reply *next
        unsigned char           *flags
        unsigned char           *service
        unsigned char           *regexp
        char                    *replacement
        unsigned short           order
        unsigned short           preference


    ctypedef struct ares_soa_reply:
      char        *nsname
      char        *hostmaster
      unsigned int serial
      unsigned int refresh
      unsigned int retry
      unsigned int expire
      unsigned int minttl

    # /*
    #  * Similar to addrinfo, but with extra ttl and missing canonname.
    #  */
    struct ares_addrinfo_node:
        int                        ai_ttl
        int                        ai_flags
        int                        ai_family
        int                        ai_socktype
        int                        ai_protocol
        ares_socklen_t             ai_addrlen
        sockaddr           *ai_addr
        ares_addrinfo_node *ai_next

    # /*
    #  * alias - label of the resource record.
    #  * name - value (canonical name) of the resource record.
    #  * See RFC2181 10.1.1. CNAME terminology.
    #  */
    struct ares_addrinfo_cname:
        int  ttl
        char *alias
        char *name
        ares_addrinfo_cname *next

    ctypedef struct ares_addrinfo_t:
        ares_addrinfo_cname *cnames
        ares_addrinfo_node  *nodes


    struct ares_addrinfo_hints:
        int ai_flags
        int ai_family
        int ai_socktype
        int ai_protocol

    int ares_library_init(int flags)

    void ares_library_cleanup()

    const char *ares_version(int *version)

    int ares_init_options(ares_channel_t **channelptr,
                ares_options *options,
                                       int optmask)

    int ares_reinit(ares_channel_t* channel)

    int ares_save_options(
                ares_channel_t* channel,
                ares_options *options,
                int *optmask)

    void ares_destroy_options(ares_options *options)

    int ares_dup(ares_channel_t *dest, ares_channel_t src)

    void ares_destroy(ares_channel_t* channel)

    void ares_cancel(ares_channel_t* channel)

    void ares_set_local_ip4(ares_channel_t* channel, unsigned int local_ip)

    void ares_set_local_ip6(ares_channel_t* channel,
                                         const unsigned char* local_ip6)

    void ares_set_local_dev(ares_channel_t* channel,
                                         const char* local_dev_name)

    void ares_set_socket_callback(ares_channel_t* channel,
                                               ares_sock_create_callback callback,
                                               void *user_data)

    void ares_getaddrinfo(ares_channel_t* channel,
                                   const char* node,
                                   const char* service,
                                   const ares_addrinfo_hints* hints,
                                   ares_addrinfo_callback callback,
                                   void* arg)

    void ares_freeaddrinfo(ares_addrinfo_t* ai)

    # New DNS record API
    ares_status_t ares_query_dnsrec(ares_channel_t* channel,
                                const char *name,
                                ares_dns_class_t dnsclass,
                                ares_dns_rec_type_t type,
                                ares_callback_dnsrec callback,
                                void *arg,
                                unsigned short *qid)

    ares_status_t ares_search_dnsrec(ares_channel_t* channel,
                                 const ares_dns_record_t *dnsrec,
                                 ares_callback_dnsrec callback,
                                 void *arg)

    ares_status_t ares_dns_record_create(ares_dns_record_t **dnsrec,
                                     unsigned short id,
                                     unsigned short flags,
                                     ares_dns_opcode_t opcode,
                                     ares_dns_rcode_t rcode)

    ares_status_t ares_dns_record_query_add(ares_dns_record_t *dnsrec,
                                        const char *name,
                                        ares_dns_rec_type_t qtype,
                                        ares_dns_class_t qclass)

    void ares_dns_record_destroy(ares_dns_record_t *dnsrec)

    size_t ares_dns_record_rr_cnt(const ares_dns_record_t *dnsrec,
                              ares_dns_section_t sect)

    const ares_dns_rr_t *ares_dns_record_rr_get_const(const ares_dns_record_t *dnsrec,
                                                  ares_dns_section_t sect,
                                                  size_t idx)

    const char *ares_dns_rr_get_name(const ares_dns_rr_t *rr)

    ares_dns_rec_type_t ares_dns_rr_get_type(const ares_dns_rr_t *rr)

    ares_dns_class_t ares_dns_rr_get_class(const ares_dns_rr_t *rr)

    unsigned int ares_dns_rr_get_ttl(const ares_dns_rr_t *rr)

    # Record data accessors
    const in_addr *ares_dns_rr_get_addr(const ares_dns_rr_t *rr,
                                           ares_dns_rr_key_t key)

    const ares_in6_addr *ares_dns_rr_get_addr6(const ares_dns_rr_t *rr,
                                                ares_dns_rr_key_t key)

    const char *ares_dns_rr_get_str(const ares_dns_rr_t *rr,
                               ares_dns_rr_key_t key)

    unsigned char ares_dns_rr_get_u8(const ares_dns_rr_t *rr,
                                ares_dns_rr_key_t key)

    unsigned short ares_dns_rr_get_u16(const ares_dns_rr_t *rr,
                                  ares_dns_rr_key_t key)

    unsigned int ares_dns_rr_get_u32(const ares_dns_rr_t *rr,
                                ares_dns_rr_key_t key)

    const unsigned char *ares_dns_rr_get_bin(const ares_dns_rr_t *rr,
                                        ares_dns_rr_key_t key,
                                        size_t *len)

    size_t ares_dns_rr_get_abin_cnt(const ares_dns_rr_t *rr,
                               ares_dns_rr_key_t key)

    const unsigned char *ares_dns_rr_get_abin(const ares_dns_rr_t *rr,
                                         ares_dns_rr_key_t key,
                                         size_t idx,
                                         size_t *len)

    size_t ares_dns_rr_get_opt_cnt(const ares_dns_rr_t *dns_rr,
                               ares_dns_rr_key_t key)

    unsigned short ares_dns_rr_get_opt(const ares_dns_rr_t *dns_rr,
                                   ares_dns_rr_key_t key,
                                   size_t idx,
                                   const unsigned char **val,
                                   size_t *val_len)

    void ares_gethostbyaddr(ares_channel_t* channel,
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

    timeval *ares_timeout(ares_channel_t* channel,
                        timeval *maxtv,
                        timeval *tv)

    void ares_process_fd(ares_channel_t* channel,
                                      ares_socket_t read_fd,
                                      ares_socket_t write_fd)

    void ares_free_string(void *str)

    void ares_free_hostent(hostent_t *host)

    void ares_free_data(void *dataptr)

    const char *ares_strerror(int code)

    int ares_set_servers_csv(ares_channel_t* channel, const char *servers)

    char *ares_get_servers_csv(const ares_channel_t* channel)

    const char *ares_inet_ntop(int af, const void *src, char *dst,
                                            ares_socklen_t size)

    int ares_inet_pton(int af, const char *src, void *dst)

    bint ares_threadsafety()

    ares_status_t ares_queue_wait_empty(ares_channel_t* channel, int timeout_ms)

    # Definitions here are not derrived out of pycares's own handbook and we need these 
    # so we don't need a leaky thread daemon
    
    size_t ares_queue_active_queries(const ares_channel_t *channel)

    # Introduced in cyares 0.1.8 
    # typedefs are to bypass cyright's 
    # annoyance with type definitions.
    ctypedef void* (*cyares_amalloc)(size_t size) nogil
    ctypedef void (*cyares_afree)(void *ptr) nogil
    ctypedef void* (*cyares_arealloc)(void *ptr, size_t size) nogil
    int ares_library_init_mem(
        int flags,
        cyares_amalloc amalloc,
        cyares_afree afree,
        cyares_arealloc arealloc
    )