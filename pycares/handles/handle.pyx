

cdef class Handle:
    cdef void _init(self, Channel channel, uint64_t h_id, object cb):
        self.channel = channel
        self.h_id = h_id
        self.cb = cb
        self.alive = True
        
    cdef void _throw_exception(self, object exc):
        return
    
    cdef void _cancel(self):
        self.alive = False
    
    
 
