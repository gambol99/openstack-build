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

module OpenstackBuild
class Stack

  attr_reader :options, :stack, :config

  def initialize options = {}
    raise ArgumentError, 'you have not specified a configuration file in you options' unless options.config
    # step: load the configuration
    @config  = OpenstackBuild::Config::new options.config, options
    @options = options
    # step: check the configuration
    validate_config @config, options
    # step: 
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
      :image_ref    => image( options.image ).id,
      :flavor_ref   => flavor( options.flavor ).id,
      :key_name     => keypair( options.keypair ).id,
      :nics         => []
    }
    # step: lets add the networks
    options.networks.each do |net|
      compute_options[:nics] << { 'net_id' => network( net ).id }
    end
    # step: lets go ahead an create the instance
    @stack.compute.create_server hostname, compute_options
    # step: if block given, wait for activation 
    if block_given?
      Timeout::timeout( 30 ) do 
        loop do 
          if active? hostname
            yield instance( hostname )
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
    instances.include? name
  end

  def instance name 
    raise ArgumentError, 'the instance: %s does not exists'  unless exists? name 
    @stack.compute.servers.select { |x| x if x.name == name }.first
  end

  def instances 
    @stack.compute.servers.map { |x| x.name } 
  end

  def active?
    raise ArgumentError, 'the instance: %s does not exists'  unless exists? name 
    ( instance( name ).status =~ /ACTIVE/ ) ? true : false
  end

  def addresses name, interval = 0.5, timeout = 30
    raise ArgumentError, 'the instance: %s does not exist, please check'  % [ name ] unless exists? name 
    begin
      Timeout::timeout( timeout ) do  
        loop do
          if active? name
            host      = instance.addresses  
          end
          sleep interval
        end
      end
    rescue Timeout::Error => e 
      raise Exception, 'we have timed out attempting to acquire the instance addresses'
    end
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
  end

end
end
