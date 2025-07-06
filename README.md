![cy-ares logo](Cy-Ares-Logo.png)

An Upgraded version of __pycares__ with faster and safer features.



# Small Examples of How to Use

```python
from cyares import Channel

# NOTE: Dns Queries contain a Future object
# This is a little bit different from pycares 
# Handles were used to prevent new or unwanted vulnerabilities along
# with easier control given to the user...
# The Future object comes from the python concurrent.futures standard library

def main():
    with Channel(servers=["8.8.8.8", "8.8.4.4"], event_thread=True) as channel:
        data = channel.query("google.com", "A").result()
    print(data)

if __name__ == "__main__":
    main()
```

## In Asyncio
There's a module for an aiodns version if aiodns were using cyares.

```python
import winloop # or uvloop (asyncio will also work) 
# I'll add trio support in a future update as well...
from cyares.aio import DNSResolver

async def test():
    async with DNSResolver(["8.8.8.8", "8.8.4.4"]) as dns:
        data = await dns.query("google.com", "A")
    print(data)

if __name__ == "__main__":
    winloop.run(test())
```



## Story
As Someone who as recently started to contribute to projects such as __aiohttp__ and a few of it's smaller libraries. The asynchronous dns resolver __aiodns__ that __aiohttp__ can optionally use, felt like the oddest one in the group. With __aiodns__ using __pycares__ under the hood I wanted to learn how it worked to see if I could use my skills to optimize it like I had previously done with __propcache__ and __multidict__ as well but I soon came to learn of it's many problems and when __pycares__ started to hang on me with lingering threads when it ran, something didn't feel right to me and it lead me down a very large rabbit-hole waiting to be re-explored.

__Pycares__ was quick, dirty and fast but as the years of it's existance went by something wasn't exactly right with it and it could use safer features, better optimization and safety practices. While __cffi__ might be both quick and easy to use I didn't see the benefit of using it. The many vulnerabilities it was getting told me something needed to change if not big. With __Pycares__ reaching version __5.0.0__ I wanted to celebrate it the same way node-js celebrated the 10 year annversery of the original __http-parser__. Write a new one.


### The Rewrite 

While contributing to the aio-libs repos whenever I had a gap of free-time on hand while waiting on a question to be answered and when my other python libraries felt stable enough such as (deprecated-params, aiocallback, aiothreading & winloop) this is where I spent my time on. It had a total of 3 re-writes until I was satisfied with the result. Turns out just doing everything in small chunks makes all the difference. 

It only felt right to me that migrating the library from __cffi__ to __cython__ would be the best solution to the problem. Not __Rust__ or __C__, just __pure-cython__ and small amounts of __C__ whenever nessesary and re-changing many of the internals to incorperate a safer approch. The reason for not picking __Rust__ is that there wasn't nessesarly a need to be memory-safe. What I cared about was speed, when people are doing DNS Lookups, speed matters and __Rust__ did not have a friendly enough archetecture that would set a future or allow me to access the parent from the child. 

There was no better canadate than to move to using handles the same way __uvloop__ & __winloop__ do it and having authored one of them I was familliar with this concept.

The idea was not to reinvent the wheel rather move parts of the library over in chunks and look at __pycares__ for clues on how certain things should be laid out. At the end of the day, __Pycares__ was the blueprint and using __concurrent.futures__ & __Cython__ was the cure. __Py_buffer__ techniques brought over from __msgspec__ were utilized incase users were planning to use any bytes or string objects of any sort and I made sure the license was on it incase users wanted to know where it came from.

If there was a deprecated function with an alternative & safer approch to use I felt using it would be a better move. For example, servers are now set with the csv functions rather than the original setup and because of that change you could now set dns servers in url formats and I might possibly look at adding in __yarl__ to be the cherry on top for those who might wish to get real creative about dns server urls. 

Moving over the __ares_query__ function to use the dns recursion function is planned for the future (maybe after I do the first release of cyares). I still wanted to retain the original response data it gives so that migrating from __pycares__ to __cyares__ wouldn't be a pain to anyone who planned on moving and I also didn't want to take away from __pycares__ either if you prefer using __cffi__ over __cython__ the same way __curl-cffi__ and __cycurl__ were both done. I have my fingers crossed that __aiodns__ will adopt this library in the future or allow users to choose between __pycares__ and __cyares__.

