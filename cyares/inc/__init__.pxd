cdef extern from "cares_flag_check.h":
    int pycares_check_qtypes(int qtype) except -1
    int pycares_check_qclasses(int qclass) except -1


cdef extern from "utils.h":
    char* pycares_unicode_str_and_size(str obj, Py_ssize_t* size) except NULL
    int pycares_get_buffer(object obj, Py_buffer *view) except -1
    void pycares_release_buffer(Py_buffer *view)
    
    int pycares_copy_memory(char** ptr_to, object ptr_from) except -1
