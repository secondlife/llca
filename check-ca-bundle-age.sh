#!/usr/bin/env bash
### -*- mode: shell-script;-*-
###
### Check the build time of the llca package 
###

Action="CHECK"
Max_CA_Bundle_Days=90
Packages_Dir=
ExitStatus=0

while [ $# -ne 0 -a $ExitStatus -eq 0 ]
do
    case ${1} in
        -p|--packages)
            if [ $# -lt 2 ]
            then
                echo "Must specify <packages-directory> with ${1}" 1>&2
                Action=USAGE
                ExitStatus=1
                break
            else
                Packages_Dir=${2}
                shift # consume the switch ( for n values, consume n-1 )
            fi
            ;;

        -d|--days)
            if [ $# -lt 2 ]
            then
                echo "Must specify <maximum-ca-package-days> with ${1}" 1>&2
                Action=USAGE
                ExitStatus=1
                break
            else
                Max_CA_Bundle_Days=${2}
                shift # consume the switch ( for n values, consume n-1 )
            fi
            ;;

        *)
            echo "Unrecognized arguments: $@" 1>&2
            Action=USAGE
            ExitStatus=1
            break
            ;;
    esac           

    shift # always consume 1
done

if [ "${Action}" = "CHECK" ]
then
    if [ -d "$Packages_Dir" ]
    then
        max_ca_bundle_seconds=$(( 60 * 60 * 24 * $Max_CA_Bundle_Days ))

        now=$(date '+%s')

        # the meta/llca/built file is produced by the package build
        build_time_file="${Packages_Dir}/meta/llca/built"
        if [ -r "$build_time_file" ]
        then
            bundle_built=$(<"$build_time_file")

            if [ $now -gt $(($bundle_built + $max_ca_bundle_seconds)) ]
            then
                echo "The certificate bundle is more than $max_ca_bundle_days old: failed" 1>&2
                ExitStatus=1
            else
                echo "The certificate bundle is less than $max_ca_bundle_days old: passed." 
            fi
        else
            echo "No build time record found at '$build_time_file'" 1>&2
            Action="USAGE"
            ExitStatus=1
        fi
    else
        echo "No packages directory at '$Packages_Dir'" 1>&2
        Action="USAGE"
        ExitStatus=1
    fi
fi

if [ "${Action}" = "USAGE" ]
then
    cat <<USAGE

Usage:
    
    check-ca-bundle-age {-p | --packages} <packages-directory> [ -d | -days <maximum-ca-package-days> ]
    
    Verify that the llca package in the packages-directory was build no more than maximum-ca-package-days ago.
    
    If not specified, maximum-ca-package-days is $Max_CA_Bundle_Days

USAGE
fi

exit $ExitStatus
