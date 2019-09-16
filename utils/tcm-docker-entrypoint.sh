#!/bin/bash

set -e

exec "/tini" "-g" "-s" "--" "/usr/local/bin/docker-entrypoint-tiny.sh" "$@";
