#  Makefile - Makefile for a Linux module for reading sensor data.
#  Copyright (c) 1998, 1999  Frodo Looijaard <frodol@dds.nl>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

# Everything you may want to change is in the top of this file. Usually, you
# can just use the defaults, fortunately.

# There are two build systems supported. The lm_sensors-like one builds
# everything without needing write-access to the kernel tree. The original
# i2c one adds versioning for module symbols; it needs to write in your
# kernel tree for this (and seems to give minor troubles in some cases).
# Make your choice.
BUILD_SYSTEM=lm_sensors
#BUILD_SYSTEM=i2c

# If your /bin/sh is not bash, change the below definition so that make can
# find bash. Or you can hope your sh-like shell understands all scripts.
# I think so, but I have not tested it.
# SHELL=/usr/bin/bash

# The location of linux itself. This is used to find the kernel headers
# and other things.
LINUX=/usr/src/linux
LINUX_HEADERS=$(LINUX)/include

# Determine whether we need to compile the kernel modules, or only the
# user-space utilities. By default, the kernel modules are compiled.
#COMPILE_KERNEL := 0
COMPILE_KERNEL := 1


# Uncomment the third line on SMP systems if the magic invocation fails. It
# is a bit complicated because SMP configuration changed around kernel 2.1.130
SMP := $(shell if grep -q '^SMP[[:space:]]*=' $(LINUX)/Makefile || \
                  grep -q '^[[:space:]]*\#define[[:space:]]*CONFIG_SMP[[:space:]]*1' $(LINUX_HEADERS)/linux/autoconf.h ; \
               then echo 1; else echo 0; fi)
#SMP := 0
#SMP := 1

# Uncomment the second or third line if the magic invocation fails.
# We need to know whether CONFIG_MODVERSIONS is defined.
MODVER := $(shell if cat $(LINUX_HEADERS)/linux/config.h $(LINUX_HEADERS)/linux/autoconf.h 2>/dev/null | grep -q '^[[:space:]]*\#define[[:space:]]*CONFIG_MODVERSIONS[[:space:]]*1'; then echo 1; else echo 0; fi)
#MODVER := 0
#MODVER := 1

# This is the directory into which the modules will be installed.
# The magic invocation will return something like this:
#   /lib/modules/2.2.15-ac9/extra/misc
MODDIR := /lib/modules/`sed -ne '1,4 { s/.*= *\(.*\)/\1/; 1,2 s/.*/&./; p; };' <$(LINUX)/Makefile | tr -d '\n'`
ifeq ($(BUILD_SYSTEM),i2c)
MODDIR := $(MODDIR)/extra/misc
else
MODDIR := $(MODDIR)/misc
endif


# This is the directory into which the header files will be installed.
# If you want to make sure your current kernel tree is not overwritten,
# the default should work. This is ignored for the i2c build system.
LINUX_INCLUDE_DIR := /usr/local/include/linux
#LINUX_INCLUDE_DIR := $(LINUX_HEADERS)

# Uncomment the second line if you are a developer. This will enable many
# additional warnings at compile-time
WARN := 0
#WARN := 1

##################################################
# Below this, nothing should need to be changed. #
##################################################

.PHONY: all clean install patch

ifeq ($(BUILD_SYSTEM),i2c)

all:
ifeq ($(COMPILE_KERNEL),1)
	$(MAKE) -C kernel KERNEL_LOCATION=$(LINUX) MODULE_DIR=$(MODDIR) here
endif

install:
ifeq ($(COMPILE_KERNEL),1)
	$(MAKE) -C kernel KERNEL_LOCATION=$(LINUX) MODULE_DIR=$(MODDIR) \
                I2CKERNELDIR=(LINUX_HEADERS) I2CMODDIR=$(MODDIR) install
endif

clean:
ifeq ($(COMPILE_KERNEL),1)
	$(MAKE) -C kernel KERNEL_LOCATION=$(LINUX) MODULE_DIR=$(MODDIR) clean
endif

else

# Note that this is a monolithic Makefile; it calls no sub-Makefiles,
# but instead, it compiles everything right from here. Yes, there are
# some distinct advantages to this; see the following paper for more info:
#   http://www.tip.net.au/~millerp/rmch/recu-make-cons-harm.html
# Note that is still uses Makefile fragments in sub-directories; these
# are called 'Module.mk'.

# Within each Module.mk, rules and dependencies can be added to targets
# all, install and clean. Use double colons instead of single ones
# to do this.

# The subdirectories we need to build things in
SRCDIRS := mkpatch
ifeq ($(COMPILE_KERNEL),1)
SRCDIRS += kernel
endif

# Some often-used commands with default options
MKDIR := mkdir -p
RM := rm -f
CC := gcc
BISON := bison
FLEX := flex
AR := ar
INSTALL := install
LN := ln -sfn
GREP := grep

# Determine the default compiler flags
# MODCFLAGS is to create in-kernel object files (modules)

CFLAGS := -I$(LINUX_HEADERS) -O2 -DLM_SENSORS

ifeq ($(WARN),1)
CFLAGS += -Wall -Wstrict-prototypes -Wshadow -Wpointer-arith -Wcast-qual \
          -Wcast-align -Wwrite-strings -Wnested-externs -Winline
endif


# The -DEXPORT_SYMTAB is to keep the symbol export mechanism quiet.
MODCFLAGS := $(CFLAGS) -D__KERNEL__ -DMODULE -fomit-frame-pointer \
             -DEXPORT_SYMTAB

ifeq ($(SMP),1)
MODCFLAGS += -D__SMP__
endif

ifeq ($(MODVER),1)
MODCFLAGS += -DMODVERSIONS -include $(LINUX_HEADERS)/linux/modversions.h
endif

.PHONY: dep
# Make all the default rule
all::

# Include all makefiles for sub-modules
INCLUDEFILES :=
ifneq ($(SRCDIRS),)
include $(patsubst %,%/Module.mk,$(SRCDIRS))
endif
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(INCLUDEFILES),)
include $(INCLUDEFILES)
endif
endif

# Making the dependency files - done automatically!
dep :

all ::

install :: all

clean::
	$(RM) lm_sensors-*

# Here, we define all implicit rules we want to use.

.SUFFIXES:

# We need to create dependency files. Tricky. We sed rule puts dir/file.d and
# dir/file.c # in front of the dependency file rule.

# .o files are used for modules
%.o: %.c
	$(CC) $(MODCFLAGS) -c $< -o $@

%.d: %.c
	$(CC) -M -MG $(MODCFLAGS) $< | \
	sed -e 's@^\(.*\)\.o:@$*.d $*.o: Makefile '`dirname $*.d`/Module.mk' @' > $@

endif
