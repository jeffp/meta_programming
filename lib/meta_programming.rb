require 'meta_programming/object'
require 'meta_programming/class'

module MetaProgramming
  class AliasMethodChainError < Exception; end
end

Object.send :include, MetaProgramming::Object
Class.send :include, MetaProgramming::Class
