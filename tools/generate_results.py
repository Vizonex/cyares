# Python Script to Generate ares_query_results and callbacks
# See _tempita_compat for the 2 fallbacks

# I'll see if pycares devs wants their own copy if they want to move
# or try this as well.... - Vizonex

from _tempita_compat import Template, TemplateError
import typing

# I prefer MultiDict[...] over dict[str, list[...]]
# since it has a better system
from multidict import MultiDict
from enum import IntEnum

# we will use multidict for collecting up the main Record Types
# by string to handle sorting from the different ARES Enums
# in ares_dns_rr_key_t

# When searching or querying with ANY We will use a different
# callback with all the callbacks in a if-chain
# when cython updates and allows for match statements or when
# Python 3.9 hits End Of Life We can swap to match statements
# in the ANY Callback


class DataType(IntEnum):
    # ADDR (ipv4 host) - (bytes)
    ADDR = 0
    # ADDR6 (ipv6 host) - (bytes)
    ADDR6 = 1
    # char* (bytes)
    NAME = 2
    # uint8_t
    U8 = 3
    # uint16_t
    U16 = 4
    # uint32_t
    U32 = 5
    # char* (bytes)
    STR = 6
    # uchar* & size_t (unicode)
    ABINP = 7
    # uchar* (unicode)
    BIN = 8
    # unsigned short (OPT)
    OPT = 9
    # uchar*
    BINP = 10


ADDR = DataType.ADDR
ADDR6 = DataType.ADDR6
NAME = DataType.NAME
U8 = DataType.U8
U16 = DataType.U16
U32 = DataType.U32
STR = DataType.STR
BIN = DataType.BIN
ABINP = DataType.ABINP
OPT = DataType.OPT
BINP = DataType.BINP

CYTHON_DICT_CONV = {
    ADDR: "bytes",
    ADDR6: "bytes",
    NAME: "bytes",
    U8: "uint8_t",
    U16: "uint16_t",
    U32: "uint32_t",
    BIN: "str",
    OPT: "uint16_t",
    BINP: "str"
}

# NOTE: PYX_TEMPLATE SHOULD HAVE ares_dns_rr_get_opt set as 
#   cyares_dns_rr_get_opt


