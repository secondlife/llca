#!/usr/bin/env bash

# Because a key input to this build is external (the Mozilla CA repository),
# we must use the datetime stamp as a codeticket input value, so this has
# to be a custom build script

initialize_build

set -e

# This fetches an xml file that contains a pointer to the latest curl release tarball
curl -s 'https://curl.haxx.se/metalink.cgi?curl=tar.gz' > metalink.xml

# The use of a default xml namespace confuses the xmllint xpath processor, so remove it
xmllint --format metalink.xml | sed 's/xmlns="urn:ietf:params:xml:ns:metalink"//' > metalink_nons.xml

# Extract the name and url of the latest release tarball
curl_release_tarball_name=$(xmllint --xpath 'string(/metalink/file/@name)' metalink_nons.xml)
curl_release_tarball_url=$(xmllint --xpath '/metalink/file/url[1]/text()' metalink_nons.xml)

# Fetch the tarball
curl -s "${curl_release_tarball_url}" > "${curl_release_tarball_name}"

# Extract the script mk-ca-bundle.pl from the tarball
curl_release_dir=$(echo "${curl_release_tarball_name}" | sed 's/.tar.gz//')
tar -x -z --strip-components 2 -f "${curl_release_tarball_name}" "${curl_release_dir}/lib/mk-ca-bundle.pl"

export mozilla_bundle_time=$(date "+%Y%m%d%H%M")
echo python_cmd "$helpers/codeticket.py" addinput "Mozilla CA Bundle Timestamp" "${mozilla_bundle_time}"

initialize_version # sets $revision

${AUTOBUILD} build

package_results=`mktemp -t results.XXXXXX`

${AUTOBUILD} package --results-file $(native_path "$package_results")

. "$package_results"

python_cmd "$helpers/codeticket.py" addoutput "Autobuild Package" $(native_path "${autobuild_package_filename}") > output.url

output_url=$(cat output.url)

cat >>install_cmd.sh <<EOF
\${AUTOBUILD:-autobuild} installables edit '${autobuild_package_name}' url='${output_url}' hash='${autobuild_package_md5}'
EOF

python_cmd "$helpers/codeticket.py" addoutput "Autobuild Install Command" install_cmd.sh --mimetype text/plain --private --display \
    || fatal "upload of Autobuild Install Command failed"

python_cmd "$helpers/codeticket.py" addoutput "Autobuild Package Metadata" "${autobuild_package_metadata}" --mimetype text/xml \
    || fatal "upload of Autobuild Package Metadata failed"





