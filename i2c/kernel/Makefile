#################################################
# config
KERNEL_LOCATION=/usr/src/linux
CURRENT=$(shell uname -r)
I2CINCLUDES := i2c.h i2c-dev.h i2c-algo-bit.h i2c-algo-pcf.h \
               i2c-elektor.h i2c-pcf8584.h
I2CKERNELDIR := /usr/include/linux
I2CMODDIR := /lib/modules/$(CURRENT)/misc

#################################################
# some magic for using linux kernel settings
# when compiling module(s)

MOD_SUB_DIRS =
MX_OBJS       = i2c-core.o i2c-algo-bit.o i2c-algo-pcf.o

M_OBJS      = i2c-dev.o i2c-philips-par.o i2c-elv.o i2c-velleman.o i2c-elektor.o
EXTRA_CFLAGS = -Wno-unused


here:
	DIR=`pwd`; (cd $(KERNEL_LOCATION); make SUBDIRS=$$DIR modules)

install:
	su -c "cp -v $(M_OBJS) $(MX_OBJS) $(I2CMODDIR)"
	su -c "cp -v $(I2CINCLUDES) $(I2CKERNELDIR)"

clean:
	-rm -f $(M_OBJS) $(MX_OBJS) .*.o.flags *~ $(M_OBJS:.o=.d) \
               $(MX_OBJS:.o=.d)

up:
	insmod i2c-core.o i2c_debug=0
	insmod algo-bit.o bit_test=1  i2c_debug=1
	insmod bit-lp.o base=0x278
	insmod i2c-dev.o
	insmod drivers/eeprom.o test=1

down:
	-rmmod eeprom
	-rmmod i2c-dev
	-rmmod bit-lp
	-rmmod algo-bit
	-rmmod i2c-core

include $(KERNEL_LOCATION)/Rules.make
