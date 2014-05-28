#!/usr/bin/env ruby
#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','../lib')
require 'openstack-build'
require 'optparse'
require 'colorize'
require 'pp'

def check message, &block 
  begin 
    puts "\n[check]".green << ": #{message}\n"
    start = Time.now
    yield
    timetake = Time.now - start
    puts "[time] %f.2ms".colorize(:light_blue) % [ timetake ]
  rescue Exception => e 
    puts "[failed] #{e.message}"
  end
end

begin 
  options = {
    :stack  => 'qa',
    :config => './config.yaml'
  }
  stack = OpenstackBuild.load( options )

  start_time = Time.now

  check 'pulling a list of networks' do 
    puts "networks: " << stack.networks.join(', ')
  end

  check "pulling the instances" do 
    puts "instances: " << stack.servers.join(', ')  
  end

  check "pulling the images: " do 
    puts "images: " << stack.images.join(', ')
  end

  check "checking an instance exists" do 
    instance = stack.servers.first
    puts  "instance: %s exists: %s"       % [ instance, stack.exists?( instance ) ]
    puts  "instance: noname, exists: %s"  % [ stack.exists?( 'noname') ]
  end

  check "pulling details on an instance" do 
    name      = stack.servers.first
    instance  = stack.server( name )
    puts "instance: %s addresses: %s" % [ name, instance.addresses ]
  end

  check "pulling the addresses of an instance" do 
    name      = stack.servers.first
    puts "instance: %s addresses: %s" % [ name, stack.addresses( name ) ]
  end

  # INSTANCES
  check "check we can pull a list of networks an instance is attached" do 
    hostname = stack.servers.last
    puts "instance: %s, attached networks: %s " % [ hostname, stack.server_networks( hostname ) ]
  end

  # IMAGES
  check "checking we can pull the image details" do
    images = stack.images
    index  = rand(0..(images.size - 1) )
    name   = images[index]
    puts "using random image: %s" % [ name ]
    image  = stack.image name 
    puts "image id: %s" % [ image.id ]
  end



  puts "\n[total] %f.3".green % [ Time.now - start_time ]

rescue Exception => e 
  puts "execption: " << e.message
end

