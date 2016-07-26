#!/usr/bin/env bash

# Run the script provided by curl that downloads and converts the Mozilla certificate authorities
perl ./packages/scripts/mk-ca-bundle.pl

# Use this date on which we did this download as the bundle version number
date "+%Y.%m.%d.${revision:-0}" > VERSION.txt

cp -r ../LICENSES .

# HACK WARNING !
#
# The real output of this package is the ca-bundle.txt file, which is platform independent,
# so we build the package on Linux because it already has all the perl support needed
# by mk-ca-bundle.pl, but as platform 'common' and use the output of that one build on all
# platforms. This avoids the possibility of different bundles on different platforms, and
# the need to install the requisite perl support in our CYGWIN (Windows) build hosts.
#
# This would create a problem because this package depends directly on curl for the
# mk-ca-buindle.pl script (and so indirectly on zlib and openssl), which are platform dependent.
# If, as is normally the case, this package is built on the Linux platform and then resulting
# llca package is installed in a CYGWIN build, autobuild will fail because it will see a conflict
# between the CYGWIN builds of curl, zlib, and openssl and the Linux versions of those packages
# it would find in the dependencies of this package.
#
# We overcome this by overwriting the installed-packages file here with one that contains no
# dependencies so that the resulting llca package will not create conflicts on any platform
# except with some other version of itself.
cp ../no-depends.xml ./packages/installed-packages.xml
