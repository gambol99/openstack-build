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

STDOUT.sync = true

def usage message = nil
  puts Parser
  if message 
    puts "\nerror: %s".red % [ message ]
    exit 1
  end
  exit 0
end

def verbose message
  puts '[verb][%s] : %s' % [ Time.now.strftime( '%H:%M:%S' ), message ] if @options[:verbose]
end

@options = {}
Parser   = OptionParser::new do |o|
  o.banner = "Usage: #{__FILE__} --add|--delete [OPTIONS]"
  o.seperator ""
  o.on( nil,              '--add',                    'update / add an entry into foreman dns' )        { |x|   @options[:action]      = :update  }
  o.on( nil,              '--delete',                 'delete a dns entry from foreman dns' )           { |x|   @options[:action]      = :delete  }
  o.on( '-S stack',       '--stack NAME',             'the name of the openstack you wish to connect' ) { |x|   @options[:stack]       =  x       }
  o.on( '-c CONFIG',      '--config CONFIG',          'the configuration file to read credentials' )    { |x|   @options[:config]      =  x       }
  o.on( '-H HOSTNAME',    '--hostname HOSTNAME',      'the hostname of instance you are creating' )     { |x|   @options[:hostname]    =  x       }
  o.on( '-d DOMAIN',      '--domain DOMAIN',          'the domain of the instance' )                    { |x|   @options[:domain]      =  x       }
  o.on( '-i IPADDRESS',   '--ipaddress',              'this can be the ip or instance' )                { |x|   @options[:ipaddress]   =  x       }
  o.on( '-v',             '--verbose',                'switch on verbose mode' )                        {       @options[:verbose]     =  true    }
end
Parser.parse!

def validate_options options = {}
  # step: check we have the options for the specific command
  if options[:action] == :update
    [ :hostname, :domain, :ipaddress ].each do |x|
      raise ArgumentError, 'you have not specified the %s options' % [ x ] unless options.has_key? x 
    end
    unless options[:ipaddress] == /.*/
      raise ArgumentError, 'the ipaddress options is invalid, please check usage'
    end
  else
    [ :hostname, :domain ].each do |x|
      raise ArgumentError, 'you have not specified the %s options' % [ x ] unless options.has_key? x 
    end
  end
end

def update_dns opt = @options
  verbose "update_dns: hostname: %s domain: %s ip: %s" % [ opt[:hostname], opt[:domain], opt[:ipaddress] ]
  if opt[:ipaddress] == /instance/
    # step: we have to get the ip addresses from openstack
    fqdn      = '%s.%s' % [ opt[:hostname], opt[:domain] ]
    stack     = OpenstackBuild::load( { :config => opt[:config], :stack  => opt[:stack] } )
    addresses = stack.addresses fqdn
    raise ArgumentError, 'unable to get any ip addresses from openstack' if addresses.empty?

    HTTParty.post 
    :body => { :subject => 'This is the screen name', 
               :issue_type => 'Application Problem', 
               :status => 'Open', 
               :priority => 'Normal', 
               :description => 'This is the description for the problem'
             }.to_json,
    :headers => { 'Content-Type' => 'application/json' } )

  end

end

def delete_dns options = @options 

end

begin  
  # step: check we have an action and config
  raise ArgumentError, 'you have not specified a configuration for openstack-build'   unless @options[:config]
  # step: lets create the stack connector
  @stack   = OpenstackBuild::load( { :config => opt[:config], :stack  => opt[:stack] } )
  @foreman =
  
  # step: validate the options
  validate_options @options
  # step: perform the command
  case @options[:action]
  when :update
    update_dns 
  when :delete
    delete_dns
  end
rescue SystemExit => e 
  exit e.status
rescue Exception  => e 
  usage e.message
end
