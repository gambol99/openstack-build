#
#   Author: Rohith
#   Date: 2014-05-22 12:16:53 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#
require 'yaml'

module OpenstackBuild
class Config

  attr_reader :config

  def initialize filename, options 
    # step: check we have all the options
    @config   = validate_configuration filename, options
    @options  = options
    @filename = filename
  end

  def changed?
    ( @modified < File.mtime( @filename ) ) ? true : false 
  end

  def reload
    @config = validate_configuration @filename, @options
  end

  def stacks 
    @config.openstack.each.map { |x| x['name'] }
  end

  def stack name
    raise ArgumentError, 'the stack: %s does not exists' % [ name ] unless stack? name 
    @config.openstack.each.select { |x| x if x['name'] == name }.first
  end

  def stack? name 
    stacks.include? name 
  end

  def method_missing( m, *args, &block )
    @config[m] = args.first if !args.empty?
    return @config[m]       if @config.has_key?( m )  
    return @config[m.to_s]  if @config.has_key?( m.to_s )  
    nil
  end
  
  private
  def validate_configuration filename = @filename, options = @options
    # step: get the modified time
    @modified = File.mtime filename 
    # step: read in the configution file
    config    = YAML.load_file( filename )
    # step: check we have erveything we need
    raise ArgumentError, 'the configuration does not contain the openstack config' unless config.openstack
    raise ArgumentError, 'the openstack field should be an array'                  unless config.openstack.is_a? Array
    # step: we have to make sure we have 0.{username,api_key,auth_uri}
    config.openstack.each do |os|
      raise ArgumentError, 'the credentials for a openstack cluster must have a name field' unless os.has_key? 'name'
      %w(username tenant api_key auth_url).each do |x|
        unless os.has_key? x 
          raise ArgumentError, 'the credentials are incomplete, you must have the %s field for %s' % [ x, os['name'] ]
        end
      end
    end
    # step: lets validate templates or inject the default one
    if !config.has_key? 'templates' or config['templates'].nil? and !options.template
      # we have no templates in config and the user has not specified any
      raise ArgumentError, 'there is no templates in configuration and you have not specified a custom template'
    end
    config
  end

end
end
