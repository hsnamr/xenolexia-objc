# GNUmakefile for Xenolexia Core Tests (links xenolexia-shared-c)
# Run: make -f CoreTests/GNUmakefile (from xenolexia-objc) or cd CoreTests && make

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = XenolexiaCoreTests

XenolexiaCoreTests_OBJC_FILES = main.m

# Path to xenolexia-shared-c (from repo root: Xenolexia/xenolexia-shared-c)
SHARED_C_DIR = $(shell cd ../.. 2>/dev/null && pwd)/xenolexia-shared-c
# If building from xenolexia-objc dir, shared-c is ../xenolexia-shared-c
ifeq ($(wildcard $(SHARED_C_DIR)/sm2.h),)
  SHARED_C_DIR = ../xenolexia-shared-c
endif

XenolexiaCoreTests_INCLUDE_DIRS = -I$(SHARED_C_DIR)
XenolexiaCoreTests_LDFLAGS = -L$(SHARED_C_DIR) -lxenolexia_sm2
ADDITIONAL_OBJCFLAGS = -I$(SHARED_C_DIR)

# Ensure shared lib is built
all: build_shared_c
	$(MAKE) -f GNUmakefile tool

build_shared_c:
	@if [ -f "$(SHARED_C_DIR)/Makefile" ]; then $(MAKE) -C $(SHARED_C_DIR) static; fi

include $(GNUSTEP_MAKEFILES)/tool.make
