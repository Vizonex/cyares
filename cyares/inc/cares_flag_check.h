#ifndef __CARES_FLAG_CHECK_H__
#define __CARES_FLAG_CHECK_H__

#include "ares.h"
#include "ares_nameser.h"

#include "Python.h"

#define CYARES_QTYPES(XX) \
    XX(T_A) \
    XX(T_AAAA) \
    XX(T_ANY) \
    XX(T_CAA) \
    XX(T_CNAME)\
    XX(T_MX) \
    XX(T_NAPTR) \
    XX(T_NS) \
    XX(T_PTR) \
    XX(T_SOA) \
    XX(T_SRV) \
    XX(T_TXT)

#define CYARES_QCLASSES(XX) \
    XX(C_IN) \
    XX(C_CHAOS) \
    XX(C_HS) \
    XX(C_NONE) \
    XX(C_ANY)

// returns -1 if it failed
static int cyares_check_qtypes(int qtype){
    switch (qtype) {
        #define __CYARES_QTYPE_CASE(TYPE) \
            case TYPE: return 0;
        CYARES_QTYPES(__CYARES_QTYPE_CASE)
        #undef __CYARES_QTYPE_CASE
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
        #define __CYARES_QCLASS_CASE(TYPE) \
            case TYPE: return 0;
        CYARES_QCLASSES(__CYARES_QCLASS_CASE)
        #undef __CYARES_QCLASS_CASE
        default: {
            goto FAIL;
        }
    }
    FAIL:
        PyErr_SetString(PyExc_ValueError, "invalid query class specified");
        return -1;
}




#endif // __CARES_FLAG_CHECK_H__