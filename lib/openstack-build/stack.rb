#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','./')
require 'fog'
require 'config'
require 'timeout'
require 'utils'
require 'cache'
require 'pp'

module OpenstackBuild
class Stack

  include OpenstackBuild::Utils 

  attr_reader :options, :stack, :config, :stack_config

  def initialize options = {}
    raise ArgumentError, 'you have not specified a configuration file in you options' unless options.config
    # step: load the configuration
    @config  = OpenstackBuild::Config::new options.config, options
    @options = options
    @cache   = OpenstackBuild::Cache::new 
    # step: check the configuration
    @stack_config = validate_config @config, options
    # step: get a connection
    @stack = connection @stack_config
  end

  # ========================================================================
  # Instance Operations
  # ========================================================================

  def launch hostname, options = {}, &block
    raise ArgumentError, 'you have not specified a hostname' unless hostname
    # step: check we have the minimum options
    [ :image, :flavor, :networks, :keypair, :security_group ].each do |x|
      raise ArgumentError, 'you have not specified the %s field' % [ x ] unless options.has_key? x 
    end
    # step: check everything exists
    raise ArgumentError, 'networks field should be a array'   % [ options.networks ]        unless options.networks.is_a? Array
    raise ArgumentError, 'the networks field is empty'        % [ options.networks ]        unless !options.networks.empty?
    raise ArgumentError, 'security group should be a array'   % [ options.security_group ]  unless options.security_group.is_a? Array
    raise ArgumentError, 'the security_group field is empty'  % [ options.security_group ]  unless !options.security_group.empty?
    raise ArgumentError, 'the image: %s does not exist'       % [ options.image ]           unless image? options.image
    raise ArgumentError, 'the flavor: %s does not exist'      % [ options.flavor ]          unless flavor? options.flavor
    if options.volume
      raise ArgumentError, 'the volume: %s does not exist'      % [ options.volume ]        unless volume? options.volume
    end
    # step: we need to check the networks and security groups
    options.networks.each do |net|
      raise ArgumentError, 'the network: %s does not exist' % [ net ] unless network? net
    end
    options.security_group.each do |sec|
      raise ArgumentError, 'the security_group: %s does not exist' % [ sec ] unless security_group? sec
    end
    # step: ok, lets build the instance
    compute_options = {
      :name         => hostname,
      :image_ref    => image( options.image ).id,
      :flavor_ref   => flavor( options.flavor ).id,
      :key_name     => options.keypair,
      :nics         => []
    }
    # step: lets add the networks
    options.networks.each do |net|
      compute_options[:nics] << { 'net_id' => network( net ).id }
    end
    # step: lets go ahead an create the instance
    @stack.compute.servers.create compute_options
    # step: if block given, wait for activation 
    if block_given?
      Timeout::timeout( 30 ) do 
        loop do 
          if active? hostname
            yield server( hostname )
            break
          end
          sleep 0.3
        end
      end
    end
  end

  def destroy hostname


  end

  # ========================================================================
  # Security Groups
  # ========================================================================

  def security_group name 
    raise ArgumentError, 'the security_group: %s does not exists'  unless security_group? name 
    @stack.compute.security_groups.select { |x| x if x.name == name }.first
  end

  def security_groups
    @stack.compute.security_groups.map { |x| x.name }
  end

  def security_group? name
    !@stack.compute.security_groups.select { |x| x if x.name == name }.empty?
  end

  # ========================================================================
  # Keypairs
  # ========================================================================

  def keypair name 
    raise ArgumentError, 'the keypair: %s does not exists'  unless keypair? name 
    @stack.compute.key_pairs.select { |x| x if x.name == name }.first
  end

  def keypairs
    @stack.compute.key_pairs.map { |x| x.name }
  end

  def keypair? name
    !@stack.compute.key_pairs.select { |x| x if x.name == name }.empty?
  end

  # ========================================================================
  # Networks
  # ========================================================================

  def network name 
    raise ArgumentError, 'the network: %s does not exists'  unless network? name 
    @stack.network.networks.select { |x| x if x.name == name }.first
  end

  def networks
    @stack.network.networks.map { |x| x.name }
  end

  def network? name
    !@stack.network.networks.select { |x| x if x.name == name }.empty?
  end

  # ========================================================================
  # Instances
  # ========================================================================

  def exists? name 
    servers.include? name
  end

  def server name 
    raise ArgumentError, 'the instance: %s does not exists'  unless exists? name 
    @stack.compute.servers.select { |x| x if x.name == name }.first
  end

  def servers 
    @stack.compute.servers.map { |x| x.name } 
  end

  def active? name
    raise ArgumentError, 'the instance: %s does not exists'  unless exists? name 
    ( server( name ).state =~ /ACTIVE/ ) ? true : false
  end

  def server_networks name 
    raise ArgumentError, 'the instance: %s does not exists'  unless exists? name 
    server( name ).addresses.keys
  end

  def addresses name, interval = 0.2, timeout = 15
    raise ArgumentError, 'the instance: %s does not exist, please check'  % [ name ] unless exists? name 
    list = []
    begin
      host = nil
      Timeout::timeout( timeout ) do  
        loop do
          host  = server( name ) if active? name 
          break if host
          sleep interval
        end
      end
      # step: we need to parse the structure
      host.addresses.each_pair do |name,addrs|
        addrs.each { |net| list << net['addr'] }
      end
    rescue Timeout::Error => e 
      raise Exception, 'we have timed out attempting to acquire the instance addresses'
    end
    list
  end

  # ========================================================================
  # Images
  # ========================================================================

  def image name 
    raise ArgumentError, 'the image: %s does not exists'  unless image? name 
    @stack.compute.images.select { |x| x if x.name == name }.first
  end

  def images
    @stack.compute.images.map { |x| x.name }
  end

  def image? name
    !@stack.compute.images.select { |x| x if x.name == name }.empty?
  end

  # ========================================================================
  # Flavors
  # ========================================================================

  def flavor name 
    raise ArgumentError, 'the flavor: %s does not exists'  unless flavor? name  
    @stack.compute.flavors.select { |x| x if x.name == name }.first
  end

  def flavors 
    @stack.compute.flavors.map { |x| x.name }
  end

  def flavor? name
    !@stack.compute.flavors.select { |x| x if x.name == name }.empty?
  end

  private

  def validate_config config, options 
    raise ArgumentError, 'you have multiple openstack cluster defined in configuration, you must select one'  if config.stacks.size > 0 and !options.stack
    raise ArgumentError, 'the stack: %s does not exist in configuration, please check' % [ options.stack ]    unless config.stacks.include? options.stack
    config.stack options.stack
  end

  def connection openstack 
    @stack = {} unless @stack
    @stack[:compute] = ::Fog::Compute.new( :provider => :OpenStack,
      :openstack_auth_url   => openstack.auth_url,
      :openstack_api_key    => openstack.api_key,
      :openstack_username   => openstack.username,
      :openstack_tenant     => openstack.tenant
    )
    @stack[:network] = ::Fog::Network.new( :provider => :OpenStack,
      :openstack_auth_url   => openstack.auth_url,
      :openstack_api_key    => openstack.api_key,
      :openstack_username   => openstack.username,
      :openstack_tenant     => openstack.tenant
    )
    @stack
  end

end
end
