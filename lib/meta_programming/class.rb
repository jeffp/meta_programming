module MetaProgramming
  module Class
    def self.included(base)
      raise 'This module may only be included in class Class' unless base.name == 'Class'
    end

    def blank_slate(opts={})
      opts[:except] = opts[:except] ? (opts[:except].is_a?(Array) ? opts[:except] : [opts[:except]]) : []
      exceptions =  opts[:except].map(&:to_s)
      exceptions += ['method_missing', 'respond_to?'] unless opts[:all]
      matchers = exceptions.map{|ex| "^#{ex.gsub(/\?/, '\?')}$" }
      matchers << '^__'
      regexp = Regexp.new(matchers.join('|'))
      instance_methods.each do |m|
        undef_method m unless regexp.match(m.to_s)
      end
    end
  end
end