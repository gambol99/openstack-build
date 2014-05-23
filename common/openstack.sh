#!/bin/bash
#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#

openstack_credential() {
  [ -e $OPENRC ] || error "unable to find the openstack credentials file"
  [ -f $OPENRC ] || error "the openstack credentials is not a regular file"
  [ -r $OPENRC ] || error "the openstack credentials file is not readable"
  source $OPENRC
}

keypair_exists() {
  $NOVA keypair-list | grep -q $@ && return 0 || return 1
}

hypervisor_exists() {
  $NOVA hypervisor-list | grep -q $1 ] && return 0 || return 1
}

network_exists() {
  $NOVA network-list | grep -q $1 && return 0 || return 1
}

network_id() {
  ID=$($NOVA network-list | grep $1 | cut -d' ' -f2)
  if [[ ! $ID =~ ^[[:alnum:]]{8}-([[:alnum:]]{4}-){3}[[:alnum:]]{12}$ ]]; then 
    error "the network id $ID retrieve looks invalid to me"
  fi
  echo $ID
}

instance_exists() {
  $NOVA list | grep -q $1 && return 0 || return 1
}

image_exists() {
  $NOVA image-list | grep -q $1  && return 0 || return 1
}

flavor_exists() {
  $NOVA flavor-list | grep -q $1 && return 0 || return 1
}
