module MetaProgramming
  module Class
    def self.included(base)
      raise 'This module may only be included in class Class' unless base.name == 'Class'
    end

    #opts :matcher=>/xx/, :except=>[:method_name, //, ''], :only=>[:method_name, //, '']
#    def cast_proxy(target_klass, opts={}, &block)
#      matcher = lambda{|sym| target_klass.method_defined?(sym) && sym}
#      define_ghost_method(matcher) {|sym, *args| block.call }
#    end

    def dynamic_proxy(target, opts={}, &block)

    end

    def blank_slate(opts={})
      opts[:except] = opts[:except] ? (opts[:except].is_a?(Array) ? opts[:except] : [opts[:except]]) : []
      exceptions =  opts[:except].map(&:to_s)
      matchers = exceptions.map{|ex| "^#{ex.gsub(/\?/, '\?')}$" }
      matchers += ['^method_missing', '^respond_to'] unless opts[:all]
      matchers << '^__'
      matchers << '^object_id$'
      regexp = Regexp.new(matchers.join('|'))
      instance_methods.each do |m|
        undef_method m unless regexp.match(m.to_s)
      end
    end
  end
end