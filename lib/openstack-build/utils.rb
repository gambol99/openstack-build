#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#

# I perfer to access hashes this way
class Hash 
  def method_missing( m, *args, &block )
    self[m] = args.first if !args.empty?
    return self[m.to_s] if self.has_key? m.to_s 
    return self[m]      if self.has_key? m
    nil
  end
end

module OpenstackBuild
module Utils


end
end
