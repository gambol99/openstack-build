#!/usr/bin/env ruby
#
#   Author: Rohith
#   Date: 2014-05-22 23:55:29 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
module OpenstackBuild
  ROOT = File.expand_path File.dirname __FILE__

  require "#{ROOT}/rundeck-openstack/version"

  autoload :Version,    "#{ROOT}/rundeck-openstack/version"
  autoload :Utils,      "#{ROOT}/rundeck-openstack/utils"
  autoload :Logger,     "#{ROOT}/rundeck-openstack/log"
  autoload :Stack,      "#{ROOT}/rundeck-openstack/loader"

  def self.version
    OpenstackBuild::VERSION
  end 

  def self.load options 
    OpenstackBuild::Loader::new( options )
  end
end

