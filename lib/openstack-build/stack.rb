#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','./')
require 'fog'
require 'timeout'
require 'utils'

module OpenstackBuild
class Stack

  include OpenstackBuild::Utils 

  attr_reader :options, :stack, :config, :stack_config

  def initialize options = {}
    @options = validate_options options
    # step: get a connection
    @stack = connection @options
  end

  # ========================================================================
  # Instance Operations
  # ========================================================================

  def launch hostname, o = {}, &block
    raise ArgumentError, 'you have not specified a hostname' unless hostname
    # step: check we have the minimum o
    [ :image, :flavor, :networks, :keypair, :security_group ].each do |x|
      raise ArgumentError, 'you have not specified the %s field' % [ x ] unless o.has_key? x 
    end
    # step: check everything exists
    raise ArgumentError, 'networks field should be a array'   % [ o.networks ]        unless o.networks.is_a? Array
    raise ArgumentError, 'the networks field is empty'        % [ o.networks ]        unless !o.networks.empty?
    raise ArgumentError, 'security group should be a array'   % [ o.security_group ]  unless o.security_group.is_a? Array
    raise ArgumentError, 'the security_group field is empty'  % [ o.security_group ]  unless !o.security_group.empty?
    raise ArgumentError, 'the image: %s does not exist'       % [ o.image ]           unless image? o.image
    raise ArgumentError, 'the flavor: %s does not exist'      % [ o.flavor ]          unless flavor? o.flavor
    if o.volume
      raise ArgumentError, 'the volume: %s does not exist'    % [ o.volume ]          unless volume? o.volume
    end
    # step: we need to check the networks and security groups
    o.networks.each do |net|
      raise ArgumentError, 'the network: %s does not exist' % [ net ] unless network? net
    end
    o.security_group.each do |sec|
      raise ArgumentError, 'the security_group: %s does not exist' % [ sec ] unless security_group? sec
    end
    # step: ok, lets build the instance
    compute_options = {
      :name         => hostname,
      :image_ref    => image( o.image ).id,
      :flavor_ref   => flavor( o.flavor ).id,
      :key_name     => o.keypair,
      :nics         => []
    }
    # step: set the availability_zone if defined
    compute_options[:availability_zone] = "nova:%s" % [ o[:availability_zone] ] if o[:availability_zone]
    # step: the user data
    compute_options[:user_data] = o[:user_data] if o[:user_data]
    # step: lets add the networks
    o.networks.each do |net|
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
    # step: check the instance exists?
    raise ArgumentError, "the instance: #{hostname} does not exist, please check" unless exists? hostname
    @stack.compute.delete_server( server( hostname ).id )
  end

  # ========================================================================
  # Compute Resources
  # ========================================================================
  def compute hostname 
    raise ArgumentError, 'the compute host: %s does not exist' % [ hostname ] unless compute? hostname
    @stack.compute.get_host_details( hostname ).body
  end

  def computes 
    @stack.compute.list_hosts.body['hosts'].inject([]) do |a,host|
      a << host['host_name'] if host['service'] == 'compute'
      a 
    end
  end

  def compute? hostname 
    computes.include? hostname
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
    raise ArgumentError, "the image: #{name} does not exists" unless image? name 
    @stack.compute.images.select { |x| x if x.name == name }.first
  end

  def images
    @stack.compute.images.map { |x| x.name }
  end

  def image? name
    !@stack.compute.images.select { |x| x if x.name == name }.empty?
  end

  def delete_image name 
    source_image = image name 
    @stack.compute.delete_image source_image.id 
  end

  # ========================================================================
  # Snapshots
  # ========================================================================

  def snapshot hostname, snapshot, force = false, &block
    instance = server hostname
    if !force and image? snapshot
      raise ArgumentError, "the snapshot / image name: #{snapshot} already exists"
    end
    delete_image snapshot if image? snapshot
    @stack.compute.create_image instance.id, snapshot unless block_given?
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

  # ========================================================================
  # Load Balancer Pools
  # ========================================================================

  def pool name 
    raise ArgumentError, "the pool: #{name} does not exists" unless pool? name 
    @stack.network.list_lb_pools.body['pools'].select { |x| x if x['name'] == name }.first
  end

  def pools 
    @stack.network.list_lb_pools.body['pools'].map { |x| x['name'] }
  end

  def pool_active? name 
    pool( name )['admin_state_up']
  end

  def pool_status? name 
    pool( name )['status']
  end

  def pool_members name 
    pool( name )['members']
  end

  def pool? name 
    !@stack.network.list_lb_pools.body['pools'].select { |x| x if x['name'] == name }.empty?
  end

  # ========================================================================
  # Load Balancer Members
  # ========================================================================

  def add_member pool_name, member 
    # step: validate the options
    pool = pool pool_name
    [ :hostname, :port, :weight, :state ].each do |x|
      raise ArgumentError, "you have not specified a value for #{x}" unless member.has_key? x
    end
    raise ArgumentError, "the member state: #{member.state} is invalid" unless member_states.include? member.state
    member.port   = validate_integer member.port, 1, 65535
    member.weight = validate_integer member.weight, 1, 100
    # step: check if the host is already a member
    if member_of? pool_name, member.hostname, member.port
      raise ArgumentError, "the hostname: #{member.hostname}, port: #{member.port} is already a member of #{pool_name}"
    end
    # step: ok, lets add it to the pool
    instance = server member.hostname
    @stack.create_lb_member pool.id, addresses( instance.name ).first, member.port, { :admin_state_up => member.state }
  end

  # method: pull the member details
  def member id 
    @state.get_lb_member( id ).body['member']
  end

  # method: check to see if the host instance is a member of the pool
  def member_of? pool_name, hostname, port
    raise ArgumentError, "the hostname: #{hostname} does not exists" unless exists? hostname
    instance_addresss = addresses hostname
    pool_members.each do |x|
      pool_member = member x
      if instance_addresss.include? pool_member['address'] and pool_member['protocol_port'] == port
        raise ArgumentError, "the hostname: #{hostname} is already a member of pool: #{pool_member}"
      end
    end
  end

  def member_states
    %w(up down)
  end

  private
  def validate_options options = {}
    [ :username, :tenant, :api_key, :auth_url ].each do |x|
      raise ArgumentError, 'the credentials are incomplete, you must have the %s field' % [ x ] unless options.has_key? x 
    end
    options
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
