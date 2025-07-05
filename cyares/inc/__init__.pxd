cdef extern from "cares_flag_check.h":
    int cyares_check_qtypes(int qtype) except -1
    int cyares_check_qclasses(int qclass) except -1


cdef extern from "cyares_utils.h":
    char* cyares_unicode_str_and_size(str obj, Py_ssize_t* size) except NULL
    int cyares_get_buffer(object obj, Py_buffer *view) except -1
    void cyares_release_buffer(Py_buffer *view)
    int cyares_copy_memory(char** ptr_to, object ptr_from) except -1
