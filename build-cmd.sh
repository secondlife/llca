#!/usr/bin/env bash


# Use this date on which we did this download as the bundle version number
echo "${mozilla_bundle_time:-LOCAL}.${revision:-0}" > VERSION.txt

# Run the script provided by curl that downloads and converts the Mozilla certificate authorities
perl ../mk-ca-bundle.pl -m -v -t

cp -r ../LICENSES .
