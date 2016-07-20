#!/usr/bin/env bash

perl ./packages/scripts/mk-ca-bundle.pl

date "+%Y.%m.%d.${revision:-0}" > VERSION.txt
