#!/bin/bash
#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#
WORKSPACE_DEFAULT="/opt/workspace/NOTHS"

usage() {
  cat <<EOF
  Usage: $(basename $0) -H HOSTNAME -i IMAGE -f FLAVOR -n NETWORK 
    -H|--hostname HOSTNAME      : the hostname you wish to associate to the instance
    -d|--domain DOMAIN          : the domain name of the instance
    -i|--ipaddress ADDRESS      : the ip address of the instance, otherwise we take it from nova
    -v|--verbose                : switch verbose mode on
    -h|--help                   : display this help menu

EOF
  exit 0
}

# step: get the command line options
while [ $# -gt 0 ]; do
  case $1 in 
    -H|--hostname)  HOSTNAME=$2   ; shift 2 ;;
    -d|--domain)    DOMAIN=$2     ; shift 2 ;;
    -v|--verbose)   VERBOSE=1     ; shift 1 ;;
    -h|--help)      usage                   ;;
    *)              shift         ;         ;;
  esac
done

HOSTNAME=${RD_OPTION_HOSTNAME:-$HOSTNAME}
DOMAIN=${RD_OPTION_DOMAIN:-$DOMAIN}

for i in logging openstack foreman; do 
  [ -f "${WORKSPACE}/common/${i}.sh" ] && source "${WORKSPACE}/common/${i}.sh" 
done

# step: load the openstack if required
[ -z "$IPADDRESS" ] || openstack_credential

# step: perform some simple verification
[ -z $HOSTNAME  ] && error "you must specify the hostname of the instance"
[ -z $DOMAIN    ] && error "you must specify the domain of the instance"
if [ -z $IPADDRESS ]; then
  [[ $IPADDRESS =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || error "the ip address $IPADDRESS is invalid";
  [[ $IPADDRESS =~ ^(10|172|192)\.*$ ]]             || error "the ip address must be an internal ip address";
  # step: check the ip address is not in use  
}

FQDN="${HOSTNAME}.${DOMAIN}"

annonce "checking the instance: $FQDN exists in openstack"
# step: check the instance exist
instance_exists $FQDN && error "unable to find the instance in openstack, please check"

annonce "attempting to acquire the ip addresses of instance: $FQDN"
# step: get the address from openstack - this might take multiple attempts
annonce "checking the status of the build"

INTERVAL=1

for i in {1..10}; do 
  if ! is_active $FQDN; then
    annonce "the instance is not yet active, waiting for now"
    sleep $INTERVAL
    next
  else
    # step: it is active, lets get the addresses
    ADDRESSES=$(addresses $FQDN)
    if [ -z $ADDRESSES ]; then
      annonce "the ip addresses are not available yet, lets wait for a bit"
      sleep $INTERVAL
      next
    fi 
    annonce "we have addresses: $ADDRESSES for instance: $HOSTNAME"
  fi
done

# step: add the ip addresses into DNS

