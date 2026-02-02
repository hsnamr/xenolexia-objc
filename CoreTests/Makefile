# Standalone Makefile for CoreTests (no GNUStep required)
# Links xenolexia-shared-c (SM-2). Run from repo root: make -C xenolexia-objc/CoreTests

CC = gcc
SHARED_C_DIR = ../../xenolexia-shared-c
CFLAGS = -I$(SHARED_C_DIR) -Wall -O2
LDFLAGS = -L$(SHARED_C_DIR) -lxenolexia_sm2

.PHONY: all clean run build_shared

all: build_shared XenolexiaCoreTests

build_shared:
	$(MAKE) -C $(SHARED_C_DIR) static

XenolexiaCoreTests: main.c $(SHARED_C_DIR)/libxenolexia_sm2.a
	$(CC) $(CFLAGS) -o XenolexiaCoreTests main.c $(LDFLAGS)

run: XenolexiaCoreTests
	./XenolexiaCoreTests

clean:
	rm -f XenolexiaCoreTests *.o
