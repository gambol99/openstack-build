#!/bin/bash
#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
WORKSPACE="/opt/workspace/NOTHS"
OPENRC="${WORKSPACE}/.openrc"

usage() {
  cat <<EOF
  Usage: $(basename $0) -H HOSTNAME -d domain 
    -H|--hostname HOSTNAME      : the hostname you wish to associate to the instance
    -d|--domain DOMAIN          : the domain of the instance 
    -v|--verbose                : switch verbose mode on
    -h|--help                   : display this help menu

EOF
  exit 0
}

# get the command line options
while [ $# -gt 0 ]; do
  case $1 in 
    -H|--hostname)  HOSTNAME=$2               ; shift 2 ;;
    -d|--domain)    DOMAIUN=$2                ; shift 2 ;;
    -h|--help)      usage                               ;;
    *)              shift                     ;         ;;
  esac
done

HOSTNAME=${RD_OPTION_HOSTNAME:-$HOSTNAME}
DOMAIN=${RD_OPTION_DOMAIN:-$DOMAIN}

# step: import the modules
for i in logging openstack; do 
  [ -f "${WORKSPACE}/common/${i}.sh" ] && source "${WORKSPACE}/common/${i}.sh" 
done

# step: make sure we have all the arguments
[ -z $HOSTNAME ] && error "you must specify the hostname of the instance"
[ -z $DOMAIN   ] && error "you must specify the domain of the instance"

FQDN="${HOSTNAME}.${DOMAIN}"

annonce "loading the openstack credentials"
openstack_credential

annonce "checking the instance exists in openstack"
instance_exists $FQDN   || error "the instance $FQDN does not exist, please check"

annonce "destroying the instance: $FQDN"

$NOVA delete $FQDN
[ $? -ne 0 ] && error "we have a problem deleting the instance"

annonce "succesfully destryed the instance"

