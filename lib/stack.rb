#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#
require 'fog'
require 'openstruct'
require 'yaml'

module OpenstackBuild
class Stack

  attr_reader :options

  def initialize options = {}
    

    raise ArgumentError, 'you have not specified a configuration file to read'  unless options.ha

  end

  def create hostname, options 


  end

  def destroy hostname


  end

  def halt hostname


  end

  def volume? name

  end

  def network? name

  end

  def exists? name

  end

  def image? name



  end

  def flavor? name

  end

  def active? name

  end

  private


end
end

Parser = OptionParser::new do |o|
  o.on( '-H HOSTNAME',    '--hostname HOSTNAME', )
  o.on( '-i IMAGE',       '--image IMAGE', )
  o.on( '-r REALM',       '--realm REALM', )
  o.on( '-f FLAVOR',      '--flavor FLAVOR', 
  o.on( '-n NETWORK',     '--network NETWORK',
  o.on( nil,              '--create',
  o.on( nil,              '--destroy',
  o.on( nil,              '--snapshot',
  o.on( nil,              '--halt',
      

  o.on( nil,              '--float [FLOAT]', )  


end
