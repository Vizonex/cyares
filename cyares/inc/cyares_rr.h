#ifndef __CYARES_RR_H__
#define __CYARES_RR_H__

/* Cyares recursive results, This is meant to help optimize out a 
few of the most repetative and quite annoying sections of this library. 
*/

#include "cares_headers.h"
#include "Python.h"
#include "string.h"
#include "stdint.h"

#define _CYARES_DEFAULT_BUF_SIZE 512 /* 0.5 kb by default due to some TXT Records being smaller than others */

// Next section is inspired by aiohttp & yarl for handling utf-8 characters
// it is not meant to be publically accessable
typedef struct {
    char* buf;
    Py_ssize_t size, pos;
    uint8_t heap;
} writer_t;

inline void 
cyares_init_writer(writer_t* writer, char* buf, Py_ssize_t size){
    writer->buf = buf;
    writer->size = size;
    writer->pos = 0;
    writer->heap = 0;
}

inline int
cyares_write_byte(writer_t* writer, const uint8_t ch){
    char* buf;
    Py_ssize_t size;

    if (writer->pos == writer->size){
        /* realloc */
        size = writer->size + _CYARES_DEFAULT_BUF_SIZE;
        if (!writer->heap) {
            buf = (char*)PyMem_Malloc((size_t)size);
            if (buf == NULL){
                PyErr_NoMemory();
                return -1;
            }
            memcpy(buf, writer->buf, writer->size);
        } else {
            buf = (char*)PyMem_Realloc(writer->buf, size);
            if (buf == NULL){
                PyErr_NoMemory();
                return -1;
            }
        }
        writer->buf = buf;
        writer->size = size;
        writer->heap = 1;
    }
    writer->buf[writer->pos] = (char)ch;
    writer->pos += 1;
    return 0;
}

inline void cyares_release_writer(writer_t* writer){
    if (writer->heap){
        PyMem_Free(writer->buf);
    }
}

inline int cyares_write_utf8(writer_t* writer, const uint8_t utf){
    if (utf < 0x80) {
        return cyares_write_byte(writer, utf);
    }
    /* it can only go less than 256 from here so no need to 
    rip off all that aiohttp does :) */
    if (cyares_write_byte(writer, (uint8_t)(0xc0 | (utf >> 6))) < 0){
        return -1;
    }
    return cyares_write_byte(writer,  (uint8_t)(0x80 | (utf & 0x3f)));
}

inline PyObject* cyares_writer_finish(writer_t* writer) {
    return PyBytes_FromStringAndSize(writer->buf, writer->pos);
}

/* encodes utf-8 values as bytes without needing to convert multiple times */
inline PyObject* cyares_encode_bytes(const uint8_t* utf, const Py_ssize_t len){
    /* prevents us from needing to calculate each character's actual size */
    char buf[_CYARES_DEFAULT_BUF_SIZE];
    writer_t w;
    PyObject* b;
    cyares_init_writer(&w, buf, _CYARES_DEFAULT_BUF_SIZE);
    
    for (Py_ssize_t i = 0; i < len; i++)
    {
        if (cyares_write_utf8(&w, utf[i]) < 0){
            cyares_release_writer(&w);
            return NULL;
        }
    }
    /* finish and release */
    b = cyares_writer_finish(&w);
    cyares_release_writer(&w);
    return b;
}




/* DNS RR Stuff */

inline PyObject* cyares_dns_rr_get_name(const ares_dns_rr_t* rr){
    return PyUnicode_FromString(ares_dns_rr_get_name(rr));
}

inline PyObject* cyares_dns_rr_get_str(
  const ares_dns_rr_t* rr, ares_dns_rr_key_t key
){
    return PyUnicode_FromString(ares_dns_rr_get_str(rr, key));
}

/* Based off an idea that the author of cyares had in mind 
for pycares to try https://github.com/saghul/pycares/pull/302 
*/

inline PyObject* cyares_rr_get_bin_as_unicode(
    const ares_dns_rr_t* rr, ares_dns_rr_key_t key
){
    size_t bin_len;
    const uint8_t* bin = (const uint8_t*)ares_dns_rr_get_bin(rr, key, &bin_len);
    return PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, bin, (Py_ssize_t)bin_len);
}

