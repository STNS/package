#!/bin/sh

set -e

sudo -k

echo "This script requires superuser authority to configure stns yum repository:"

sudo sh <<'SCRIPT'
  set -x

  os_name=""
  releasever=""
  basearch=$(uname -i)

  if [ -f /etc/centos-release ]; then
    os_name="centos"
    releasever=$(rpm -q --qf "%{version}" -f /etc/centos-release| cut -d. -f1)
  elif [ -f /etc/os-release ]; then
    os_name="centos"
    releasever=$(rpm -q --qf "%{version}" -f /etc/os-release| cut -d. -f1)
  elif [ -f /etc/almalinux-release ]; then
    os_name="almalinux"
    releasever=$(rpm -q --qf "%{version}" -f /etc/almalinux-release| cut -d. -f1)
  elif [ -f /etc/rocky-release ]; then
    os_name="almalinux"
    releasever=$(rpm -q --qf "%{version}" -f /etc/rocky-release| cut -d. -f1)
  else
    echo "Unsupported OS. Please use CentOS or AlmaLinux."
    exit 1
  fi

  # import GPG key
  gpgkey_path=`mktemp`
  curl -fsS -o $gpgkey_path https://repo.stns.jp/gpg/GPG-KEY-stns
  rpm --import $gpgkey_path
  rm $gpgkey_path

  # add config for stns yum repos
  cat >/etc/yum.repos.d/stns.repo <<EOF;
[stns]
name=stns
baseurl=https://repo.stns.jp/$os_name/$basearch/$releasever
gpgcheck=1
EOF
SCRIPT

echo 'done'
