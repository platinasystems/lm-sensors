#!/usr/bin/perl

#    mkpatch - Create patches against the Linux kernel
#    Copyright (c) 1999  Frodo Looijaard <frodol@dds.nl>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

use strict;

use vars qw($temp);
$temp = "mkpatch/.temp";

# Generate a diff between the old kernel file and the new I2C file. We
# arrange the headers to tell us the old tree was under directory 
# `linux-old', and the new tree under `linux'.
# $_[0]: i2c package root (like /tmp/i2c)
# $_[1]: Linux kernel tree (like /usr/src/linux)
# $_[2]: Name of the kernel file
# $_[3]: Name of the patched file
sub print_diff
{
  my ($package_root,$kernel_root,$kernel_file,$package_file) = @_;
  my ($diff_command,$dummy);

  $diff_command = "diff -u2";
  if ( -e "$kernel_root/$kernel_file") {
    $diff_command .= " $kernel_root/$kernel_file ";
  } else {
    $diff_command .= " /dev/null ";
  }
  if ( -e "$package_root/$package_file") {
    $diff_command .= " $package_root/$package_file ";
  } else {
    $diff_command .= " /dev/null";
  }
  open INPUT, "$diff_command|" or die "Can't call `$diff_command'";
  $dummy = <INPUT>;
  $dummy = <INPUT>;
  print "--- linux-old/$kernel_file\t".`date`;
  print "+++ linux/$kernel_file\t".`date`;
    
  while (<INPUT>) {
    print;
  }
  close INPUT;
}

