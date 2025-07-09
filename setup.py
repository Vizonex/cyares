# NOTE: many parts were borrowed from pycares so that we wouldn't need to reinvent the wheel.

import os
import sys
import select

from setuptools.command.build_ext import build_ext
from setuptools import setup, Extension

use_system_lib = bool(int(os.environ.get("CYARES_USE_SYSTEM_LIB", 0)))

cares_sources = [
    "deps/c-ares/src/lib/ares_addrinfo_localhost.c",
    "deps/c-ares/src/lib/ares_addrinfo2hostent.c",
    "deps/c-ares/src/lib/ares_android.c",
    "deps/c-ares/src/lib/ares_cancel.c",
    "deps/c-ares/src/lib/ares_close_sockets.c",
    "deps/c-ares/src/lib/ares_conn.c",
    "deps/c-ares/src/lib/ares_cookie.c",
    "deps/c-ares/src/lib/ares_data.c",
    "deps/c-ares/src/lib/ares_destroy.c",
    "deps/c-ares/src/lib/ares_free_hostent.c",
    "deps/c-ares/src/lib/ares_free_string.c",
    "deps/c-ares/src/lib/ares_freeaddrinfo.c",
    "deps/c-ares/src/lib/ares_getaddrinfo.c",
    "deps/c-ares/src/lib/ares_getenv.c",
    "deps/c-ares/src/lib/ares_gethostbyaddr.c",
    "deps/c-ares/src/lib/ares_gethostbyname.c",
    "deps/c-ares/src/lib/ares_getnameinfo.c",
    "deps/c-ares/src/lib/ares_hosts_file.c",
    "deps/c-ares/src/lib/ares_init.c",
    "deps/c-ares/src/lib/ares_library_init.c",
    "deps/c-ares/src/lib/ares_metrics.c",
    "deps/c-ares/src/lib/ares_options.c",
    "deps/c-ares/src/lib/ares_parse_into_addrinfo.c",
    "deps/c-ares/src/lib/ares_process.c",
    "deps/c-ares/src/lib/ares_qcache.c",
    "deps/c-ares/src/lib/ares_query.c",
    "deps/c-ares/src/lib/ares_search.c",
    "deps/c-ares/src/lib/ares_send.c",
    "deps/c-ares/src/lib/ares_set_socket_functions.c",
    "deps/c-ares/src/lib/ares_socket.c",
    "deps/c-ares/src/lib/ares_sortaddrinfo.c",
    "deps/c-ares/src/lib/ares_strerror.c",
    "deps/c-ares/src/lib/ares_sysconfig_files.c",
    "deps/c-ares/src/lib/ares_sysconfig.c",
    "deps/c-ares/src/lib/ares_timeout.c",
    "deps/c-ares/src/lib/ares_update_servers.c",
    "deps/c-ares/src/lib/ares_version.c",
    "deps/c-ares/src/lib/dsa/ares_array.c",
    "deps/c-ares/src/lib/dsa/ares_htable_asvp.c",
    "deps/c-ares/src/lib/dsa/ares_htable_dict.c",
    "deps/c-ares/src/lib/dsa/ares_htable_strvp.c",
    "deps/c-ares/src/lib/dsa/ares_htable_szvp.c",
    "deps/c-ares/src/lib/dsa/ares_htable_vpstr.c",
    "deps/c-ares/src/lib/dsa/ares_htable_vpvp.c",
    "deps/c-ares/src/lib/dsa/ares_htable.c",
    "deps/c-ares/src/lib/dsa/ares_llist.c",
    "deps/c-ares/src/lib/dsa/ares_slist.c",
    "deps/c-ares/src/lib/event/ares_event_configchg.c",
    "deps/c-ares/src/lib/event/ares_event_thread.c",
    "deps/c-ares/src/lib/event/ares_event_wake_pipe.c",
    "deps/c-ares/src/lib/inet_net_pton.c",
    "deps/c-ares/src/lib/inet_ntop.c",
    "deps/c-ares/src/lib/legacy/ares_create_query.c",
    "deps/c-ares/src/lib/legacy/ares_expand_name.c",
    "deps/c-ares/src/lib/legacy/ares_expand_string.c",
    "deps/c-ares/src/lib/legacy/ares_fds.c",
    "deps/c-ares/src/lib/legacy/ares_getsock.c",
    "deps/c-ares/src/lib/legacy/ares_parse_a_reply.c",
    "deps/c-ares/src/lib/legacy/ares_parse_aaaa_reply.c",
    "deps/c-ares/src/lib/legacy/ares_parse_caa_reply.c",
    "deps/c-ares/src/lib/legacy/ares_parse_mx_reply.c",
    "deps/c-ares/src/lib/legacy/ares_parse_naptr_reply.c",
    "deps/c-ares/src/lib/legacy/ares_parse_ns_reply.c",
    "deps/c-ares/src/lib/legacy/ares_parse_ptr_reply.c",
    "deps/c-ares/src/lib/legacy/ares_parse_soa_reply.c",
    "deps/c-ares/src/lib/legacy/ares_parse_srv_reply.c",
    "deps/c-ares/src/lib/legacy/ares_parse_txt_reply.c",
    "deps/c-ares/src/lib/legacy/ares_parse_uri_reply.c",
    "deps/c-ares/src/lib/record/ares_dns_mapping.c",
    "deps/c-ares/src/lib/record/ares_dns_multistring.c",
    "deps/c-ares/src/lib/record/ares_dns_name.c",
    "deps/c-ares/src/lib/record/ares_dns_parse.c",
    "deps/c-ares/src/lib/record/ares_dns_record.c",
    "deps/c-ares/src/lib/record/ares_dns_write.c",
    "deps/c-ares/src/lib/str/ares_buf.c",
    "deps/c-ares/src/lib/str/ares_str.c",
    "deps/c-ares/src/lib/str/ares_strsplit.c",
    "deps/c-ares/src/lib/util/ares_iface_ips.c",
    "deps/c-ares/src/lib/util/ares_math.c",
    "deps/c-ares/src/lib/util/ares_rand.c",
    "deps/c-ares/src/lib/util/ares_threads.c",
    "deps/c-ares/src/lib/util/ares_timeval.c",
    "deps/c-ares/src/lib/util/ares_uri.c",
]

