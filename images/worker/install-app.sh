#!/bin/bash
set -e
set -x

APP=$1

cd /home/frappe/frappe-bench

# if $APP == "press" skip removing .git
if [ "$APP" != "press" ]; then
    rm -rf "apps/$APP/.git"
fi

env/bin/pip install -e "apps/$APP"

echo "$APP" >>sites/apps.txt