# Find all the lm_sensors code in a file
# $_[0]: Linux kernel tree (like /usr/src/linux)
# $_[1]: Name of the kernel file
# Returns a list of strings with the sensors codes
sub find_sensors_code
{
  my ($kernel_root,$kernel_file) = @_;
  my @res;
  open INPUT, "$kernel_root/$kernel_file" 
       or return @res;
  while (<INPUT>) {
    if (m@sensors code starts here@) {
      push @res,"";
      while (<INPUT>) {
        last if m@sensors code ends here@;
        $res[$#res] .= $_;
      }
    }
  }
  return @res;    
} 

# Here we generate diffs for all kernel files mentioned in OLDI2C 
# which change the invocation # `#include <linux/i2c.h>' to 
# `#include <linux/i2c-old.h>'. But first, we generate diffs to copy
# file <linux/i2c.h> to <linux/i2c-old.h>, if the kernel does not have
# this file yet.
# $_[0]: sensors package root (like /tmp/sensors)
# $_[1]: Linux kernel tree (like /usr/src/linux)
sub patch_old_i2c
{
  my ($package_root,$kernel_root) = @_;
  my (@files,$file);
  # If i2c.c does not exist, either we renamed it earlier, or there is no
  # i2c support in this kernel at all.
  return if not -e "$kernel_root/drivers/char/i2c.c";

  print_diff $kernel_root,$kernel_root,"include/linux/i2c-old.h", 
             "include/linux/i2c.h";


  open INPUT, "$package_root/mkpatch/OLDI2C" 
        or die "Can't open `$package_root/mkpatch/OLDI2C'";
  @files = <INPUT>;
  close INPUT;

  foreach $file (@files,"drivers/char/i2c-old.c") {
    chomp $file;
    if ($file eq "drivers/char/i2c-old.c") {
      open INPUT, "$kernel_root/drivers/char/i2c.c"
            or next;
    } else { 
      open INPUT, "$kernel_root/$file"
           or next;
    }
    open OUTPUT, ">$package_root/$temp"
           or die "Can't open `$package_root/$temp'";
    while (<INPUT>) {
      s@(\s*#\s*include\s*)<linux/i2c.h>@\1<linux/i2c-old.h>@;
      print OUTPUT;
    }
    close INPUT;
    close OUTPUT;
    print_diff $package_root,$kernel_root,$file,$temp;
  }
  print_diff "/dev",$kernel_root,"drivers/char/i2c.c","null";
}

# This generates diffs for kernel file Documentation/Configure.help. This
# file contains the help texts that can be displayed during `make *config'
# for the kernel.
# The new texts are put at the end of the file, or just before the
# lm_sensors texts.
# Of course, care is taken old lines are removed.
# $_[0]: i2c package root (like /tmp/i2c)
# $_[1]: Linux kernel tree (like /usr/src/linux)
sub gen_Documentation_Configure_help
{
  my ($package_root,$kernel_root) = @_;
  my $kernel_file = "Documentation/Configure.help";
  my $package_file = $temp;
  my $printed = 0;

  open INPUT,"$kernel_root/$kernel_file"
        or die "Can't open `$kernel_root/$kernel_file'";
  open OUTPUT,">$package_root/$package_file"
        or die "Can't open $package_root/$package_file";
  MAIN: while(<INPUT>) {
    if (m@I2C support@ or m@I2C bit-banging interfaces@ or
           m@Philips style parallel port adapter@ or
           m@ELV adapter@ or m@Velleman K9000 adapter@ or
           m@I2C PCF 8584 interfaces@ or m@Elektor ISA card@ or
           m@I2C device interface@ ) {
      $_ = <INPUT>;
      $_ = <INPUT>;
      $_ = <INPUT> while not m@^\S@ and not eof(INPUT);
      redo MAIN;
    }
    if (not $printed and (eof(INPUT) or m@I2C mainboard interfaces@)) {
      print OUTPUT <<'EOF';
I2C support
CONFIG_I2C
  I2C (pronounce: I-square-C) is a slow bus protocol developed by
  Philips. SMBus, or System Management Bus is a sub-protocol of I2C.

  Both I2C and SMBus are supported here. You will need this for 
  hardware sensors support, and in the future for Video for Linux
  support.

  Beside this option, you will also need to select specific drivers 
  for your bus adapter(s). 

I2C bit-banging interfaces
CONFIG_I2C_ALGOBIT
  This allows you to use a range of I2C adapters called bit-banging
  adapters. Why they are called so is rather technical and uninteresting;
  but you need to select this if you own one of the adapters listed
  under it.

Philips style parallel port adapter
CONFIG_I2C_PHILIPSPAR
  This supports parallel-port I2C adapters made by Philips. Unless you
  own such an adapter, you do not need to select this.

ELV adapter
CONFIG_I2C_ELV
  This supports parallel-port I2C adapters called ELV. Unless you 
  own such an adapter, you do not need to select this.

Velleman K9000 adapter
CONFIG_I2C_VELLEMAN
  This supports the Velleman K9000 parallel-port I2C adapter. Unless
  you own such an adapter, you do not need to select this.

I2C PCF 8584 interfaces
CONFIG_I2C_ALGOPCF
  This allows you to use a range of I2C adapters called PCF
  adapters. Why they are called so is rather technical and uninteresting;
  but you need to select this if you own one of the adapters listed
  under it.

Elektor ISA card
CONFIG_I2C_ELEKTOR
  This supports the PCF8584 ISA bus I2C adapter. Unless you own such
  an adapter, you do not need to select this.

I2C device interface
CONFIG_I2C_CHARDEV
  Here you find the drivers which allow you to use the i2c-* device 
  files, usually found in the /dev directory on your system. They
  make it possible to have user-space programs use the I2C bus.

EOF
      $printed = 1;
    }
    print OUTPUT;
  }
  close INPUT;
  close OUTPUT;
  print_diff $package_root,$kernel_root,$kernel_file,$package_file;
}

# This generates diffs for the main Linux Makefile.
# Three lines which add drivers/i2c/i2.a to the DRIVERS list are put just
# before the place where the architecture Makefile is included.
# Of course, care is taken old lines are removed.
# $_[0]: i2c package root (like /tmp/i2c)
# $_[1]: Linux kernel tree (like /usr/src/linux)
sub gen_Makefile
{
  my ($package_root,$kernel_root) = @_;
  my $kernel_file = "Makefile";
  my $package_file = $temp;
  my $printed = 0;

  open INPUT,"$kernel_root/$kernel_file"
        or die "Can't open `$kernel_root/$kernel_file'";
  open OUTPUT,">$package_root/$package_file"
        or die "Can't open $package_root/$package_file";
  MAIN: while(<INPUT>) {
    if (m@CONFIG_I2C@) {
      $_ = <INPUT> while not m@endif@;
      $_ = <INPUT>;
      $_ = <INPUT> if m@^$@;
      redo MAIN;
    }
    if (not $printed and 
        (m@include arch/\$\(ARCH\)/Makefile@ or m@CONFIG_SENSORS@)) {
      print OUTPUT <<'EOF';
ifeq ($(CONFIG_I2C),y)
DRIVERS := $(DRIVERS) drivers/i2c/i2c.a
endif

EOF
      $printed = 1;
    }
    print OUTPUT;
  }
  close INPUT;
  close OUTPUT;
  die "Automatic patch generation for `Makefile' failed.\n".
      "Contact the authors please!" if $printed == 0;
  print_diff $package_root,$kernel_root,$kernel_file,$package_file;
}

# This generates diffs for drivers/Makefile
# First, `i2c' is added to the ALL_SUB_DIRS list. Next, a couple of lines
# to add i2c to the SUB_DIRS and/or MOD_SUB_DIRS lists is put right before
# Rules.make is included.
# Of course, care is taken old lines are removed.
# $_[0]: i2c package root (like /tmp/i2c)
# $_[1]: Linux kernel tree (like /usr/src/linux)
sub gen_drivers_Makefile
{
  my ($package_root,$kernel_root) = @_;
  my $kernel_file = "drivers/Makefile";
  my $package_file = $temp;
  my $i2c_present;
  my $printed = 0;
  my $added = 0;

  open INPUT,"$kernel_root/$kernel_file"
        or die "Can't open `$kernel_root/$kernel_file'";
  open OUTPUT,">$package_root/$package_file"
        or die "Can't open $package_root/$package_file";
  MAIN: while(<INPUT>) {
    if (m@^ALL_SUB_DIRS\s*:=@) {
      $added = 1;
      $i2c_present = 0;
      while (m@\\$@) {
        $i2c_present = 1 if m@i2c@;
        print OUTPUT;
        $_ = <INPUT>;
      }
      $i2c_present = 1 if m@i2c@;
      s@$@ i2c@ if (not $i2c_present);
      print OUTPUT;
      $_ = <INPUT>;
      redo MAIN;
    } 
    if (m@CONFIG_I2C@) {
      $_ = <INPUT> while not m@^endif@;
      $_ = <INPUT>;
      $_ = <INPUT> if m@^$@;
      redo MAIN;
    } 
    if (not $printed and
        (m@^include \$\(TOPDIR\)/Rules.make$@ or
         m@^ifeq \(\$\(CONFIG_SENSORS\),y\)@)) {
      print OUTPUT <<'EOF';
ifeq ($(CONFIG_I2C),y)
SUB_DIRS += i2c
MOD_SUB_DIRS += i2c
else
  ifeq ($(CONFIG_I2C),m)
  MOD_SUB_DIRS += i2c
  endif
endif

EOF
     $printed = 1;
    }
    print OUTPUT;
  }
  close INPUT;
  close OUTPUT;
  die "Automatic patch generation for `Makefile' failed.\n".
      "Contact the authors please!" if $printed == 0 or $added == 0;
  print_diff $package_root,$kernel_root,$kernel_file,$package_file;
}

# This generates diffs for drivers/char/Makefile
# It changes all occurences of `i2c.o' to `i2c-old.o'.
# $_[0]: i2c package root (like /tmp/i2c)
# $_[1]: Linux kernel tree (like /usr/src/linux)
sub gen_drivers_char_Makefile
{
  my ($package_root,$kernel_root) = @_;
  my $kernel_file = "drivers/char/Makefile";
  my $package_file = $temp;
  open INPUT,"$kernel_root/$kernel_file"
        or die "Can't open `$kernel_root/$kernel_file'";
  open OUTPUT,">$package_root/$package_file"
        or die "Can't open $package_root/$package_file";
  while(<INPUT>) {
    s@i2c\.o@i2c-old\.o@;
    print OUTPUT;
  }
  close INPUT;
  close OUTPUT;
  print_diff $package_root,$kernel_root,$kernel_file,$package_file;
}

# This generates diffs for drivers/char/Config.in
# It adds a line just before CONFIG_APM or main_menu_option lines to include
# the I2C Config.in.
# Of course, care is taken old lines are removed.
# $_[0]: i2c package root (like /tmp/i2c)
# $_[1]: Linux kernel tree (like /usr/src/linux)
sub gen_drivers_char_Config_in
{
  my ($package_root,$kernel_root) = @_;
  my $kernel_file = "drivers/char/Config.in";
  my $package_file = $temp;
  my $ready = 0;
  my $printed = 0;

  open INPUT,"$kernel_root/$kernel_file"
        or die "Can't open `$kernel_root/$kernel_file'";
  open OUTPUT,">$package_root/$package_file"
        or die "Can't open $package_root/$package_file";
  MAIN: while(<INPUT>) {
    if (m@i2c@) {
      $_ = <INPUT>;
      $_ = <INPUT> if (m@^$@);
      redo MAIN;
    }
    if ($ready and not $printed and 
        (m@^mainmenu_option@ or m@CONFIG_APM@ or m@CONFIG_ALPHA_BOOK1@ or
         m@source drivers/sensors/Config.in@)) {
      $printed = 1;
      print OUTPUT <<'EOF';
source drivers/i2c/Config.in

EOF
    }
    $ready = 1 if (m@^mainmenu_option@);
    print OUTPUT;
  }
  close INPUT;
  close OUTPUT;
  die "Automatic patch generation for `drivers/char/Config.in' failed.\n".
      "Contact the authors please!" if $printed == 0;
  print_diff $package_root,$kernel_root,$kernel_file,$package_file;
}
 

# This generates diffs for drivers/char/mem.c They are a bit intricate.
# Lines are generated at the beginning to declare i2c_init and i2c_init_all.
# The first is the invocation for the old I2C driver, the second for the
# new driver. At the bottom, a call to i2c_init_all is added when the
# new I2C stuff is configured in.
# Of course, care is taken old lines are removed.
# $_[0]: i2c package root (like /tmp/i2c)
# $_[1]: Linux kernel tree (like /usr/src/linux)
sub gen_drivers_char_mem_c
{
  my ($package_root,$kernel_root) = @_;
  my $kernel_file = "drivers/char/mem.c";
  my $package_file = $temp;
  my $right_place = 0;
  my $done = 0;
  my $atstart = 1;
  my $pr1 = 0;
  my $pr2 = 0;

  open INPUT,"$kernel_root/$kernel_file"
        or die "Can't open `$kernel_root/$kernel_file'";
  open OUTPUT,">$package_root/$package_file"
        or die "Can't open $package_root/$package_file";
  MAIN: while(<INPUT>) {
    if (m@#include <linux/i2c.h>@) {
       $_=<INPUT>;
       redo MAIN;
    }
    if ($atstart and m@#ifdef@) {
      print OUTPUT << 'EOF';
#ifdef CONFIG_VIDEO_BT848
extern int i2c_init(void);
#endif
#ifdef CONFIG_I2C
extern int i2c_init_all(void);
#endif
EOF
      $atstart = 0;
      $pr1 = 1;
    }
    while (not $right_place and (m@CONFIG_I2C@ or m@CONFIG_VIDEO_BT848@)) {
      $_ = <INPUT> while not m@#endif@;
      $_ = <INPUT>;
      redo MAIN;
    }
    $right_place = 1 if (m@lp_init\(\);@);
    if ($right_place and m@CONFIG_I2C@) {
      $_ = <INPUT> while not m@#endif@;
      $_ = <INPUT>;
      $_ = <INPUT> if m@^$@;
      redo MAIN;
    }
    if ($right_place and not $done and
        (m@CONFIG_VIDEO_BT848@ or m@return 0;@ or m@CONFIG_SENSORS@)) {
      print OUTPUT <<'EOF';
#ifdef CONFIG_I2C
	i2c_init_all();
#endif

EOF
      $done = 1;
      $pr2 = 1;
    }
    print OUTPUT;
  }
  close INPUT;
  close OUTPUT;
  die "Automatic patch generation for `drivers/char/mem.c' failed.\n".
      "Contact the authors please!" if $pr1 == 0 or $pr2 == 0;
  print_diff $package_root,$kernel_root,$kernel_file,$package_file;
}
 

# Main function
sub main
{
  my ($package_root,$kernel_root,%files,%includes,$package_file,$kernel_file);
  my ($diff_command,$dummy,$data0,$data1,$sedscript,@sensors_subs);

  # --> Read the command-line
  $package_root = $ARGV[0];
  die "Package root `$package_root' is not found\n" 
        unless -d "$package_root/mkpatch";
  $kernel_root = $ARGV[1];
  die "Kernel root `$kernel_root' is not found\n" 
        unless -f "$kernel_root/Rules.make";

  patch_old_i2c $package_root, $kernel_root;
         

  # --> Read FILES
  open INPUT, "$package_root/mkpatch/FILES" 
        or die "Can't open `$package_root/mkpatch/FILES'";
  while (<INPUT>) {
    ($data0,$data1) = /(\S+)\s+(\S+)/;
    $files{$data0} = $data1;
  } 
  close INPUT;

  # --> Read INCLUDES
  open INPUT, "$package_root/mkpatch/INCLUDES" 
        or die "Can't open `$package_root/mkpatch/INCLUDES'";
  while (<INPUT>) {
    ($data0,$data1) = /(\S+)\s+(\S+)/;
    $includes{$data0} = $data1;
    $sedscript .= 's,(#\s*include\s*)'.$data0.'(\s*),\1'."$data1".'\2, ; ';
  } 
  close INPUT;

  # --> Start generating
  foreach $package_file (sort keys %files) {
    $kernel_file = $files{$package_file};
    @sensors_subs = find_sensors_code "$kernel_root","$kernel_file";
    open INPUT, "$package_root/$package_file"
         or die "Can't open `$package_root/$package_file'";
    open OUTPUT, ">$package_root/$temp"
         or die "Can't open `$package_root/$temp'";
    while (<INPUT>) {
      eval $sedscript;
      if (m@sensors code starts here@) {
        print OUTPUT;
        while (<INPUT>) {
           last if m@sensors code ends here@;
        }
        print OUTPUT $sensors_subs[0];
        shift @sensors_subs
      }
      print OUTPUT;
    }
    close INPUT;
    close OUTPUT;
    print_diff "$package_root","$kernel_root","$kernel_file","$temp";
  }

  gen_Makefile $package_root, $kernel_root;
  gen_drivers_Makefile $package_root, $kernel_root;
  gen_drivers_char_Config_in $package_root, $kernel_root;
  gen_drivers_char_mem_c $package_root, $kernel_root;
  gen_drivers_char_Makefile $package_root, $kernel_root;
  gen_Documentation_Configure_help $package_root, $kernel_root;
}

main;

