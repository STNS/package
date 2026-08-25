#!/bin/sh

set -e

sudo -k

echo "This script requires superuser authority to configure stns apt repository:"

echo "install lsb-release package"
sudo apt update -qqy
sudo apt install -y lsb-release gnupg ca-certificates curl
sudo sh <<'SCRIPT'
  set -x
  DIST=`lsb_release -a | tail -1 | awk '{ print $2 }'`
  install -d -m 0755 /etc/apt/keyrings
  curl -fsS https://repo.stns.jp/gpg/GPG-KEY-stns | gpg --dearmor --yes -o /etc/apt/keyrings/stns.gpg
  chmod 0644 /etc/apt/keyrings/stns.gpg
  echo "deb [signed-by=/etc/apt/keyrings/stns.gpg] https://repo.stns.jp/${DIST}/ stns ${DIST}" > /etc/apt/sources.list.d/stns.list
  apt-get update -qq
SCRIPT

echo 'done'
