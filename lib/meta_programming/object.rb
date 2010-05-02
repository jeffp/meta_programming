module MetaProgramming
  module Object
    def self.included(base)
      raise 'This module may only be included in class Object' unless base.name == 'Object'
      base.extend(ClassMethods)
      base.class_eval do
        alias_method :metaclass, :eigenclass
      end
    end

    def eigenclass
      class << self; self; end
    end
    
    module ClassMethods

      module Helpers
        def self.compose_chaining_symbols(method_name, ext)
          stripped_method_name, punctuation = method_name.to_s.sub(/([?!=])$/, ''), $1
          ["#{stripped_method_name}_with_#{ext}#{punctuation}".to_sym,
            "#{stripped_method_name}_without_#{ext}#{punctuation}".to_sym]
        end

        def self.escape_method_name(method_name)
          method_name.to_s.gsub(/\?/, 'qmark').gsub(/\!/, 'bang').gsub(/\=/, 'equal')
        end
      end

      def method_access_level(method_name)
        case
        when public_method_defined?(method_name.to_sym) then :public
        when private_method_defined?(method_name.to_sym) then :private
        when protected_method_defined?(method_name.to_sym) then :protected
        else nil
        end
      end
      
      def safe_alias_method_chain(method_name, ext)
        class_eval do
          method_name_with_ext, method_name_without_ext = Helpers.compose_chaining_symbols(method_name, ext)
          instance_variable = Helpers.escape_method_name(method_name_with_ext)
          if method_access_level(method_name_with_ext)
            raise "#{method_name_with_ext} already chained. Rechaining not permitted" if eigenclass.instance_variable_defined?("@#{instance_variable}")
            if method_access_level(method_name.to_sym)
              #alias_method_chain(method_name.to_sym, ext.to_sym)
              alias_method method_name_without_ext, method_name.to_sym
              alias_method method_name.to_sym, method_name_with_ext
              case method_access_level(method_name_without_ext)
              when :public then public(method_name.to_sym)
              when :protected then protected(method_name.to_sym)
              when :private then private(method_name.to_sym)
              end
            else
              define_method(method_name_without_ext) {|*args| }
              alias_method method_name.to_sym, method_name_with_ext
            end
            eigenclass.instance_variable_set("@#{instance_variable}", true)
          end
        end
      end

      def define_chained_method(method_name, ext, &block)
        raise 'Must have block' unless block_given?
        with, without = Helpers.compose_chaining_symbols(method_name, ext)
        define_method(with, block)
        safe_alias_method_chain(method_name.to_sym, ext.to_sym)
      end

      def define_method_missing_chain(name, &block)
        raise 'Must have block' unless block_given?
        define_chained_method(:method_missing, name.to_sym, &block)
      end

      def define_ghost_method(matcher, &block)
        raise "Must have a block" unless block_given?
        raise ArgumentError, "Matcher argument must be either a 'string', :symbol, /regexp/ or proc" unless (matcher.nil? || [String, Symbol, Regexp, Proc].any?{|c| matcher.is_a?(c)})
        ext = matcher.hash.abs.to_s
        define_chained_method(:method_missing, ext.to_sym) do |symbol, *args|
          begin
            handled = case matcher
            when Regexp then (symbol.to_s =~ matcher)
            when String, Symbol then (symbol == matcher.to_sym)
            when Proc then matcher.call(self, symbol)
            else nil
            end
            handled ? yield(self, handled == true ? symbol : handled, *args) :
              __send__("method_missing_without_#{ext}".to_sym, symbol, *args)
          rescue LocalJumpError
            raise LocalJumpError, "Remove the 'return' keyword in your method block."
          end
        end
        #cripple respond_to? in deference of 1.8 -- the include_private no longer works
        define_chained_method(:respond_to?, ext.to_sym) do |method_name| #1.9 only, include_private=nil|
          responds = case matcher
          when Regexp then method_name.to_s =~ matcher
          when String, Symbol then method_name == matcher.to_sym
          when Proc then matcher.call(self, method_name)
          end
          responds || __send__("respond_to_without_#{ext}?", method_name) #1.9 only, include_private)
        end
      end
    end
  end
end
