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
          if (method_defined?(method_name_with_ext) || private_method_defined?(method_name_with_ext))
            raise(MetaProgramming::AliasMethodChainError, "#{method_name_without_ext} already exists.  Circular references not permitted.") if (method_defined?(method_name_without_ext) || private_method_defined?(method_name_without_ext))
            raise(MetaProgramming::AliasMethodChainError, "#{method_name_with_ext} already chained. Rechaining not permitted") if eigenclass.instance_variable_defined?("@#{instance_variable}")
            if (method_defined?(method_name.to_sym) || private_method_defined?(method_name.to_sym))
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
        raise 'Must have a block defining the method body' unless block_given?
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
        uniq_ext = "#{self.name.gsub(/.+::/,'')}_#{matcher.class.name.gsub(/.+::/,'')}#{matcher.hash.abs.to_s}"
        _ghost_method_handler = "_ghost_method_handler_#{uniq_ext}".to_sym
        _ghost_method_matcher = "_ghost_method_matcher_#{uniq_ext}".to_sym
        define_method(_ghost_method_handler, block)
        private _ghost_method_handler
        if matcher.is_a?(Proc)
          define_method(_ghost_method_matcher, matcher)
          private _ghost_method_matcher
        end
        define_chained_method(:method_missing, uniq_ext.to_sym) do |symbol, *args|
          handled = case matcher
          when Regexp then !(symbol.to_s =~ matcher).nil?
          when String, Symbol then (symbol == matcher.to_sym)
          when Proc
            begin
              __send__(_ghost_method_matcher, symbol)
            rescue Exception => matcher_error
              raise matcher_error, "#{matcher_error.message} in a ghost method matcher called for symbol :#{symbol}. Be sure to use self.class.method_defined? instead of respond_to? in a lambda matcher."
            end
          else nil
          end
          if handled
            begin
              __send__(_ghost_method_handler, (handled == true ? symbol : handled), *args)
            rescue Exception => handler_error
              raise handler_error, "#{handler_error.message} in a ghost method block called with symbol :#{symbol}."
            end
          else
            __send__("method_missing_without_#{uniq_ext}".to_sym, symbol, *args)
          end
        end
        #cripple respond_to? in deference of 1.8 -- the include_private no longer works
        define_chained_method(:respond_to?, uniq_ext.to_sym) do |method_name| #1.9 only, include_private=nil|
          responds = case matcher
          when Regexp then !(method_name.to_s =~ matcher).nil?
          when String, Symbol then method_name == matcher.to_sym
          when Proc
            begin
              __send__(_ghost_method_matcher, method_name)
            rescue Exception => matcher_error
              raise matcher_error, "#{matcher_error.message} in a ghost method matcher called in respond_to? for symbol :#{method_name}. Be sure to use self.class.method_defined? instead of respond_to? in a lambda matcher."
            end
          end
          responds || __send__("respond_to_without_#{uniq_ext}?".to_sym, method_name) #1.9 only, include_private)
        end
      end
    end
  end
end
