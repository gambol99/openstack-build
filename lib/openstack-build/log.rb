#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#
require 'logger'
module OpenstackBuild
class Logger
  class << self
    attr_accessor :logger

    def init options = {} 
      self.logger = ::Logger.new( options[:std] || STDOUT)
    end

    def method_missing(m,*args,&block)
      logger.send m, *args, &block if logger.respond_to? m
    end
  end
end
end
