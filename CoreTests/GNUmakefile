# GNUmakefile for Xenolexia Core Tests (uses native XLSm2; no xenolexia-shared-c)
# Run: make -f CoreTests/GNUmakefile (from xenolexia-objc) or cd CoreTests && make

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = XenolexiaCoreTests

XenolexiaCoreTests_OBJC_FILES = main.m ../Core/Native/XLSm2.m

XenolexiaCoreTests_INCLUDE_DIRS = -I.. -I../Core -I../Core/Native

include $(GNUSTEP_MAKEFILES)/tool.make
