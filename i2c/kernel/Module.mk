#  Module.mk - Makefile for a Linux module for reading sensor data.
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

# Note that MODULE_DIR (the directory in which this file resides) is a
# 'simply expanded variable'. That means that its value is substituted
# verbatim in the rules, until it is redefined. 
MODULE_DIR := kernel
KERNELDIR := $(MODULE_DIR)

# Regrettably, even 'simply expanded variables' will not put their currently
# defined value verbatim into the command-list of rules...
# We will only include those modules which are not already built into this
# kernel.
KERNELTARGETS :=
KERNELINCLUDES :=
ifneq ($(shell if grep -q '^CONFIG_I2C=y' $(LINUX)/.config; then echo 1; fi),1)
KERNELTARGETS += $(MODULE_DIR)/i2c-core.o
KERNELINCLUDES += $(MODULE_DIR)/i2c.h $(MODULE_DIR)/i2c-id.h
endif
ifneq ($(shell if grep -q '^CONFIG_I2C_CHARDEV=y' $(LINUX)/.config; then echo 1; fi),1)
KERNELTARGETS += $(MODULE_DIR)/i2c-dev.o
KERNELINCLUDES += $(MODULE_DIR)/i2c-dev.h
endif
ifneq ($(shell if grep -q '^CONFIG_I2C_ALGOBIT=y' $(LINUX)/.config; then echo 1; fi),1)
KERNELTARGETS += $(MODULE_DIR)/i2c-algo-bit.o
KERNELINCLUDES += $(MODULE_DIR)/i2c-algo-bit.h
endif
ifneq ($(shell if grep -q '^CONFIG_I2C_PHILIPSPAR=y' $(LINUX)/.config; then echo 1; fi),1)
KERNELTARGETS += $(MODULE_DIR)/i2c-philips-par.o
endif
ifneq ($(shell if grep -q '^CONFIG_I2C_ELV=y' $(LINUX)/.config; then echo 1; fi),1)
KERNELTARGETS += $(MODULE_DIR)/i2c-elv.o
endif
ifneq ($(shell if grep -q '^CONFIG_I2C_VELLEMAN=y' $(LINUX)/.config; then echo 1; fi),1)
KERNELTARGETS += $(MODULE_DIR)/i2c-velleman.o
endif
ifneq ($(shell if grep -q '^CONFIG_I2C_ALGOPCF=y' $(LINUX)/.config; then echo 1; fi),1)
KERNELTARGETS += $(MODULE_DIR)/i2c-algo-pcf.o
KERNELINCLUDES += $(MODULE_DIR)/i2c-algo-pcf.h
endif
ifneq ($(shell if grep -q '^CONFIG_I2C_ELEKTOR=y' $(LINUX)/.config; then echo 1; fi),1)
KERNELTARGETS += $(MODULE_DIR)/i2c-elektor.o
KERNELINCLUDES += $(MODULE_DIR)/i2c-elektor.h $(MODULE_DIR)/i2c-pcf8584.h
endif

# Include all dependency files
INCLUDEFILES += $(KERNELTARGETS:.o=.d)

all-kernel: $(KERNELTARGETS)
all :: all-kernel

install-kernel: all-kernel
	$(MKDIR) $(MODDIR) $(LINUX_INCLUDE_DIR)
	$(INSTALL) -o root -g root -m 644 $(KERNELTARGETS) $(MODDIR)
	$(INSTALL) -o root -g root -m 644 $(KERNELINCLUDES) $(LINUX_INCLUDE_DIR)
install :: install-kernel

clean-kernel:
	$(RM) $(KERNELDIR)/*.o $(KERNELDIR)/*.d $(KERNELDIR)/.*.o.flags 
	$(RM) $(KERNELDIR)/*~
clean :: clean-kernel

