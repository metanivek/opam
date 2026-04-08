#!/bin/sh

set -euo pipefail

dockerfile=$(mktemp)
cat > "$dockerfile" << EOF
FROM ubuntu:22.04
RUN apt-get update && apt-get install -yy make autoconf git
COPY --chown=0:0 .git /mnt/.git
WORKDIR /mnt
RUN git reset --hard HEAD
RUN make configure
CMD cat configure
EOF

docker build -f "$dockerfile" -t cat-opam-configure .
docker run --rm cat-opam-configure > configure
