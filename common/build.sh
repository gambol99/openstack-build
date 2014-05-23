#!/bin/bash


# defaults
KEYPAIR="default"

usage() {
  cat <<EOF
  Usage: $(basename $0) -H HOSTNAME -i IMAGE -f FLAVOR -n NETWORK 
    -H|--hostname HOSTNAME      : the hostname you wish to associate to the instance
    -i|--image IMAGE            : the name of the image to boot from 
    -f|--flavor FLAVOR          : the openstack flavor you wish to use 
    -n|--network NETWORK        : the network the instance should be associate to (can use multiples)
    -k|--keypair KEYPAIR        : the name of the keypair to use on the instance (defaults to $KEYPAIR)
    -a|--hypervisor HOST        : specify the hypervisor the instance should live on 
    -O|--openrc FILE            : the location of openstack credentials file 
    -W|--workspace DIRECTORY    : the location of the build workspace
    -v|--verbose                : switch verbose mode on
    -h|--help                   : display this help menu

EOF
  exit 0
}

# get the command line options
while [ $# -gt 0 ]; do
  case $1 in 
    -H|--hostname)  HOSTNAME=$2               ; shift 2 ;;
    -i|--image)     IMAGE=$2                  ; shift 2 ;;
    -f|--flavor)    FLAVOR=$2                 ; shift 2 ;;
    -n|--network)   NETWORKS=( $NETWORKS $2 ) ; shift 2 ;;
    -d|--domain)    DOMAIN=$2                 ; shift 2 ;;
    -k|--keypair)   KEYPAIR=$2                ; shift 2 ;;
    --hypervisor)   HYPERVISOR=$2             ; shift 2 ;;
    -O|--openrc)    OPENRC=$2                 ; shift 2 ;;
    -v|--verbose)   VERBOSE=1                 ; shift 1 ;;
    -h|--help)      usage                               ;;
    *)              shift                     ;         ;;
  esac
done

WORKSPACE_DEFAULT="/opt/workspace/NOTHS"
HOSTNAME=${RD_OPTION_HOSTNAME:-$HOSTNAME}
IMAGE=${RD_OPTION_IMAGE:-$IMAGE}
FLAVOR=${RD_OPTION_FLAVOR:-$FLAVOR}
NETWORKS=${RD_OPTION_NETWORKS:-$NETWORKS}
KEYPAIR=${RD_OPTION_KEYPAOR:-$KEYPAIR}
DOMAIN=${RD_OPTION_DOMAIN:-$DOMAIN}
WORKSPACE=${RD_WORKSPACE:-$WORKSPACE_DEFAULT}
OPENRC=${OPENRC:-$WORKSPACE/.openrc}

# step: import the modules
for i in logging openstack; do 
  [ -f "${WORKSPACE}/common/${i}.sh" ] && source "${WORKSPACE}/common/${i}.sh" 
done

# step: make sure we have all the arguments
[ -z $HOSTNAME ] && error "you must specify the hostname of the instance"
[ -z $DOMAIN   ] && error "you must specify the domain of the instance"
[ -z $IMAGE    ] && error "you must specify the image of the instance"
[ -z $FLAVOR   ] && error "you must specify the flavor of the instance"
[ -z $NETWORKS ] && error "you must specify the network/s of the instance"
[ -z $KEYPAIR  ] && error "you must specify the keypair of the instance"

FQDN="${HOSTNAME}.${DOMAIN}"

annonce "loading the openstack credentials"
openstack_credential

annonce "checking the image $IMAGE exist in openstack"
image_exists $IMAGE     || error "the image $IMAGE does not exist, please check"

annonce "checking the flavor $FLAVOR exist in openstack"
flavor_exists $FLAVOR   || error "the flavor $FLAVOR does not exists, please check"

annonce "checking the keypair exists"
keypair_exists $KEYPAIR || error "the keypair $KEYPAIR does not exist, please check"

annonce "check the hostname does not already exist"
instance_exists $FQDN   && error "the instance '${FQDN}' already exist, please choose another hostname"

NETWORK_ID=""
for NETWORK in ${NETWORKS[@]}; do 
  annonce "checking for network $NETWORK in openstack"
  if ! network_exists $NETWORK; then
    error "the network $NETWORK does not exist in openstack"
  fi  
  ID="--nic net-id=$(network_id $NETWORK)"
  NETWORK_ID="$NETWORK_ID $ID"
done

if [ ! -n $HYPERVISOR ]; then
  annonce "checking the hypervisor: $HYPERVISOR exists"
  hypervisor_exists $HYPERVISOR || error "the hypervisor: $HYPERVISOR does not exist, please check"
fi

annonce "booting the instance: $FQDN, image: $IMAGE, flavor: $FLAVOR"
OPTIONS="--image ${IMAGE} --flavor ${FLAVOR} --key-name $KEYPAIR $NETWORK_ID "
[ -z $HYPERVISOR ] || OPTIONS="$OPTIONS --availability-zone nova:$HYPERVISOR "

$NOVA boot $OPTIONS $FQDN
[ $? -ne 0 ] && error "we have a problem booting the image"

annonce "succesfully booted the image"

