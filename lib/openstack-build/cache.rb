#
#   Author: Rohith
#   Date: 2014-05-22 12:16:53 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#
require 'thread'

module OpenstackBuild
class Cache

  def initialize
    @cache = {}
  end

  def flush 
    @cache = {}
  end

  def cached? key 
    @cache.has_key? key
  end

  def get key, default = nil
    return default unless @cache.has_key? key 
    item      = @cache[key]
    hold_time = Time.now - item[:created] * 1000
    if hold_time > item[:ttl]
      @cache.delete key
      return default
    end
    @cache[key][:value]
  end

  def set key, value, ttl_ms = 10
    item = {
      :created => Time.now,
      :ttl     => ttl_ms,
      :value   => value
    }
    @cache[key] = item
  end

end
end