inline PyObject* cyares_rr_get_bin_as_bytes(
    const ares_dns_rr_t* rr, ares_dns_rr_key_t key
){
    size_t bin_len;
    const uint8_t* bin = (const uint8_t*)ares_dns_rr_get_bin(rr, key, &bin_len);
    return cyares_encode_bytes(bin, bin_len);
}

/* Mostly for ARES_RR_TXT_DATA but incase anything else comes along it will be added to this... */
inline PyObject* cyares_rr_get_abin(const ares_dns_rr_t* rr, ares_dns_rr_key_t key){
    size_t cnt = ares_dns_rr_get_abin_cnt(rr, key);
    size_t length;
    writer_t w;
    PyObject* abin;
    const uint8_t* data;
    char buf[_CYARES_DEFAULT_BUF_SIZE];
    cyares_init_writer(&w, buf, _CYARES_DEFAULT_BUF_SIZE);
    
    for (size_t i = 0; i < cnt; i++)
    {
        data = ares_dns_rr_get_abin(rr, key, i, &length);
        if (data != NULL){
            for (size_t j = 0; j < length; j++)
            {
                if (cyares_write_utf8(&w, data[i]) < 0){
                    cyares_release_writer(&w);
                    return NULL;
                }
            }
        }
    }
    abin = cyares_writer_finish(&w);
    cyares_writer_finish(&w);
    return abin;
}

PyObject* cyares_rr_get_opt(const ares_dns_rr_t* rr, ares_dns_rr_key_t key){
    size_t opt_cnt;
    PyObject* params;

    opt_cnt = ares_dns_rr_get_opt_cnt(rr, key);

    /* New list with as many NULL values as needed */
    params = PyList_New((Py_ssize_t)(opt_cnt));
    if (params == NULL){
        return NULL;
    }

    for (size_t i = 0; i < opt_cnt; i++)
    {
        const uint8_t* ptr;
        size_t ptr_len;
        PyObject *opt_val, *opt_key, *opt;
        
        opt_key = PyLong_FromLong(ares_dns_rr_get_opt(rr, key, i, &ptr, &ptr_len));
        if (opt_key == NULL){
            Py_XDECREF(params);
            return NULL;
        }
        
        opt_val = PyUnicode_FromKindAndData(
            PyUnicode_1BYTE_KIND, (void*)ptr, ptr_len
        );

        if (opt_val == NULL){
            Py_XDECREF(opt_key);
            Py_XDECREF(params);
            return NULL;
        }

        opt = PyTuple_Pack(2, opt_key, opt_val);
        if (opt == NULL){
            Py_XDECREF(opt_val);
            Py_XDECREF(opt_key);
            Py_XDECREF(params);
            return NULL;
        }
        if (PyList_Append(params, opt) < 0){
            Py_XDECREF(opt);
            Py_XDECREF(opt_val);
            Py_XDECREF(opt_key);
            Py_XDECREF(params);
            return NULL;
        }
    }
    return params;
}

PyObject* cyares_dns_rr_get_addr(const ares_dns_rr_t* rr, ares_dns_rr_key_t key){
    char buf[23]; /* INET_ADDRSTRLEN is being dumb with me so will say it's number for now */
    const in_addr* py_addr = ares_dns_rr_get_addr(rr, key);
    if (py_addr == NULL){
        PyErr_SetString(PyExc_ValueError, "Failed to parse in cyares_dns_rr_get_addr");
        return NULL;
    }
    return PyUnicode_FromString(ares_inet_ntop(AF_INET, py_addr, buf, 23));
}

PyObject* cyares_dns_rr_get_addr6(const ares_dns_rr_t* rr, ares_dns_rr_key_t key){
    char buf[65];
    const ares_in6_addr* py_addr = ares_dns_rr_get_addr6(rr, key);
    if (py_addr == NULL){
        PyErr_SetString(PyExc_ValueError, "Failed to parse in cyares_dns_rr_get_addr6");
        return NULL;
    }
    return PyUnicode_FromString(ares_inet_ntop(AF_INET6, py_addr, buf, 65));
}



#endif // __CYARES_RR_H__