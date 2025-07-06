from libc.stdint cimport uint8_t

cdef extern from "cares_flag_check.h":
    int cyares_check_qtypes(int qtype) except -1
    int cyares_check_qclasses(int qclass) except -1


cdef extern from "cyares_utils.h":
    char* cyares_unicode_str_and_size(str obj, Py_ssize_t* size) except NULL
    int cyares_get_buffer(object obj, Py_buffer *view) except -1
    void cyares_release_buffer(Py_buffer *view)
    int cyares_copy_memory(char** ptr_to, object ptr_from) except -1

    # uint8_t is Py_UCS1 which is perfect for the data
    # we need to parse from c-ares and convert to result-data
    str cyares_unicode_from_uchar_and_size(
        const uint8_t* chars, Py_ssize_t size
    )
    
    str cyares_unicode_from_uchar(
        const uint8_t* chars
    )
    