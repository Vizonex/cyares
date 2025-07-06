# We can use Cython's Tempita module but we can fallback 
# if we didn't install cython globally or in a virtual-env

# Fallbacks go in this order
# 1. Cython's Tempita (Fastest)
#    - Cython uses a pure-python cython wrapper to speedup things 
#    - may also be pre-compiled
#
# 2. Direct Tempita Library 
# - can be installed via pip or uv 
# - Likely More Maintained
#
# 3. Fallback_Tempita
#    - Local Copy if all else has failed us
#    - Likely Slowest Option or Least Maintained
#    - a urllib script is planned to download and update this fallback if needed

try:
    from Cython.Tempita import Template, TemplateError # type: ignore
except (ModuleNotFoundError, ImportError):
    # Do we at least have the Tempita library?
    try:
        from tempita import Template, TemplateError # type: ignore
    except (ModuleNotFoundError, ImportError):
        # Workaround, made a local copy of tempita 
        # DATE: 7-6-2025 , I'll make a script that 
        # updates this in the future... - Vizonex
        from fallback_tempita import Template, TemplateError # type: ignore

__all__ = ("Template", "TemplateError",)
