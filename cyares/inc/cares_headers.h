#ifndef __CARES_HEADERS_H__
#define __CARES_HEADERS_H__

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#ifdef _WIN32
#define CYARES_USE_WINDOWS 1
#define WIN32_LEAN_AND_MEAN
# include <WinSock2.h>

// Incase we didn't have it previously...
typedef uint16_t in_port_t;


#ifdef __clang__
    // pxdgen is in use don't let this type end up being a scavenger hunt... 
    typedef int socklen_t;
#endif

#else
#define CYARES_USE_WINDOWS 0
# include <sys/types.h>
# include <sys/socket.h>
# include <netdb.h> /* struct hostent */
# include <netinet/in.h> /* struct sockaddr_in/sockaddr_in6 */
#endif

// We would like to compile to one static file please....
// NOTE: It's already defined...
// #define CARES_STATICLIB

#include "ares_nameser.h"
#include "ares_build.h"

#include "ares.h"



#ifdef __cplusplus
};
#endif /* __cplusplus */


#endif // __CARES_HEADERS_H__