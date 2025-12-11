#ifndef __CARES_FLAG_CHECK_H__
#define __CARES_FLAG_CHECK_H__

#include "ares.h"

#include "Python.h"


#define CYARES_QCLASSES(XX) \
    XX(AES_CLASS_IN) \
    XX(AES_CLASS_CHAOS) \
    XX(AES_CLASS_HS) \
    XX(AES_CLASS_NONE) \
    XX(AES_CLASS_ANY)

// returns -1 if it failed
static int cyares_check_qtypes(int qtype){
    switch (qtype) {
        case ARES_REC_TYPE_A: return 0;
        case ARES_REC_TYPE_NS: return 0;
        case ARES_REC_TYPE_CNAME: return 0;
        case ARES_REC_TYPE_SOA: return 0;
        case ARES_REC_TYPE_PTR: return 0;
        case ARES_REC_TYPE_MX: return 0;
        case ARES_REC_TYPE_TXT: return 0;
        case ARES_REC_TYPE_AAAA: return 0;
        case ARES_REC_TYPE_SRV: return 0;
        case ARES_REC_TYPE_NAPTR: return 0;
        case ARES_REC_TYPE_TLSA: return 0;
        case ARES_REC_TYPE_HTTPS: return 0;
        case ARES_REC_TYPE_CAA: return 0;
        case ARES_REC_TYPE_URI: return 0;
        case ARES_REC_TYPE_ANY: return 0;
        default: {
            goto FAIL;
        }
    };
    FAIL:
        PyErr_SetString(PyExc_ValueError, "invalid query type specified");
        return -1;
}

static int cyares_check_qclasses(int qclass){
    switch (qclass) {
        case ARES_CLASS_IN: return 0;
        case ARES_CLASS_CHAOS: return 0;
        case ARES_CLASS_HESOID: return 0;
        case ARES_CLASS_NONE: return 0;
        case ARES_CLASS_ANY: return 0;
        default: {
            goto FAIL;
        }
    }
    FAIL:
        PyErr_SetString(PyExc_ValueError, "invalid query class specified");
        return -1;
}

#endif // __CARES_FLAG_CHECK_H__