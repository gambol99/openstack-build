#!/usr/bin/env ruby
#
#   Author: Rohith
#   Date: 2014-05-22 23:55:29 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'openstack-build'
require 'optparse'
require 'openstruct'

commands = {
  :create => OptionParse::new { |o|
    [ :hostname, :image, :flavor, :keypair, :hypervisor, :security_group].each do |x|
      field = x.to_s.upcase
      o.on( "-#{x[0,1].upcase} #{x.to_s.upcase} #{field}", "--#{x} #{field}", "the #{x} you wish to assign" ) { |x| options.create.x.to_sym = x }
    end
    o.on( '-n NETWORK', '--network NETWORK', 'the network/s you wish to assign to the instance' ) do |x| 
      options.create.networks = [] unless options.create.networks?
      options.create.networks << x 
    end
  },
  :instance => OptionParse::new { |o|
      

  }
}

options = OpenStruct.new 
Parser = OptionParse::new do |o|
  o.banner "Usage: #{__FILE__} -H HOSTNAME -f FLAVOR "
  commands.keys.each do |c|


  end

end


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
    -v|--verbose                : switch verbose mode on
    -h|--help                   : display this help menu

