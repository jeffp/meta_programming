module MetaProgramming
  module Class
    def self.included(base)
      raise 'This module may only be included in class Class' unless base.name == 'Class'
    end

    def blank_slate(opts={})
      opts[:except] = opts[:except] ? (opts[:except].is_a?(Array) ? opts[:except] : [opts[:except]]) : []
      exceptions = ['method_missing', 'respond_to\?', '^__'] + opts[:except].map{|ex| ex.to_s}
      regexp = Regexp.new(exceptions.join('|'))
      instance_methods.each do |m|
        undef_method m unless regexp.match(m.to_s)
      end
    end
    alias_method :clean_room, :blank_slate
  end
end