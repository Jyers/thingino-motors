# Simple Makefile for ingenic-motor
# - Builds motor and motor-daemon
# - Links against libjct for JSON parsing/config support
#
# Usage examples:
#   make                          # native build (expects libjct in default paths)
#   make CROSS_COMPILE=mipsel-linux-gnu- SYSROOT=/opt/mipsel-sysroot
#   make JCT_PREFIX=/opt/libjct   # explicit lib/include directories for libjct

CC       ?= cc
CFLAGS   ?= -Wall -Wextra -O2
LDFLAGS  ?=

# Cross-compilation (use CROSS_COMPILE=triplet-), e.g.:
#   make CROSS_COMPILE=mipsel-linux-gnu- SYSROOT=/opt/mipsel-sysroot
CROSS_COMPILE ?=
SYSROOT       ?=
JCT_PREFIX    ?=

ifneq ($(strip $(CROSS_COMPILE)),)
CC     := $(CROSS_COMPILE)gcc
AR     := $(CROSS_COMPILE)ar
RANLIB := $(CROSS_COMPILE)ranlib
STRIP  := $(CROSS_COMPILE)strip
endif

ifneq ($(strip $(SYSROOT)),)
CFLAGS  += --sysroot=$(SYSROOT)
LDFLAGS += --sysroot=$(SYSROOT)
endif

ifneq ($(strip $(JCT_PREFIX)),)
INCLUDE_DIRS += -I$(JCT_PREFIX)/include
LIB_DIRS     += -L$(JCT_PREFIX)/lib
endif

LIBS += -ljct

SRC_DIR  := src
BINARIES := motor motor-daemon
OBJS     := $(SRC_DIR)/motor.o $(SRC_DIR)/motor-daemon.o

.PHONY: all deps clean distclean format

all: deps $(BINARIES)

deps:
	@echo "Using libjct from the current toolchain/sysroot"

motor: $(SRC_DIR)/motor.o | deps
	$(CC) $(CFLAGS) -o $@ $^ $(LIB_DIRS) $(LIBS) $(LDFLAGS)

motor-daemon: $(SRC_DIR)/motor-daemon.o | deps
	$(CC) $(CFLAGS) -o $@ $^ $(LIB_DIRS) $(LIBS) $(LDFLAGS)

$(SRC_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) $(INCLUDE_DIRS) -c -o $@ $<

format:
	@if command -v clang-format >/dev/null 2>&1; then \
		clang-format -i $(SRC_DIR)/motor.c $(SRC_DIR)/motor-daemon.c; \
	else \
		echo "clang-format not found; skipping format"; \
	fi

clean:
	rm -f $(OBJS) $(BINARIES)
	rm -f *.o *.a *.so $(SRC_DIR)/*.o

distclean: clean
	rm -rf third_party