RR_KEYS: list[tuple[str, DataType]] = [
    # A Record. Address. Datatype: INADDR
    ("ARES_RR_A_ADDR", ADDR),  # ipv4
    # NS Record. Name. Datatype: NAME
    ("ARES_RR_NS_NSDNAME", NAME),
    # CNAME Record. CName. Datatype: NAME
    ("ARES_RR_CNAME_CNAME", NAME),
    # SOA Record. MNAME, Primary Source of Data. Datatype: NAME
    ("ARES_RR_SOA_MNAME", NAME),
    # SOA Record. RNAME, Mailbox of person responsible. Datatype: NAME
    ("ARES_RR_SOA_RNAME", NAME),
    # SOA Record. Serial, version. Datatype: U32
    ("ARES_RR_SOA_SERIAL", U32),
    # SOA Record. Refresh, zone refersh interval. Datatype: U32
    ("ARES_RR_SOA_REFRESH", U32),
    # SOA Record. Retry, failed refresh retry interval. Datatype: U32
    ("ARES_RR_SOA_RETRY", U32),
    # SOA Record. Expire, upper limit on authority. Datatype: U32
    ("ARES_RR_SOA_EXPIRE", U32),
    # SOA Record. Minimum, RR TTL. Datatype: U32
    ("ARES_RR_SOA_MINIMUM", U32),
    # PTR Record. DNAME, pointer domain. Datatype: NAME
    ("ARES_RR_PTR_DNAME", NAME),
    # HINFO Record. CPU. Datatype: STR
    ("ARES_RR_HINFO_CPU", STR),
    # HINFO Record. OS. Datatype: STR
    ("ARES_RR_HINFO_OS", STR),
    # MX Record. Preference. Datatype: U16
    ("ARES_RR_MX_PREFERENCE", U16),
    # MX Record. Exchange, domain. Datatype: NAME
    ("ARES_RR_MX_EXCHANGE", NAME),
    # TXT Record. Data. Datatype: ABINP
    ("ARES_RR_TXT_DATA", ABINP),
    # SIG Record. Type Covered. Datatype: U16
    ("ARES_RR_SIG_TYPE_COVERED", U16),
    # SIG Record. Algorithm. Datatype: U8
    ("ARES_RR_SIG_ALGORITHM", U8),
    # SIG Record. Labels. Datatype: U8
    ("ARES_RR_SIG_LABELS", U8),
    # SIG Record. Original TTL. Datatype: U32
    ("ARES_RR_SIG_ORIGINAL_TTL", U32),
    # SIG Record. Signature Expiration. Datatype: U32
    ("ARES_RR_SIG_EXPIRATION", U32),
    # SIG Record. Signature Inception. Datatype: U32
    ("ARES_RR_SIG_INCEPTION", U32),
    # SIG Record. Key Tag. Datatype: U16
    ("ARES_RR_SIG_KEY_TAG", U16),
    # SIG Record. Signers Name. Datatype: NAME
    ("ARES_RR_SIG_SIGNERS_NAME", NAME),
    # SIG Record. Signature. Datatype: BIN
    ("ARES_RR_SIG_SIGNATURE", BIN),
    # AAAA Record. Address. Datatype: INADDR6
    ("ARES_RR_AAAA_ADDR", ADDR6),
    # SRV Record. Priority. Datatype: U16
    ("ARES_RR_SRV_PRIORITY", U16),
    # SRV Record. Weight. Datatype: U16
    ("ARES_RR_SRV_WEIGHT", U16),
    # SRV Record. Port. Datatype: U16
    ("ARES_RR_SRV_PORT", U16),
    # SRV Record. Target domain. Datatype: NAME
    ("ARES_RR_SRV_TARGET", NAME),
    # NAPTR Record. Order. Datatype: U16
    ("ARES_RR_NAPTR_ORDER", U16),
    # NAPTR Record. Preference. Datatype: U16
    ("ARES_RR_NAPTR_PREFERENCE", U16),
    # NAPTR Record. Flags. Datatype: STR
    ("ARES_RR_NAPTR_FLAGS", STR),
    # NAPTR Record. Services. Datatype: STR
    ("ARES_RR_NAPTR_SERVICES", STR),
    # NAPTR Record. Regexp. Datatype: STR
    ("ARES_RR_NAPTR_REGEXP", STR),
    # NAPTR Record. Replacement. Datatype: NAME
    ("ARES_RR_NAPTR_REPLACEMENT", NAME),
    # OPT Record. UDP Size. Datatype: U16
    ("ARES_RR_OPT_UDP_SIZE", U16),
    # OPT Record. Version. Datatype: U8
    ("ARES_RR_OPT_VERSION", U8),
    # OPT Record. Flags. Datatype: U16
    ("ARES_RR_OPT_FLAGS", U16),
    # OPT Record. Options. Datatype: OPT
    ("ARES_RR_OPT_OPTIONS", OPT),
    # TLSA Record. Certificate Usage. Datatype: U8
    ("ARES_RR_TLSA_CERT_USAGE", U8),
    # TLSA Record. Selector. Datatype: U8
    ("ARES_RR_TLSA_SELECTOR", U8),
    # TLSA Record. Matching Type. Datatype: U8
    ("ARES_RR_TLSA_MATCH", U8),
    # TLSA Record. Certificate Association Data. Datatype: BIN
    ("ARES_RR_TLSA_DATA", BIN),
    # SVCB Record. SvcPriority. Datatype: U16
    ("ARES_RR_SVCB_PRIORITY", U16),
    # SVCB Record. TargetName. Datatype: NAME
    ("ARES_RR_SVCB_TARGET", NAME),
    # SVCB Record. SvcParams. Datatype: OPT
    ("ARES_RR_SVCB_PARAMS", OPT),
    # HTTPS Record. SvcPriority. Datatype: U16
    ("ARES_RR_HTTPS_PRIORITY", U16),
    # HTTPS Record. TargetName. Datatype: NAME
    ("ARES_RR_HTTPS_TARGET", NAME),
    # HTTPS Record. SvcParams. Datatype: OPT
    ("ARES_RR_HTTPS_PARAMS", OPT),
    # URI Record. Priority. Datatype: U16
    ("ARES_RR_URI_PRIORITY", U16),
    # URI Record. Weight. Datatype: U16
    ("ARES_RR_URI_WEIGHT", U16),
    # URI Record. Target domain. Datatype: NAME
    ("ARES_RR_URI_TARGET", NAME),
    # CAA Record. Critical flag. Datatype: U8
    ("ARES_RR_CAA_CRITICAL", U8),
    # CAA Record. Tag/Property. Datatype: STR
    ("ARES_RR_CAA_TAG", STR),
    # CAA Record. Value. Datatype: BINP
    ("ARES_RR_CAA_VALUE", BINP),
    # RAW Record. RR Type. Datatype: U16
    ("ARES_RR_RAW_RR_TYPE", U16),
    # RAW Record. RR Data. Datatype: BIN
    ("ARES_RR_RAW_RR_DATA", BIN),
]
# Sorted by ATTR & DATATYPE, CYTHON_TYPE for the entries and RR_TYPE FOR THE KEYS
# This is why multidict was chosen for this job of sorting...
RESULT_DATA: MultiDict[tuple[str, DataType, str]] = MultiDict()

