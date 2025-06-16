from ..ares cimport *
from libc.stdint cimport uint64_t


cdef class Channel:
    cdef:
        ares_channel_t channel
        uint64_t handle_id
        dict handles

    