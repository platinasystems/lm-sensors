#!/bin/sh
# genchanges.sh - generate a changes file for a deb file generated via
#      the make-kpkg utility

# REV KSRC KMAINT and KEMAIL are expected to be passed through the
# environment

set -e
umask 022

VERS=`dpkg-parsechangelog | grep ^Version: | cut -d ' ' -f 2`
ARCH=`dpkg --print-architecture`

# the changes file's name
chfile="$KSRC/../lm-sensors-${KVERS}_${VERS}+${REV}_${ARCH}.changes"

dpkg-genchanges -b ${KMAINT:+-m"$KMAINT <$KEMAIL>"} -u"$KSRC/.." > "$chfile.pt"
pgp -fast ${KMAINT:+-u"$KMAINT"} < "$chfile.pt" > "$chfile"
rm "$chfile.pt"
