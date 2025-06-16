# _cyares
A roughdraft for moving pycares to cython. hence the underscore

## Why Rewrite pycares?
- While pycares runs aiodns which optionally runs aiohttp there's some pretty alarming and unsafe code that hangs while during shutdown 
- the library has had [recent vulnerablilities](https://github.com/saghul/pycares/security/advisories/GHSA-5qpg-rh4j-qp35). 
- cython is faster than cffi and can be straight up compiled statically rather than being ran dynamically
- rewriting the code in cython means you could use pycares in cython as well which only means more benefits in speed.
- rewriting the way the handles work in uvloop fashion might be safer as well as making
  the channels shut them down instead of having another thread do it.
- pycares's shutdown mechanisms are not threadsafe and users using tools such as [aiothreading](https://github.com/Vizonex/aiothreading) may experience unwanted performance degredations.

