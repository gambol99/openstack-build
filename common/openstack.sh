#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
NOVA="/usr/bin/nova"

openstack_credential() {
  [ -e $OPENRC ] || error "unable to find the openstack credentials file"
  [ -f $OPENRC ] || error "the openstack credentials is not a regular file"
  [ -r $OPENRC ] || error "the openstack credentials file is not readable"
  source $OPENRC
}

is_active() {
  # step: check if the instance exists?
  instance_exists "$1" || return 1
  # step: check if the instance is active
  $NOVA list | grep -q ACTIVE && return 0 || return 1
}

get_addresses() {
  local attempts=10
  local interval=1
  local instance=$1
  for i in {1..$attempts}; do
    if is_active $instance; then 
      return addresses $instance
    else
      sleep $interval
    fi
  done
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

addresses() {
  $NOVA list | grep $1 | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}'
}
