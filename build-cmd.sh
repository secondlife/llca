#!/usr/bin/env bash
# This is the build script executed by 'autobuild build'

set -e
set -x

# Fetch a pointer to the latest curl release tarball from the curl distribution site
curl -s 'https://curl.se/metalink.cgi?curl=tar.gz' > metalink.xml

# The use of a default xml namespace confuses the xmllint xpath processor, so remove it
xmllint --format metalink.xml | sed 's/xmlns="urn:ietf:params:xml:ns:metalink"//' > metalink_no_namespace.xml

# Extract the name and url of the latest release tarball
curl_release_tarball_name=$(xmllint --xpath 'string(/metalink/file/@name)' metalink_no_namespace.xml)
curl_release_tarball_url=$(xmllint --xpath '/metalink/file/url[1]/text()' metalink_no_namespace.xml)

# Fetch the curl distribution tarball
curl -s "${curl_release_tarball_url}" > "${curl_release_tarball_name}"

# Extract the script mk-ca-bundle.pl from the curl distribution
curl_release_dir=$(echo "${curl_release_tarball_name}" | sed 's/.tar.gz//')
tar -x -z --strip-components 2 -f "${curl_release_tarball_name}" "${curl_release_dir}/lib/mk-ca-bundle.pl"
# Patch mk-ca-bundle.pl to add time validity tests
patch < ../mk-ca-bundle.patch

# Get the certdata.txt file directly from Mozilla (it appears that the location in mk-ca-bundle.pl is not current)
# see https://www.mozilla.org/en-US/about/governance/policies/security-group/certs/
curl -s -L "https://mxr.mozilla.org/mozilla-central/source/security/nss/lib/ckfw/builtins/certdata.txt" -o certdata.txt
ls -l certdata.txt

# Use the date/time on which we did this download as the bundle version number
llca_version="${mozilla_bundle_time:=$(date "+%Y%m%d%H%M")}.${revision:-0}"
echo "Converting certificates for version $llca_version"
echo "$llca_version" > VERSION.txt

# Run the script provided by curl to convert the Mozilla certificate authorities; do not use it to download
perl ./mk-ca-bundle.pl -m -v -t -n -f

# Verify and add the LindenLab self-signed CA (used for simhost certificates and other *.<grid>.lindenlab.com certs)
openssl verify -verbose -CAfile ../LindenLab.crt ../LindenLab.crt
cat ../LindenLab.crt >> ca-bundle.crt

# Record when this was built in an easy way to compare; see check-ca-bundle-age.sh
test -d meta/llca || mkdir -p meta/llca
date '+%s' > meta/llca/built
# and add the script to check that in builds that consume this one
test -d bin || mkdir bin
cp ../check-ca-bundle-age.sh bin/

# Record the license for this package
cp -r ../LICENSES .
