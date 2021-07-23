#!/bin/bash

set -x

test -z ${PRODUCT:-} && product=min-web-front
test -z ${USER:-} && USER=ubuntu

while read -r dir ; do
   test -d /opt/$PRODUCT/src/python/$dir/.venv && sudo rm -r /opt/$PRODUCT/src/python/$dir/.venv
   cp -r /home/$USER/opt/$PRODUCT/src/python/$dir/.venv /opt/$PRODUCT/src/python/$dir/.venv
   perl -pi -e "s|/home/$USER||g" /opt/$PRODUCT/src/python/$dir/.venv/bin/activate
done < <(cat << EOF
api-caller
min-jinja
EOF
)
trap : TERM INT; sleep infinity & wait