if sys.platform == "win32":
    cares_sources += [
        "deps/c-ares/src/lib/ares_sysconfig_win.c",
        "deps/c-ares/src/lib/windows_port.c",
        "deps/c-ares/src/lib/event/ares_event_win32.c",
    ]

if sys.platform == "darwin":
    cares_sources += ["deps/c-ares/src/lib/ares_sysconfig_mac.c"]


class cares_build_ext(build_ext):
    cares_dir = os.path.join("deps", "c-ares")
    build_config_dir = os.path.join("deps", "build-config")
    ext_headers = os.path.join("cyares")

    # Brought over from winloop since these can be very useful.
    user_options = build_ext.user_options + [
        ("cython-always", None, "run cythonize() even if .c files are present"),
        (
            "cython-annotate",
            None,
            "Produce a colorized HTML version of the Cython source.",
        ),
        ("cython-directives=", None, "Cythion compiler directives"),
    ]
    def initialize_options(self):
        super().initialize_options()
        self.cython_always = False
        self.cython_annotate = True
        self.cython_directives = None

    def add_include_dir(self, dir, force=False):
        if use_system_lib and not force:
            return
        dirs = self.compiler.include_dirs
        dirs.insert(0, dir)
        self.compiler.set_include_dirs(dirs)

    def build_extensions(self):
        self.add_include_dir(self.ext_headers)
        # make sure we get the inc folder
        self.add_include_dir(os.path.join(self.ext_headers, "inc"))
        self.add_include_dir(os.path.join(self.cares_dir, "include"))
        self.add_include_dir(os.path.join(self.cares_dir, "src", "lib"))
        self.add_include_dir(os.path.join(self.cares_dir, "src", "lib", "include"))
        self.add_include_dir(os.path.join(self.build_config_dir, "include"), True)
        if sys.platform != "win32":
            self.compiler.define_macro("HAVE_CONFIG_H", 1)
            self.compiler.define_macro("_LARGEFILE_SOURCE", 1)
            self.compiler.define_macro("_FILE_OFFSET_BITS", 64)
        if sys.platform.startswith("linux"):
            # Check if it's actually Android
            if os.environ.get("ANDROID_ROOT") and os.environ.get("ANDROID_DATA"):
                self.add_include_dir(
                    os.path.join(self.build_config_dir, "config_android")
                )
            else:
                self.add_include_dir(
                    os.path.join(self.build_config_dir, "config_linux")
                )
            self.compiler.add_library("dl")
            self.compiler.add_library("rt")
        elif sys.platform == "darwin":
            self.add_include_dir(os.path.join(self.build_config_dir, "config_darwin"))
            self.compiler.define_macro("_DARWIN_USE_64_BIT_INODE", 1)
        elif sys.platform.startswith("freebsd"):
            self.add_include_dir(os.path.join(self.build_config_dir, "config_freebsd"))
            self.compiler.add_library("kvm")
        elif sys.platform.startswith("dragonfly"):
            self.add_include_dir(os.path.join(self.build_config_dir, "config_freebsd"))
        elif sys.platform.startswith("netbsd"):
            self.add_include_dir(os.path.join(self.build_config_dir, "config_netbsd"))
        elif sys.platform.startswith("openbsd"):
            self.add_include_dir(os.path.join(self.build_config_dir, "config_openbsd"))
        elif sys.platform.startswith("sunos"):
            self.add_include_dir(os.path.join(self.build_config_dir, "config_sunos"))
            self.compiler.add_library("socket")
            self.compiler.add_library("nsl")
            self.compiler.add_library("kstat")
        elif sys.platform == "cygwin":
            self.add_include_dir(os.path.join(self.build_config_dir, "config_cygwin"))
        elif sys.platform == "win32":
            if "mingw" not in self.compiler.compiler_type:
                self.extensions[0].extra_link_args = ["/NODEFAULTLIB:libcmt"]
            self.compiler.add_library("advapi32")
            self.compiler.add_library("iphlpapi")
            self.compiler.add_library("psapi")
            self.compiler.add_library("ws2_32")
            self.compiler.define_macro("CARES_HAVE_WINSOCK2_H", 1)
            self.compiler.define_macro("CARES_HAVE_WS2TCPIP_H", 1)
            self.compiler.define_macro("CARES_HAVE_WINDOWS_H", 1)

        if use_system_lib:
            self.compiler.add_library("cares")
        else:
            sources = cares_sources.copy()
            self.compiler.define_macro("CARES_THREADS", 1)
            self.compiler.define_macro("CARES_STATICLIB", 1)
            if hasattr(select, "poll"):
                sources += ["deps/c-ares/src/lib/event/ares_event_poll.c"]
                self.compiler.define_macro("HAVE_POLL", 1)
                self.compiler.define_macro("HAVE_POLL_H", 1)
            if hasattr(select, "kqueue"):
                sources += ["deps/c-ares/src/lib/event/ares_event_kqueue.c"]
                self.compiler.define_macro("HAVE_KQUEUE", 1)
                self.compiler.define_macro("HAVE_SYS_TYPES_H", 1)
                self.compiler.define_macro("HAVE_SYS_EVENT_H", 1)
                self.compiler.define_macro("HAVE_SYS_TIME_H", 1)
                self.compiler.define_macro("HAVE_FCNTL_H", 1)
            if hasattr(select, "epoll"):
                sources += ["deps/c-ares/src/lib/event/ares_event_epoll.c"]
                self.compiler.define_macro("HAVE_EPOLL", 1)
                self.compiler.define_macro("HAVE_SYS_EPOLL_H", 1)
                self.compiler.define_macro("HAVE_FCNTL_H", 1)
            if hasattr(os, "pipe") and sys.platform != "win32":
                sources += ["deps/c-ares/src/lib/event/ares_event_select.c"]
                self.compiler.define_macro("HAVE_PIPE", 1)

            # Currently all extensions need these sources...
            # In the future we may decide to compile the c-ares library 
            # first then add it in after due to how long it can take to 
            # compile everything
            for e in self.extensions:
                e.sources += sources

        super().build_extensions()

    # Copied from winloop
    def finalize_options(self):
        need_cythonize = self.cython_always
        cfiles = {}

        for extension in self.distribution.ext_modules:
            for i, sfile in enumerate(extension.sources):
                if sfile.endswith(".pyx"):
                    prefix, ext = os.path.splitext(sfile)
                    cfile = prefix + ".c"

                    if os.path.exists(cfile) and not self.cython_always:
                        extension.sources[i] = cfile
                    else:
                        if os.path.exists(cfile):
                            cfiles[cfile] = os.path.getmtime(cfile)
                        else:
                            cfiles[cfile] = 0
                        need_cythonize = True

        if need_cythonize:
            # import pkg_resources

            # Double check Cython presence in case setup_requires
            # didn't go into effect (most likely because someone
            # imported Cython before setup_requires injected the
            # correct egg into sys.path.
            try:
                import Cython
            except ImportError:
                raise RuntimeError(
                    "please install cython to compile cyares from source"
                )

            from Cython.Build import cythonize

            directives = {}
            if self.cython_directives:
                for directive in self.cython_directives.split(","):
                    k, _, v = directive.partition("=")
                    if v.lower() == "false":
                        v = False
                    if v.lower() == "true":
                        v = True
                    directives[k] = v
                self.cython_directives = directives

            self.distribution.ext_modules[:] = cythonize(
                self.distribution.ext_modules,
                compiler_directives=directives,
                annotate=self.cython_annotate,
                emit_linenums=self.debug,
            )

        return super().finalize_options()


if __name__ == "__main__":

    setup(
        ext_modules=[
            Extension(
                "cyares.callbacks",
                ["cyares/callbacks.pyx"]
            ),
            Extension(
                "cyares.channel",
                ["cyares/channel.pyx"],
            ),
            Extension(
                "cyares.exception",
                ["cyares/exception.pyx"]
            ),
            Extension(
                "cyares.resulttypes",
                ["cyares/resulttypes.pyx"]
            ),
            Extension(
                "cyares.socket_handle",
                ["cyares/socket_handle.pyx"],
            )
        ],
        cmdclass={"build_ext": cares_build_ext},
    )
