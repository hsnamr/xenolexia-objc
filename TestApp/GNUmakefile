# GNUmakefile for Xenolexia Test App

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = XenolexiaTestApp

XenolexiaTestApp_OBJC_FILES = main.m \
	../../SmallStep/SmallStep/Core/SSPlatform.m \
	../../SmallStep/SmallStep/Core/SSFileSystem.m \
	../../SmallStep/SmallStep/Platform/Linux/SSLinuxPlatform.m

XenolexiaTestApp_INCLUDE_DIRS = -I../../SmallStep/SmallStep/Core -I../../SmallStep/SmallStep/Platform/Linux

include $(GNUSTEP_MAKEFILES)/tool.make
