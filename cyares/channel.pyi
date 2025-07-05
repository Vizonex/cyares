
import types
from typing import Callable, Any, overload
from concurrent.futures import Future
from resulttypes import *
from typing_extensions import Self 
import socket 

__pyx_capi__: dict
__test__: dict

class Channel:
    def __init__(
        self,
        flags = None,
        timeout = None,
        tries = None,
        ndots = None,
        tcp_port = None,
        udp_port = None,
        servers:list[str] | None = None,
        domains = None,
        lookups = None,
        sock_state_cb = None,
        socket_send_buffer_size = None,
        socket_receive_buffer_size = None,
        rotate:bool = False,
        local_ip = None,
        local_dev = None,
        resolvconf_path = None,
        event_thread:bool = False
    ) -> None: ...
    
    @overload
    def query(
        self, 
        name:str | bytearray | bytes | memoryview[int], 
        query_type:str = "A",
        query_class: str | None = None
        )-> Future[list[ares_query_a_result]]:...

    @overload
    def query(
        self, 
        name:str | bytearray | bytes | memoryview[int], 
        query_type:str = "MX",
        query_class: str | None = None
        )-> Future[list[ares_query_mx_result]]:...



    def query(
        self, 
        name: str | bytearray | bytes | memoryview[int], 
        query_type: str | int, 
        callback:  Callable[[Any, int], None] = None , 
        query_class: str | None = None
    ) -> Future: ...

    def gethostbyname(
        self, 
        name:str | bytearray | bytes | memoryview[int], 
        family: socket.AddressFamily, 
        callback:Callable[[Future[ares_host_result]], None] | None = None
    ) -> Future[ares_host_result]:
        """Simillar to pycare's version but name
        can be any string or c array and the callback is a future object
        """

    

    def reinit(self) -> None: ...
    @property
    def servers() -> list[str]:
        pass
    @servers.setter
    def servers(servers:list[str | bytes | memoryview[int] | bytearray]):
        pass

    def __enter__(self) -> Self: ...
    def __exit__(self, type: type[BaseException] | None, value: BaseException | None, traceback: types.TracebackType | None): ...
    def __reduce__(self): ...
