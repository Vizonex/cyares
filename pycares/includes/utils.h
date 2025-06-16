/* 
USing this implementation did not feel wrong at all.abort

This source code utilizes some of msgspec's implementations for dealing with
buffer extraction of unicode characters into a python buffer...

- Some functions and macros were re-named for the sake of being convienient.


- pycares_copy_memory is not apart of msgspec but is written by us...

*/

/* 
Copyright (c) 2021, Jim Crist-Harif
All rights reserved.

Redistribution and use in source and binary forpycares, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
  may be used to endorse or promote products derived from this software
  without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


*/

#ifndef __UTILS_H__
#define __UTILS_H__

#include <string.h>

#include <Python.h>

#ifdef __cplusplus 
extern "C" {
#endif


#ifdef __GNUC__
#define PYCARES_LIKELY(pred) __builtin_expect(!!(pred), 1)
#define PYCARES_UNLIKELY(pred) __builtin_expect(!!(pred), 0)
#else
#define PYCARES_LIKELY(pred) (pred)
#define PYCARES_UNLIKELY(pred) (pred)
#endif

#ifdef __GNUC__
#define PYCARES_INLINE __attribute__((always_inline)) inline
#define PYCARES_NOINLINE __attribute__((noinline))
#elif defined(_pycaresC_VER)
#define PYCARES_INLINE __forceinline
#define PYCARES_NOINLINE __declspec(noinline)
#else
#define PYCARES_INLINE inline
#define PYCARES_NOINLINE
#endif

/* msgspec Note: XXX: Optimized `PyUnicode_AsUTF8AndSize` for strs that we know have
 * a cached unicode representation. */
static inline const char *
pycares_unicode_str_and_size_nocheck(PyObject *str, Py_ssize_t *size) {
    if (PYCARES_LIKELY(PyUnicode_IS_COMPACT_ASCII(str))) {
        *size = ((PyASCIIObject *)str)->length;
        return (char *)(((PyASCIIObject *)str) + 1);
    }
    *size = ((PyCompactUnicodeObject *)str)->utf8_length;
    return ((PyCompactUnicodeObject *)str)->utf8;
}

/* Msgspec NOTE: XXX: Optimized `PyUnicode_AsUTF8AndSize` */
static inline const char *
pycares_unicode_str_and_size(PyObject *str, Py_ssize_t *size) {
    const char *out = pycares_unicode_str_and_size_nocheck(str, size);
    if (PYCARES_LIKELY(out != NULL)) return out;
    return PyUnicode_AsUTF8AndSize(str, size);
}



/* Fill in view.buf & view.len from either a Unicode or buffer-compatible
 * object. */
static int
pycares_get_buffer(PyObject *obj, Py_buffer *view) {
    if (PYCARES_UNLIKELY(PyUnicode_CheckExact(obj))) {
        view->buf = (void *)pycares_unicode_str_and_size(obj, &(view->len));
        if (view->buf == NULL) return -1;
        Py_INCREF(obj);
        view->obj = obj;
        return 0;
    }
    return PyObject_GetBuffer(obj, view, PyBUF_CONTIG_RO);
}

static void
pycares_release_buffer(Py_buffer *view) {
    if (PYCARES_LIKELY(!PyUnicode_CheckExact(view->obj))) {
        PyBuffer_Release(view);
    }
    else {
        Py_CLEAR(view->obj);
    }
}


static int pycares_copy_memory(char** ptr_to, PyObject* ptr_from){
    Py_buffer view;
    if (pycares_get_buffer(ptr_from, &view) < 0) {
        return -1;
    }


    char* s = (char*)PyMem_Malloc(sizeof(char) * view.len);
    if (s == NULL){
        PyErr_NoMemory();
        return -1;
    }
    
    memcpy(s, ptr_from, sizeof(char) * view.len);
    *ptr_to = s;

    pycares_release_buffer(&view);
    return 0;
}



#ifdef __cplusplus 
}
#endif


#endif // __UTILS_H__