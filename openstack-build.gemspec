#!/usr/bin/ruby
#
#   Author: Rohith
#   Date: 2014-05-22 16:48:00 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','lib/openstack-build' )
require 'version'

Gem::Specification.new do |s|
    s.name        = "openstack-build"
    s.version     = OpenstackBuild::VERSION
    s.platform    = Gem::Platform::RUBY
    s.date        = '2014-05-22'
    s.authors     = ["Rohith Jayawardene"]
    s.email       = 'gambol99@gmail.com'
    s.homepage    = 'http://rubygems.org/gems/openstack-build'
    s.summary     = %q{Helper methods and library for working with openstack via fog}
    s.description = %q{Helper methods and library for working with openstack via fog}
    s.license     = 'MIT'
    s.files         = `git ls-files`.split("\n")
    s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
    s.add_dependency 'fog'
end
