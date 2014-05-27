#!/bin/bash
#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#
WORKSPACE="/opt/workspace/NOTHS"
OPENRC="${WORKSPACE}/.openrc"

usage() {
  cat <<EOF
  Usage: $(basename $0) -H HOSTNAME -i IMAGE -f FLAVOR -n NETWORK 
    -H|--hostname HOSTNAME      : the hostname you wish to associate to the instance
    -d|--domain DOMAIN          : the domain name of the instance
    -h|--help                   : display this help menu
EOF
  exit 0
}

# step: get the command line options
while [ $# -gt 0 ]; do
  case $1 in 
    -H|--hostname)  HOSTNAME=$2   ; shift 2 ;;
    -d|--domain)    DOMAIN=$2     ; shift 2 ;;
    -h|--help)      usage                   ;;
    *)              shift         ;         ;;
  esac
done

HOSTNAME=${RD_OPTION_HOSTNAME:-$HOSTNAME}
DOMAIN=${RD_OPTION_DOMAIN:-$DOMAIN}

for i in logging openstack foreman; do 
  [ -f "${WORKSPACE}/common/${i}.sh" ] && source "${WORKSPACE}/common/${i}.sh" 
done

# step: perform some simple verification
[ -z $HOSTNAME  ] && error "you must specify the hostname of the instance"
[ -z $DOMAIN    ] && error "you must specify the domain of the instance"

# step: load the openstack credentials
annonce "loading the openstack credentials"
openstack_credential

FQDN="${HOSTNAME}.${DOMAIN}"

annonce "checking the instance: $FQDN exists in openstack"
# step: check the instance exist
instance_exists $FQDN || error "unable to find the instance in openstack, please check"

# step: check the instance is active and thus has addresses
annonce "checking the instancE: $FQDN is active"
is_active $FQDN       || error "the instance: $FQDN is not active at the moment"

# step: get the ip addresses and release from foreman
ADDRESSES=$(addresses $FQDN)
[ -z $ADDRESSES ]     && error "unable to retrieve the ip addresses from openstack"

# step: remove each of them from foreman
for ADDR in $ADDRESSES; do 
  annonce "deleting the ip address $ADDR from dns: $HOSTNAME"
  curl -sk -X DELETE -u ${FOREMAN_USERNAME}:${FOREMAN_PASSWORD} "${FOREMAN_PROXY}/dns/$ADDR"
  if [ $? -ne 0 ]; then
    error "unable to remove the ipaddress: $ADDR for instance: $HOSTNAME"
  fi
done
