#ifndef __cyares_ERR_LOOKUP_H__
#define __cyares_ERR_LOOKUP_H__

#include <Python.h>
#include <ares.h>

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

// CYARES NOTE: I Learned this macro technique from llhttp / libuv - Vizonex

#define CYARES_ERROR_CODES(XX) \
    XX(ARES_SUCCESS, "Successful completion") \
    XX(ARES_ENODATA, "DNS server returned answer with no data") \
    XX(ARES_EFORMERR, "DNS server claims query was misformatted") \
    XX(ARES_ESERVFAIL, "DNS server returned general failure") \
    XX(ARES_ENOTFOUND, "Domain name not found") \
    XX(ARES_ENOTIMP, "DNS server does not implement requested operation") \
    XX(ARES_EREFUSED, "DNS server refused query") \
    XX(ARES_EBADQUERY, "Misformatted DNS query") \
    XX(ARES_EBADNAME,  "Misformatted domain name") \
    XX(ARES_EBADFAMILY, "Unsupported address family") \
    XX(ARES_EBADRESP, "Misformatted DNS reply") \
    XX(ARES_ECONNREFUSED, "Could not contact DNS servers") \
    XX(ARES_ETIMEOUT, "Timeout while contacting DNS servers") \
    XX(ARES_EOF, "End of file") \
    XX(ARES_EFILE, "Error reading file") \
    XX(ARES_ENOMEM, "Out of memory") \
    XX(ARES_EDESTRUCTION, "Channel is being destroyed") \
    XX(ARES_EBADSTR,"Misformatted string") \
    XX(ARES_EBADFLAGS, "Illegal flags specified") \
    XX(ARES_ENONAME, "Given hostname is not numeric") \
    XX(ARES_EBADHINTS, "Illegal hints flags specified") \
    XX(ARES_ENOTINITIALIZED, "c-ares library initialization not yet performed") \
    XX(ARES_ELOADIPHLPAPI, "Error loading iphlpapi.dll") \
    XX(ARES_EADDRGETNETWORKPARAMS, "Could not find GetNetworkParams function") \
    XX(ARES_ECANCELLED, "DNS query cancelled") \
    XX(ARES_ESERVICE,  "Invalid service name or number") \
    XX(ARES_ENOSERVER, "No DNS servers were configured")

PyObject* cyares_err_name(int status){
    PyObject* name;
    switch ((ares_status_t)status){
        #define __cyares_ERROR_NAME(ERR, MSG) \
            case ERR: return PyBytes_FromStringAndSize(#ERR, sizeof(#ERR) - 1);

        CYARES_ERROR_CODES(__cyares_ERROR_NAME)
        #undef __cyares_ERROR_NAME
        default: {
            return PyBytes_FromStringAndSize("Unknown", 8);
        }
    }
}

// Optimized version of ares_strerror
PyObject* cyares_strerror(int code){
    switch ((ares_status_t)code){
        #define __cyares_ERROR_DESC(ERR, MSG) \
            case ERR: return PyBytes_FromStringAndSize(MSG, sizeof(MSG) - 1);
        CYARES_ERROR_CODES(__cyares_ERROR_DESC)
        #undef __cyares_ERROR_DESC
        default: {
            return PyBytes_FromStringAndSize("Unknown", 8);
        }
        
    }
}

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif // __cyares_ERR_LOOKUP_H__