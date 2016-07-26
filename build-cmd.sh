#!/usr/bin/env bash

exec 3>&1; export BASH_XTRACEFD=3; set -x
 
# This fetches an xml file that contains a pointer to the latest curl release tarball
curl -s 'https://curl.haxx.se/metalink.cgi?curl=tar.gz' > metalink.xml

# The use of a default xml namespace confuses the xmllint xpath processor, so remove it
xmllint --format metalink.xml | sed 's/xmlns="urn:ietf:params:xml:ns:metalink"//' > metalink_nons.xml

# Extract the name url of the latest release tarball
curl_release_tarball_name=$(xmllint --xpath 'string(/metalink/file/@name)' metalink_nons.xml)
curl_release_tarball_url=$(xmllint --xpath '/metalink/file/url[1]/text()' metalink_nons.xml)

# Fetch the tarball
curl -s "${curl_release_tarball_url}" > "${curl_release_tarball_name}"

# Extract the script mk-ca-bundle.pl from the tarball
curl_release_dir=$(echo "${curl_release_tarball_name}" | sed 's/.tar.gz//')
tar -x -z --strip-components 2 -f "${curl_release_tarball_name}" "${curl_release_dir}/lib/mk-ca-bundle.pl"

# Run the script provided by curl that downloads and converts the Mozilla certificate authorities
perl ./mk-ca-bundle.pl

# Use this date on which we did this download as the bundle version number
date "+%Y.%m.%d.${revision:-0}" > VERSION.txt

cp -r ../LICENSES .
