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
  Usage: $(basename $0) -H HOSTNAME -d DOMAIN -i IP_ADDRESS
    -H|--hostname HOSTNAME      : the hostname of the instance
    -d|--domain DOMAIN          : the domain name of the instance
    -i|--ipaddr IP_ADDRESS      : the ip address the instance should be 
    -h|--help                   : display this help menu

EOF
  exit 0
}

# get the command line options
while [ $# -gt 0 ]; do
  case $1 in 
    -H|--hostname)  HOSTNAME=$2               ; shift 2 ;;
    -d|--domain)    DOMAIN=$2                 ; shift 2 ;;
    -i|--ipaddr)    IP_ADDRESS$2              ; shift 2 ;;
    -h|--help)      usage                               ;;
    *)              shift                     ;         ;;
  esac
done

HOSTNAME=${RD_OPTION_HOSTNAME:-$HOSTNAME}
DOMAIN=${RD_OPTION_DOMAIN:-$DOMAIN}
IP_ADDRESS=${RD_OPTION_IP_ADDRESS:-$IP_ADDRESS}
FQDN="${HOSTNAME}.${DOMAIN}"

# step: import the modules
for i in logging openstack; do 
  [ -f "${WORKSPACE}/common/${i}.sh" ] && source "${WORKSPACE}/common/${i}.sh" 
done

# step: make sure we have all the arguments
[ -z $HOSTNAME   ] && error "you must specify the hostname of the instance"
[ -z $DOMAIN     ] && error "you must specify the domain of the instance"
[ -z $IP_ADDRESS ] && error "you must specify the ip address of the instance"

# step: check this exists
annonce "checking the dns entry for instance: $FQDN exists"
DNS_FOUND=0
host $FQDN | while read line; do 
  if [[ $line =~ ^${FQDN}\ has\ address\ $IP_ADDRESS$ ]]; then
    DNS_FOUND=1
    break
  elif [[ $line =~ ^.*not\found.*$ ]]; then
    error "the dns record for instance: $FQDN does not exist"
  fi
done

[ $DNS_FOUND -eq 0 ] || error "unable to find the dns entry for instance: $FQDN"
annonce "successfully found the dns for instance: $FQDN"

