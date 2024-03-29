#!/bin/bash

echo "======== $0 ========"
set -x
set -e
set -o pipefail
set -o errtrace

OUTPUTDIR=./documentation

err_report() {
    echo "Error running '$1' [rc=$2] line $3 "
}

trap 'err_report "$BASH_COMMAND" $? $LINENO' ERR

DIR="$(pwd)"

# build the virtual environment to run ansible-test
cd $ANSIBLE_DIR
git clone https://github.com/ansible/ansible.git
cd ansible
ANSIBLE_DIR="$(pwd)"

python3 -m venv venv
. venv/bin/activate
pip install -r requirements.txt
. hacking/env-setup
pip install -r docs/docsite/requirements.txt
[[ -e $(find test/ -name sanity.txt) ]] && pip install -r $(find test/ -name sanity.txt)

# place the modules in the appropriate folder
cp $DIR/library/*.py $ANSIBLE_DIR/lib/ansible/modules/

set +e

rc=0
echo "-------- sanity test for python 2.7 --------"
for f in $DIR/library/*.py; do
    f="${f##*/}"
    ansible-test sanity ${f%%.py} --python 2.7
    rc=$(($rc + $?))
done

echo "-------- sanity test for python 3.7 --------"
for f in $DIR/library/*.py; do
    f="${f##*/}"
    ansible-test sanity ${f%%.py} --python 3.7
    rc=$(($rc + $?))
done

set -e

deactivate

exit $rc
