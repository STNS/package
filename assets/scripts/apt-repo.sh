#!/bin/sh

set -e

sudo -k

echo "This script requires superuser authority to configure stns apt repository:"

echo "install lsb-release package"
sudo apt update -qqy
sudo apt install -y lsb-release gnupg ca-certificates
sudo sh <<'SCRIPT'
  set -x
  DIST=`lsb_release -a | tail -1 | awk '{ print $2 }'`
  echo "deb https://repo.stns.jp/${DIST}/ stns ${DIST}" > /etc/apt/sources.list.d/stns.list
  curl -fsS https://repo.stns.jp/gpg/GPG-KEY-stns| apt-key add -
  apt-get update -qq
SCRIPT

echo 'done'
