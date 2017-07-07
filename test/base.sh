#!/usr/bin/env bash

set -o pipefail

PGID=$(ps -o pgid -p $$ | tail -1)
if [ "$PGID" != "$$" ]; then
	which setsid &>/dev/null && exec setsid "$0" "$@"
	which script &>/dev/null && exec script -q /dev/null "$0" "$@"
	echo "ERROR: failed to become group leader"
	exit 1
fi

export R=$(realpath $(dirname $0/)/../)
export DBENV_ROOT=${R}
export TMPDIR=$(realpath $(dirname $0))
T=$(mktemp -d ${TMPDIR}/tmpXXX)
FULL_PATH=$(realpath $0)

cleanup() {
    if [ -d ${T} ]; then
        rm -r ${T}
    fi

    kill -TERM -$$ >/dev/null
}

trap "exit" HUP TERM
trap "cleanup" EXIT

die() {
    local lineno=${1}

    echo
    echo "    Test failed on line ${lineno}:"
    echo "        "$(sed -n "${lineno}p" ${FULL_PATH})
    exit 1
}

setup() {
    [ -d ${T} ] && rm -r ${T}
    mkdir -p ${T}
    pushd ${T} >/dev/null
}

setup

tests=$(compgen -A function | grep test_ | sort)
failed=
for ut in ${tests}; do
    echo -n "Running ${ut}"
    if ! (${ut}); then
        failed="${failed} ${ut}"
    else
        echo " ... success"
    fi
done

echo
if [ -n "${failed}" ]; then
    echo "The following test(s) failed:"
    for ut in ${failed}; do
        echo "    ${ut}"
    done
    exit 1
fi

echo "All tests passed"
exit 0