for s in RR_KEYS:
    TYPE, ATTR = s[0].replace("ARES_RR_", "").split("_", 1)
    RESULT_DATA.add(TYPE, (ATTR, s[1]))



RR_TYPES = frozenset(RESULT_DATA.keys())
LOWER_CASE_DATA_TYPES = frozenset(map(lambda x:x.lower(), RR_TYPES))


# Documentation for Tempita Here: https://pyrocore.readthedocs.io/en/latest/tempita.html

PXD_TEMPLATE = Template(
"""
# cython: freethreading_compatible = True
#
# WARNING: THIS CODE IS AUTOGENERATED BY tools/generate_results.py 
# In the CYARES GITHUB REPO. TO MODIFY GO TO tools/generate_results.py 
# AND EDIT THE CODE!
#
# GENERATED: {{DATE}} 
# AUTHOR: {{AUTHOR}}

from cpython.bytes cimport (
    PyBytes_AS_STRING, 
    PyBytes_FromString,
    PyBytes_FromStringAndSize
)

cimport cython
from libc.stdint cimport uint8_t, uint16_t, uint32_t


from .ares cimport *
from .inc cimport (
    cyares_unicode_from_uchar_and_size,
    cyares_unicode_from_uchar
)


cdef class AresResult:
    cdef tuple _attrs

# === CUSTOM INLINE FUNCTIONS === 

cdef inline bytes cyares_dns_rr_get_bytes(
    const ares_dns_rr_t* dns_rr, ares_dns_rr_key_t key
):
    return PyBytes_FromString(ares_dns_rr_get_str(dns_rr, key))

cdef inline str cyares_dns_rr_get_abin(
    const ares_dns_rr_t* dns_rr, ares_dns_rr_key_t key
):
    return cyares_unicode_from_uchar(ares_dns_rr_get_abin(rr, key, ))

# === BASE CLASS === 

cdef class AresResult:
    cdef tuple _attrs

# XXX: txt_result can't be autogenerated due to it's nature...
cdef class ares_query_txt_result(AresResult):
    cdef:
        readonly bytes text
        readonly int ttl

    @staticmethod
    cdef ares_query_txt_result old_new(ares_txt_ext* txt_chunk)

    @staticmethod
    cdef ares_query_txt_result from_object(ares_query_txt_result obj)

    @staticmethod
    cdef inline ares_query_txt_result new(const ares_dns_rr_t* rr, size_t idx):
        cdef size_t len
        cdef ares_query_txt_result r = ares_query_txt_result.__new__(ares_query_txt_result)
        cdef char* data = <char*>ares_dns_rr_get_abin(rr, ARES_RR_TXT_DATA, idx, &len)
        r.text = PyBytes_FromStringAndSize(data, <Py_ssize_t>len)
        r.ttl = -1
        r._attrs = ('text', 'ttl')
        return r
  

# This one is a little bit more custom than the rest so 
# Making a special class specifically for it was the way to go

cdef class ares_opt_result(AresResult):
    cdef:
        readonly str val
        readonly uint16_t id

    @staticmethod 
    cdef inline ares_opt_result new(
        const ares_dns_rr_t* dns_rr, 
        ares_dns_rr_key_t key,
        size_t idx
    ):
        cdef size_t len
        cdef const uint8_t* cstr
        cdef ares_opt_result r = ares_opt_result.__new__(ares_opt_result)
        r.id = ares_dns_rr_get_opt(dns_rr, key, idx, &cstr, &len)
        r.val = cyares_unicode_from_uchar_and_size(cstr, <Py_ssize_t>len)
        r._attrs = ("id", "val")
        return r

# We should stay true to pycares in some ways so the class names
# Are the same format, some result class names are changed to 
# stay true to c-ares - Vizonex

{{for k in LOWER_CASE_TYPES}}
cdef class ares_query_{{k}}_result(AresResult)
    {{for pytype, RESULT_DATA.getall()}}
    cdef readonly {{}}
    {{endfor}}

{{endfor}}


"""
)






