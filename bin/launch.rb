#!/usr/bin/env ruby
#
#   Author: Rohith
#   Date: 2014-05-22 23:55:29 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','../lib')
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'openstack-build'
require 'optparse'
require 'colorize'
require 'erb'

STDOUT.sync = true

def usage message = nil
  puts Parser
  puts "\nerror: %s".red % [ message ] if message
  exit 0
end

def verbose message
  puts '[verb][%s] : '.green % [  Time.now.strftime( '%H:%M:%S' ) ] << '%s' % [ message ] if @options[:verbose]
end

@options = {
  :domain           => 'hq.noths.com',
  :config           => './config.yaml',
  :flavor           => '2cores-4096mem-10gb',
  :image            => 'centos-base-6.5-min-07-05-2014',
  :keypair          => 'default',
  :networks         => [],
  :security_group   => [ 'default' ],
  :verbose          => false
}

Parser = OptionParser::new do |o|
  o.banner = "Usage: #{__FILE__} -H HOSTNAME -f FLAVOR -i IMAGE -n NETWORK -u USER_DATA\n"
  o.on( '-S stack',       '--stack NAME',             'the name of the openstack you wish to connect' ) { |x|   @options[:stack]             =  x    }
  o.on( '-c CONFIG',      '--config CONFIG',          'the configuration file to read credentials' )    { |x|   @options[:config]            =  x    }
  o.on( '-H HOSTNAME',    '--hostname HOSTNAME',      'the hostname of instance you are creating' )     { |x|   @options[:hostname]          =  x    }
  o.on( '-d DOMAIN',      '--domain DOMAIN',          'the domain of the instance' )                    { |x|   @options[:domain]            =  x    }
  o.on( '-i IMAGE',       '--image IMAGE',            'the image you wish to boot from' )               { |x|   @options[:image]             =  x    }
  o.on( '-f FLAVOR',      '--flavor FLAVOR',          'the flavor the instance should work from' )      { |x|   @options[:flavor]            =  x    }
  o.on( '-k KEYPAIR',     '--keypair KEYPAIR',        'the keypair the instance should use' )           { |x|   @options[:keypair]           =  x    }
  o.on( '-n NETWORK',     '--network NETWORK',        'the network the instance should be connected' )  { |x|   @options[:networks]          << x    }
  o.on( '-s SECURITY',    '--secgroups SECURITY',     'the security group assigned to the instance' )   { |x|   @options[:security_group]    << x    } 
  o.on( '-u USER_DATA',   '--user-data USER_DATA',    'the user data template' )                        { |x|   @options[:user_data]         =  x    }
  o.on( nil,              '--hypervisor HOST',        'the compute node you want the instance to run' ) { |x|   @options[:availability_zone] =  x    }
  o.on( '-v',             '--verbose',                'switch on verbose mode' )                        {       @options[:verbose]           =  true }
end
Parser.parse!

def validate_options options, stack
  # step: check we have everything we need to proceed
  [ :hostname, :domain, :image, :flavor, :keypair, :user_data ].each do |x| 
    raise ArgumentError, 'you have not specified %s, please check usage' % [ x ]           unless options.has_key? x 
  end
  raise ArgumentError, 'you have not specified any networks to attach the instance to'     if options[:networks].empty?
  raise ArgumentError, 'you have not specified any secgroups to attach the instance to'    if options[:security_group].empty?
  raise ArgumentError, 'the template file: %s does not exist'   % [ options[:user_data] ]  unless File.exists? options[:user_data]
  raise ArgumentError, 'the template file: %s is not a file'    % [ options[:user_data] ]  unless File.file? options[:user_data]
  raise ArgumentError, 'the template file: %s is not readable'  % [ options[:user_data] ]  unless File.readable? options[:user_data]
  
  # step: lets help the user out a bit and check everything actually exists
  verbose "checking the image: #{options[:image]} exists"
  unless stack.image? options[:image]
    raise ArgumentError, 'the image: %s does not exist; images: %s'     % [ options[:image], stack.images.join(', ') ]
  end
  verbose "checking the flavor: #{options[:flavor]} exists"
  unless stack.flavor? options[:flavor]
    raise ArgumentError, 'the flavor: %s does not exist, flavors: %s'   % [ options[:flavor], stack.flavors.join(', ') ]
  end
  verbose "checking the keypair: #{options[:keypair]} exists"
  unless stack.keypair? options[:keypair]
    raise ArgumentError, 'the keypair: %s does not exist, keypairs: %s' % [ options[:keypair], stack.keypairs.join(', ') ]
  end
  if options[:availability_zone]
    unless stack.compute? options[:availability_zone]
      raise ArgumentError, 'the availability_zone: %s does not exist, zones: %s ' % [ options[:availability_zone], stack.computes.join(', ') ] 
    end
  end
  options[:security_group].each do |sec|
    verbose "checking the security_group: #{sec} exists"
    unless stack.security_group? sec
      raise ArgumentError, 'the security group: %s does not exist, groups: %s'    % [ sec, stack.security_groups.join(',') ]
    end
  end
  options[:networks].each do |net|
    verbose "checking the network: #{net} exists"
    unless stack.network? net
      raise ArgumentError, 'the network: %s does not exist, groups: %s' % [ net, stack.networks.join(',') ]
    end
  end
end

begin  
  
  # step: check we have an action and config
  raise ArgumentError, 'you have not specified a configuration for openstack-build'   unless @options[:config]
  
  # step: lets create the stack connector
  stack = OpenstackBuild::load( { :config => @options[:config], :stack  => @options[:stack] } )
  
  # step: validate the options
  validate_options @options, stack 
  
  # step: make sure the instance does not already exist
  @options[:name] = "%s.%s" % [ @options[:hostname], @options[:domain] ]
  verbose "checking the host: #{@options[:name]} does not exist"
  raise ArgumentError, 'the instance: %s already exist, please use another name' % [ @options[:name] ] if stack.exists? @options[:name]
  
  # step: lets build the user_data
  verbose "generating the user data for this host"
  @options[:user_data] = ERB.new( IO.read( @options[:user_data] ), nil, '-' ).result( binding )
  
  # step: lets built the instance
  verbose "bootrapping the instance: #{@options[:hostname]}"
  stack.launch @options[:name], @options do |instance|
    verbose "instance: %s build, waiting for addresses"   % [ instance.name ]
    verbose "instance: %s, ip addresses: %s"              % [ instance.name, stack.addresses( instance.name ).join(', ') ]
  end

rescue SystemExit => e 
  exit e.status
rescue Exception  => e 
  usage e.message
end
