#!/usr/bin/perl
#
# i2ccheck.pl: check that a compatible version of i2c modules exists
# David Maze <dmaze@debian.org>
# $Id: i2ccheck.pl,v 1.1 2001/12/15 16:38:54 dmaze Exp $
#
# Usage: i2ccheck.pl $(KSRC) $(MODULE_LOC)/modules/i2c 2.6.0
# (Where the parameters are, in order, the location of the kernel
# source tree, the location of the standalone i2c source tree,
# and the minimum required version of i2c.)
# Prints "kernel" if the kernel version of i2c should be used,
# "i2c" if the standalone version of i2c should be used, or "error"
# if neither will work.

my ($ksrc, $i2c, $minver) = @ARGV;

# Look for acceptable versions.
my $kver = search_i2c_h("$ksrc/include/linux/i2c.h", $minver);
my $iver = search_i2c_h("$i2c/kernel/i2c.h", $minver);

# Prefer the standalone i2c, if it's available.
if ($iver && $kver && check_version($iver, $kver))
  {
    print "i2c\n";
  }
# If there's a kernel version and either no standalone i2c or the kernel
# is newer, use that instead.
elsif ($kver)
  {
    print "kernel\n";
  }
# Otherwise, if there's standalone i2c, use that.
elsif ($iver)
  {
    print "i2c\n";
  }
# Otherwise, we lose.
else
  {
    print "error\n";
  }

exit 0;

sub search_i2c_h
  {
    my ($fn, $minver) = @_;
    my $ver = undef;

    return undef unless -f $fn;
    open I2C, "<$fn";
    while (<I2C>)
      {
	if (/^\#define I2C_VERSION "(.*)"$/)
	  {
	    $ver = $1 if check_version($1, $minver);
	    last;
	  }
      }
    close I2C;
    return $ver;
  }

sub check_version
  {
    my ($candidate, $desired) = @_;
    # Assume that both versions are dot-separated strings of numbers.
    my @cvers = split('.', $candidate);
    my @dvers = split('.', $desired);
    my $i = 0;
    while ($i < $#cvers && $i < $#dvers)
      {
	return 1 if $cvers[$i] > $dvers[i];
	return 0 if $cvers[$i] < $dvers[i];
      }
    return 1 if $i < $#cvers;
    return 0 if $i < $#dvers;
    return 1;
}
