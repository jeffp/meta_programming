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
      def safe_alias_method_chain(method_name, ext)
        class_eval do
          stripped_method_name, punctuation = method_name.to_s.sub(/([?!=])$/, ''), $1
          method_name_with_ext = "#{stripped_method_name}_with_#{ext}#{punctuation}".to_sym
          method_name_without_ext = "#{stripped_method_name}_without_#{ext}#{punctuation}".to_sym
          instance_variable = "#{stripped_method_name}_#{ext}_#{{'?'=>'questmark', '!'=>'bang', '='=>'equals'}[punctuation]}"
          if ((public_method_defined?(method_name_with_ext) ||
                  private_method_defined?(method_name_with_ext) ||
                  protected_method_defined?(method_name_with_ext)) &&
                  !(eigenclass.instance_variable_defined?("@#{instance_variable}")))
            if (public_method_defined?(method_name.to_sym) ||
                  private_method_defined?(method_name.to_sym) ||
                  protected_method_defined?(method_name.to_sym))
              #alias_method_chain(method_name.to_sym, ext.to_sym)
              alias_method method_name_without_ext, method_name.to_sym
              alias_method method_name.to_sym, method_name_with_ext
              case
              when public_method_defined?(method_name_without_ext) then public(method_name.to_sym)
              when protected_method_defined?(method_name_without_ext) then protected(method_name.to_sym)
              when private_method_defined?(method_name_without_ext) then private(method_name.to_sym)
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
        define_method("#{method_name}_with_#{ext}".to_sym, block)
        safe_alias_method_chain(method_name.to_sym, ext.to_sym)
      end

      def define_ghost_method(matcher, &block)
        raise ArgumentError, "Matcher argument must be either a 'string', :symbol or /regexp/" unless (matcher.nil? || [String, Symbol, Regexp].any?{|c| matcher.is_a?(c)})
        raise BlockMissingError, "Must have a block" unless block_given?
        ext = matcher.hash.abs.to_s
        define_chained_method(:method_missing, ext.to_sym) do |symbol, *args|          
          begin
            case
            when ((matcher.is_a?(String) || matcher.is_a?(Symbol)) && (symbol == matcher.to_sym))
              yield(symbol, *args)
            when (matcher.is_a?(Regexp) && (symbol.to_s =~ matcher))
              yield(symbol, *args)
            else
              __send__("method_missing_without_#{ext}".to_sym, symbol, *args)
            end
          rescue LocalJumpError
            raise LocalJumpError, "Do not use the 'return' keyword in your method block"
          end
        end
      end
    end
  end
end
