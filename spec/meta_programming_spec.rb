require 'lib/meta_programming'

describe "MetaProgramming" do
  describe "eigenclass and metaclass methods" do
    it "should return the eigen class of a class" do
      class A
        class << self; self; end.should == self.eigenclass
        class << self; self; end.should == self.metaclass
      end
      class << A; self; end.should == A.eigenclass
      class << A; self; end.should == A.metaclass
    end
    it "should return the eigen class of an object" do
      class A; def return_eigenclass; eigenclass; end; end
      a = A.new
      class << a; self; end.should == a.eigenclass
      class << a; self; end.should == a.metaclass
    end
  end
  describe "define_chained_method" do
    it "should complain if there is no block" do
      lambda {
        class B1
          def target; end
          define_chained_method(:target, :chain)
        end
      }.should raise_exception
    end
    it "should define and chain a method" do
      class B2; def target(array); array << 'target'; end; end
      B2.new.target(['init']).should == ['init', 'target']
      class B2
        define_chained_method(:target, :chain) do |array|
          array << 'chain'
          target_without_chain(array)
        end
      end
      B2.new.target(['init']).should == ['init', 'chain', 'target']
    end
#    it "should complain if block has wrong arity" do
#      lambda {
#        class B3
#          def target(array); array << 'target'; end
#          define_chained_method(:target, :chain) do
#            target_without_chain(['chain'])
#          end
#        end
#        B3.new.target(['init'])
#      }.should raise_exception
#    end
    it "should define and chain a method safely if there is no target method" do
      class B4
        define_chained_method(:target, :chain) do |array|
          array << 'chain'
          target_without_chain(array)
        end
        B4.new.target(['init']).should == ['init', 'chain']
      end
    end
  end
  describe "safe_alias_method_chain method" do
    it "should not chain for non-existent chaining method" do
      class A
        def primary(array); array << 'primary'; end
        #do not define :primary_with_ext
        safe_alias_method_chain :primary, :ext
      end
      a=A.new
      a.primary(['init']).should == ['init', 'primary']
    end
    it "should not raise NoMethod error when chaining for non-existing primary method" do
      lambda {
        class A0
          def primary_with_ext(array)
            array << 'chaining'
            primary_without_ext(array)
          end
          safe_alias_method_chain :primary, :ext
        end
        a=A0.new
        a.primary(['init']).should == ['init', 'chaining']
      }.should_not raise_exception(NoMethodError)
    end
    it "should chain for two methods" do
      class A1
        def primary(array)
          array << 'primary'
        end

        def primary_with_ext(array)
          array << 'chaining_in'
          primary_without_ext(array)
          array << 'chaining_out'
        end
        safe_alias_method_chain :primary, :ext
      end
      A1.new.primary(['init']).should == ['init', 'chaining_in', 'primary', 'chaining_out']
    end
    it "should chain for three methods" do
      class A2 
        def primary(array); array << 'primary'; end
        
        def primary_with_one(array); array << 'one'; primary_without_one(array); end
        
        def primary_with_two(array); array << 'two'; primary_without_two(array); end
        
        safe_alias_method_chain :primary, :one
        safe_alias_method_chain :primary, :two
      end
      A2.new.primary(['init']).should == ['init', 'two', 'one', 'primary']
    end
    it "should not cause endless loop when called twice" do
      lambda {
        class A3
          def primary(array); array << 'primary'; end
          def primary_with_one(array); array << 'one'; primary_without_one(array); end

          safe_alias_method_chain :primary, :one
          safe_alias_method_chain :primary, :one
        end
        A3.new.primary(['init']).should == ['init', 'one', 'primary']
      }.should_not raise_exception
    end
    it "should chain with = punctuation" do
      class A5
        def primary=(array); array << 'primary'; end
        def primary_with_one=(array); array << 'one'; self.primary_without_one=(array); end

        safe_alias_method_chain :primary=, :one
      end
      lambda {
        a = A5.new.primary=(['init'])
        a.should == ['init', 'one', 'primary']
      }.should_not raise_exception
    end
    it "should chain with ? punctuation" do
      class A6
        def primary?(array); array << 'primary'; end
        def primary_with_one?(array); array << 'one'; primary_without_one?(array); end

        safe_alias_method_chain :primary?, :one
      end
      lambda {
        A6.new.primary?(['init']).should == ['init', 'one', 'primary']
      }.should_not raise_exception
    end
    it "should chain with ! punctuation" do
      class A7
        def primary!(array); array << 'primary'; end
        def primary_with_one!(array); array << 'one'; primary_without_one!(array); end

        safe_alias_method_chain :primary!, :one
      end
      lambda {
        A7.new.primary!(['init']).should == ['init', 'one', 'primary']
      }.should_not raise_exception
    end
  end
end