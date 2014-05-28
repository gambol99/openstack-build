#
#   Author: Rohith
#   Date: 2014-05-22 23:55:29 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
require 'uri'

module OpenstackBuild
module Contrib
class ForemanProxy

  include HTTParty

  def initialize options = {}
    @options        = validate_configuration options
    @authentication = {}
  end

  def add hostname, domain, ipaddress, type = 'A'
    result = self.post '/dns/'
      :basic_auth => @authentication,
      :body => 
          # fqdn=hostname.example.com&value=192.168.1.1&type=A
            {
              :fqdn     => '%s.%s' % [ hostname, domain ],
              :value    => ipaddress
              :type     => type
            }.to_json,
      :headers => { 'Content-Type' => 'application/json' } 
    )
  end

  def delete hostname, domain
    result = self.delete '/dns/%s.%s' % [ hostname, domain ],
      :basic_auth => @authentication,
      :headers => { 'Content-Type' => 'application/json' } 
    )
  end

  private
  def validate_configuration options = {}
    [ :api, :username, :password ].each do |x| 
      raise ArgumentError, 'you have not supplied the %s field' % [ x ] unless options.has_key x 
    end
    raise ArgumentError, 'the url: %s is invalid, please check' unless options[:api]      =~ URI::regexp
    raise ArgumentError, 'the username: %s looks invalid to me' unless options[:username] =~ /^[[:alnum:]]{3,}$/
    # step: update the config
    self.base_uri options[:api]
    @authentication[:username] = options[:username]
    @authentication[:password] = options[:password]
    options
  end

end
end
end
