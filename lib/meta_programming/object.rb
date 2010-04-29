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
          if (method_defined?(method_name_with_ext) && !(eigenclass.instance_variable_defined?("@#{instance_variable}")))
            if method_defined?(method_name.to_sym)
              #alias_method_chain(method_name.to_sym, ext.to_sym)
              alias_method method_name_without_ext, method_name.to_sym
              alias_method method_name.to_sym, method_name_with_ext
              case
              when public_method_defined?(method_name_without_ext) then public(method_name.to_sym)
              when protected_method_defined?(method_name_without_ext) then protected(without_method.to_sym)
              when private_method_defined?(method_name_without_ext) then private(without_method.to_sym)
              end
            else
              alias_method method_name.to_sym, method_name_with_ext
              define_method(method_name_without_ext) {|*args| }
            end
            eigenclass.instance_variable_set("@#{instance_variable}", true)
          end
        end
      end

      def define_chained_method(method_name, ext, &block)
        define_method("#{method_name}_with_#{ext}".to_sym, block)
        safe_alias_method_chain(method_name.to_sym, ext)
      end

    end
  end
end
