#!/usr/bin/env bash

# Run the script provided by curl that downloads and converts the Mozilla certificate authorities
perl ./packages/scripts/mk-ca-bundle.pl

date "+%Y.%m.%d.${revision:-0}" > VERSION.txt
