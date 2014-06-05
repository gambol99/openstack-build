Openstack Build
---------------------
Is a small gem library which wraps fog and is used to ease the working with openstack - effectively they are shorthand or helper methods 

---------

Example Use:
---------

      options = {
        :username   => 'admin',
        :tenant     => 'admin',
        :api_key    => 'something',
        :auth_url   => 'http://horizon.domain.com:5000/v2.0/tokens'
      }
      stack = OpenstackBuild.new( options )
      puts "networks: " << stack.networks.join(', ')
      puts "instances: " << stack.servers.join(', ')  
      puts "images: " << stack.images.join(', ')
      instance = stack.servers.first
      puts  "instance: %s exists: %s"       % [ instance, stack.exists?( instance ) ]
      puts  "instance: noname, exists: %s"  % [ stack.exists?( 'noname') ]
  
  
