#!/usr/bin/env ruby
#
#   Author: Rohith
#   Date: 2014-05-22 23:55:29 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
module OpenstackBuild
  ROOT = File.expand_path File.dirname __FILE__

  require "#{ROOT}/openstack-build/version"

  autoload :Version,    "#{ROOT}/openstack-build/version"
  autoload :Utils,      "#{ROOT}/openstack-build/utils"
  autoload :Config,     "#{ROOT}/openstack-build/config"
  autoload :Logger,     "#{ROOT}/openstack-build/log"
  autoload :Stack,      "#{ROOT}/openstack-build/stack"

  def self.version
    OpenstackBuild::VERSION
  end 

  def self.load options 
    OpenstackBuild::Stack::new( options )
  end
end

