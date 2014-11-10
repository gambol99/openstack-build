#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#

# I perfer to access hashes this way
class Hash 
  def method_missing( m, *args, &block )
    self[m] = args.first unless args.empty?
    return self[m.to_s] if self.has_key? m.to_s 
    return self[m]      if self.has_key? m
    nil
  end
end

require 'ipaddr'

module OpenstackBuild
module Utils

  def validate_file(filename, writable = false)
    raise ArgumentError, 'you have not specified a file to check' unless filename
    raise ArgumentError, 'the file %s does not exist' % [filename] unless File.exists? filename
    raise ArgumentError, 'the file %s is not a file' % [filename] unless File.file? filename
    raise ArgumentError, 'the file %s is not readable' % [filename] unless File.readable? filename
    if writable
      raise ArgumentError, "the filename #{filename} is not writable" unless File.writable? filename
    end
    filename
  end

  def validate_integer(value, min, max, name = 'value')
    int_value = value if value.is_a? Integer
    if value.is_a? String
      raise ArgumentError, "#{name} must be numeric" unless value =~ /^[[:digit:]]+$/
      int_value = value.to_i
    else
      raise ArgumentError, "the #{name} must be a integer or a string"
    end
    raise ArgumentError, "the #{name} cannot be less than #{min}" if int_value < min
    raise ArgumentError, "the #{name} cannot be greater than #{min}" if int_value > max
    int_value
  end

  def ipaddress?(address)
    begin
      ipaddr = IPAddr.new(address)
      true
    rescue IPAddr::InvalidAddressError => e
      false
    end
  end


end
end
