#!/usr/bin/env bash

# Because a key input to this build is external (the Mozilla CA repository),
# we must use the datetime stamp as a codeticket input value, so this has
# to be a custom build script

initialize_build

set -e

# add the datetime stamp before setting the revision number in initialize_version
export mozilla_bundle_time=$(date "+%Y%m%d%H%M")
python_cmd "$helpers/codeticket.py" addinput "Mozilla CA Bundle Timestamp" "${mozilla_bundle_time}"

initialize_version # sets $revision

export AUTOBUILD_PLATFORM=common

${AUTOBUILD} build

package_results=`mktemp -t results.XXXXXX`

${AUTOBUILD} package --results-file $(native_path "$package_results")

. "$package_results"

python_cmd "$helpers/codeticket.py" addoutput "Autobuild Package" $(native_path "${autobuild_package_filename}") > output.url

output_url=$(<output.url)

cat >>install_cmd.sh <<EOF
\${AUTOBUILD:-autobuild} installables edit '${autobuild_package_name}' url='${output_url}' hash='${autobuild_package_md5}'
EOF

python_cmd "$helpers/codeticket.py" addoutput "Autobuild Install Command" install_cmd.sh --mimetype text/plain --private --display \
    || fatal "upload of Autobuild Install Command failed"

python_cmd "$helpers/codeticket.py" addoutput "Autobuild Package Metadata" "${autobuild_package_metadata}" --mimetype text/xml \
    || fatal "upload of Autobuild Package Metadata failed"





