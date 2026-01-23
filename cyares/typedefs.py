from typing import TypeVar

from .channel import (
    QUERY_CLASS_ANY,
    QUERY_CLASS_CHAOS,
    QUERY_CLASS_HS,
    QUERY_CLASS_IN,
    QUERY_CLASS_NONE,
    QUERY_TYPE_A,
    QUERY_TYPE_AAAA,
    QUERY_TYPE_ANY,
    QUERY_TYPE_CAA,
    QUERY_TYPE_CNAME,
    QUERY_TYPE_HINFO,
    QUERY_TYPE_HTTPS,
    QUERY_TYPE_MX,
    QUERY_TYPE_NAPTR,
    QUERY_TYPE_NS,
    QUERY_TYPE_OPT,
    QUERY_TYPE_PTR,
    QUERY_TYPE_SIG,
    QUERY_TYPE_SOA,
    QUERY_TYPE_SRV,
    QUERY_TYPE_SVCB,
    QUERY_TYPE_TLSA,
    QUERY_TYPE_TXT,
    QUERY_TYPE_URI,
)

_T = TypeVar("_T")


class CancelledError(Exception):
    pass


# class ClosedResolverError(Exception):
#     """DNS Resolver was closed and cannot accept more queries to be made"""


query_type_map: dict[str, int] = {
    "A": QUERY_TYPE_A,
    "AAAA": QUERY_TYPE_AAAA,
    "ANY": QUERY_TYPE_ANY,
    "CAA": QUERY_TYPE_CAA,
    "CNAME": QUERY_TYPE_CNAME,
    "HTTPS": QUERY_TYPE_HTTPS,
    "MX": QUERY_TYPE_MX,
    "NAPTR": QUERY_TYPE_NAPTR,
    "NS": QUERY_TYPE_NS,
    "PTR": QUERY_TYPE_PTR,
    "SOA": QUERY_TYPE_SOA,
    "SRV": QUERY_TYPE_SRV,
    "TLSA": QUERY_TYPE_TLSA,
    "TXT": QUERY_TYPE_TXT,
    "HINFO": QUERY_TYPE_HINFO,
    "URI": QUERY_TYPE_URI,
    "SVCB": QUERY_TYPE_SVCB,
    "OPT": QUERY_TYPE_OPT,
    "SIG": QUERY_TYPE_SIG,
}

query_class_map: dict[str, int] = {
    "IN": QUERY_CLASS_IN,
    "CHAOS": QUERY_CLASS_CHAOS,
    "HS": QUERY_CLASS_HS,
    "NONE": QUERY_CLASS_NONE,
    "ANY": QUERY_CLASS_ANY,
}

__all__ = (
    "_T",
    "CancelledError",
    "query_type_map",
    "query_class_map",
)
