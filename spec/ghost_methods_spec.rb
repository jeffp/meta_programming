require 'spec_helper'

describe "MetaProgramming" do

  describe "define_method_missing_chain method" do
    it "should create a method_missing chain" do
      class E1
        def hello; 'hello'; end
        define_method_missing_chain(:help) do |symbol, *args|
          if symbol == :help
            'help'
          else
            method_missing_without_help(symbol, *args)
          end
        end
      end
      lambda { E1.new.help.should == 'help' }.should_not raise_exception
      lambda { E1.new.helpme }.should raise_exception(NoMethodError)
    end
    it "should scream if defined twice" do
      lambda {
        class E2
          define_method_missing_chain(:help) {}
          define_method_missing_chain(:help) {}
         end
      }.should raise_exception
    end
    it "should scream if block missing" do
      lambda {
        class E3
          define_method_missing_chain(:help)
        end
      }.should raise_exception
    end
  end
  describe "define_ghost_method method" do
    it "should scream if matcher is not string, symbol or regular expression" do
      lambda {
        class GHA2
          define_ghost_method(1) {|sym| puts 1}
        end
      }.should raise_exception(ArgumentError)
    end
    it "should scream if there's no block given" do
      lambda {
        class GHA3
          define_ghost_method(:tree)
        end
      }.should raise_exception
    end
    it "should define a ghost method using a symbol" do
      class GHA1
        define_ghost_method(:catch_this_one) {|sym| 'catch_this_one' }
      end
      lambda { GHA1.new.not_this_one }.should raise_exception(NoMethodError)
      lambda { GHA1.new.catch_this_one.should == 'catch_this_one' }.should_not raise_exception
      lambda { GHA1.new.catch_this_one_too }.should raise_exception(NoMethodError)
    end
    it "should define a ghost method using a string" do
      class GHA5
        define_ghost_method('catch_another') {|sym| 'catch_another_one'}
      end
      lambda { GHA5.new.catch_another.should == 'catch_another_one'}.should_not raise_exception
      lambda { GHA5.new.catch_another_one }.should raise_exception(NoMethodError)
    end
    it "should define a ghost method using a regular expression" do
      class GHA6
        define_ghost_method(/catch/) do |symbol|
          symbol
        end
      end
      lambda { GHA6.new.catch_this_one.should == :catch_this_one }.should_not raise_exception
      lambda { GHA6.new.some_catch_here.should == :some_catch_here }.should_not raise_exception
      lambda { GHA6.new.atchoo }.should raise_exception(NoMethodError)
    end
    it "should pass arguments to the block" do
      class GHA7
        define_ghost_method(/ghost/) do |symbol, *args|
          "#{symbol.to_s.gsub(/_/, ' ')} #{args.join(' ')}"
        end
      end
      lambda { GHA7.new.ghost_methods('kick', 'butt').should == 'ghost methods kick butt'}.should_not raise_exception
    end
    it "should pass parameters" do
      class GHA9
        define_ghost_method('test_args') do |sym, *args|
          args.join(' ')
        end
      end
      GHA9.new.test_args('hi', 'you').should == 'hi you'
    end
    #ghost methods that can call blocks are not supported
    #it "should work for methods called with blocks in 1.9" do
    #  class GHA8
    #    define_ghost_method(:call_block) do |obj, sym, *args|
    #      yield(*args)
    #    end
    #  end
    #  GHA8.new.call_block(%w(hi you)) do |*args|
    #    args.join(' ')
    #  end.should == 'hi you'
    #end
    it "should define ghost methods for class Object" do
      class Object
        define_ghost_method(:alive!) do |sym|
          'ALIVE'
        end
      end
      lambda { Object.new.alive!.should == 'ALIVE'}.should_not raise_exception
    end
    it "should accept lambda as an advanced matcher and lambda parameters should be matcher_result, *args" do
      class TestObject1
        def yes?; true; end
        def no?; false; end

        matcher = lambda {|sym| sym.to_s =~ /^yn_(.*\?)$/ && self.class.method_defined?($1.to_sym) && $1.to_sym }
        define_ghost_method(matcher) do |res, *args|
          self.__send__(res, *args) ? 'yes' : 'no'
        end
      end
      lambda { TestObject1.new.yes?.should == true}.should_not raise_exception
      lambda { TestObject1.new.no?.should == false }.should_not raise_exception
      lambda { TestObject1.new.yn_yes?.should == 'yes'}.should_not raise_exception
      lambda { TestObject1.new.yn_no?.should == 'no'}.should_not raise_exception
      lambda { TestObject1.new.yessir? }.should raise_exception(NoMethodError)
      lambda { TestObject1.new.yn_yessir? }.should raise_exception(NoMethodError)
    end
    it "should create a private ghost_method_handler and ghost_method_matcher and not a public ones" do
      class TestObject3
        matcher = lambda {|sym| sym.to_s =~ /asdfjf/ && sym}
        define_ghost_method(matcher) {|sym| 'hello' }
      end
      obj = TestObject3.new
      obj.private_methods.map(&:to_s).detect{|method| method =~ /ghost_method_handler/}.should_not be_nil
      obj.private_methods.map(&:to_s).detect{|method| method =~ /ghost_method_matcher/}.should_not be_nil
    end
    it "should accept Procs as an advanced matcher and the parameters should be obj, matcher_result, *args" do
      class TestObject2
        def yes?; true; end
        def no?; false; end

        matcher = Proc.new{|sym| sym.to_s =~ /^yn_(.*\?)$/ && methods.map(&:to_sym).include?($1.to_sym) && $1.to_sym }
        define_ghost_method(matcher) do |res, *args|
          __send__(res, *args) ? 'yes' : 'no'
        end
      end
      lambda { TestObject2.new.yes?.should == true}.should_not raise_exception
      lambda { TestObject2.new.no?.should == false }.should_not raise_exception
      lambda { TestObject2.new.yn_yes?.should == 'yes'}.should_not raise_exception
      lambda { TestObject2.new.yn_no?.should == 'no'}.should_not raise_exception
      lambda { TestObject2.new.yessir? }.should raise_exception(NoMethodError)
      lambda { TestObject2.new.yn_yessir? }.should raise_exception(NoMethodError)
    end
    it "should create an appropriate respond_to? for the string matchers" do
      class StringMatcher
        def hello; end
        define_ghost_method('my_method') {|sym| 'yes_my_method'}
      end
      lambda { StringMatcher.new.my_method.should == 'yes_my_method'}.should_not raise_exception
      lambda { StringMatcher.new.respond_to?(:my_method2).should be_false}.should_not raise_exception
      lambda { StringMatcher.new.respond_to?(:my_method).should be_true }.should_not raise_exception
      StringMatcher.new.respond_to?(:hello).should be_true
    end
    it "should create an appropriate respond_to? for the symbol matchers" do
      class SymbolMatcher
        def hello; end
        define_ghost_method(:my_method2) {|sym| 'yep_my_method'}
      end
      lambda { SymbolMatcher.new.my_method2.should == 'yep_my_method'}.should_not raise_exception
      lambda { SymbolMatcher.new.respond_to?(:my_method2).should be_true}.should_not raise_exception
      SymbolMatcher.new.respond_to?(:my_method).should be_false
      SymbolMatcher.new.respond_to?(:hello).should be_true
    end
    it "should create an appropriate respond_to? for the regexp matchers" do
      class RegexpMatcher
        def hello; end
        define_ghost_method(/^my_method$/) {|sym| 'yo_my_method'}
      end
      lambda { RegexpMatcher.new.my_method.should == 'yo_my_method'}.should_not raise_exception
      lambda { RegexpMatcher.new.respond_to?(:my_method).should be_true}.should_not raise_exception
      RegexpMatcher.new.respond_to?(:hello).should be_true
      class RegexpMatcher2
        def hello; end
        define_ghost_method(/^my_method\d$/) {|sym| 'yoo_my_method'}
      end
      lambda { RegexpMatcher2.new.my_method1.should == 'yoo_my_method'}.should_not raise_exception
      lambda { RegexpMatcher2.new.my_method }.should raise_exception(NoMethodError)
      lambda { RegexpMatcher2.new.respond_to?(:my_method).should be_false}.should_not raise_exception
      lambda { RegexpMatcher2.new.respond_to?(:my_method2).should be_true}.should_not raise_exception
      lambda { RegexpMatcher2.new.respond_to?(:my_method10).should be_false}.should_not raise_exception
    end
    it "should create an appropriate respond_to? for the lambda matchers" do
      class LambdaMatcher
        def hello; end
        define_ghost_method(lambda{|sym| sym.to_s =~ /^my_method\d$/ }) {|sym| 'uhhuh_my_method'}
      end
      lambda { LambdaMatcher.new.my_method2.should == 'uhhuh_my_method'}.should_not raise_exception
      lambda { LambdaMatcher.new.my_method}.should raise_exception(NoMethodError)
      lambda { LambdaMatcher.new.respond_to?(:my_method).should be_false}.should_not raise_exception
      lambda { LambdaMatcher.new.respond_to?(:my_method5).should be_true}.should_not raise_exception
      lambda { LambdaMatcher.new.respond_to?(:my_methods).should be_false}.should_not raise_exception
      LambdaMatcher.new.respond_to?(:hello).should be_true
    end

    if RUBY_VERSION >= '1.9'
      it "should not raise a LocalJump error when 'return' keyword used in method block" do
        class GHB1
          define_ghost_method(:my_method) {|sym| return 'hello'}
        end
        lambda { GHB1.new.my_method.should == 'hello'}.should_not raise_exception
        lambda { GHB1.new.my_method2}.should raise_exception(NoMethodError)
      end
    end
    it "should not raise a LocalJumpError when 'return' keyword used in lambda matcher" do
       class GHB2
         matcher = lambda{|sym| return true if sym == :my_method; return false }
         define_ghost_method(matcher){|sym| 'hello'}
       end
       lambda { GHB2.new.my_method.should == 'hello'}.should_not raise_exception
       lambda { GHB2.new.my_method2 }.should raise_exception(NoMethodError)
    end
    it "should indicate exceptions come from method block when originating in method block" do
      class GHB3
        define_ghost_method(:my_method){|sym| raise "my cool exception"}
      end
      lambda { GHB3.new.my_method}.should raise_exception(/ghost method block/)
      lambda { GHB3.new.my_method}.should raise_exception(/my cool exception/)
    end
    it "should indicate exceptions come from lambda matcher when originating in lambda matcher" do
      class GHB4
        matcher = lambda{|sym| raise 'my cooler exception'}
        define_ghost_method(matcher){|sym| 'hello'}
      end
      lambda { GHB4.new.my_method}.should raise_exception(/ghost method matcher/)
      lambda { GHB4.new.my_method}.should raise_exception(/my cooler exception/)
    end
    it "should indicate exceptions come from respond_to? matcher when originating from there" do
      class GHB6
        matcher = lambda{|sym| raise 'my respond_to exception'}
        define_ghost_method(matcher){|sym| 'hello'}
      end
      lambda { GHB6.new.respond_to?(:my_method)}.should raise_exception(/ghost method matcher/)
      lambda { GHB6.new.respond_to?(:my_method)}.should raise_exception(/my respond_to exception/)
    end
    it "should inform about using method_defined? instead of respond_to? in matcher" do
      class GHB5
        matcher = lambda{|sym| sym.to_s =~ /^x_(.+)$/ && self.respond_to?($1.to_sym) && $1.to_sym }
        define_ghost_method(matcher){|sym, *args| __send__(sym, *args) }
      end
      lambda { GHB5.new.x_methods }.should raise_exception(/method_defined\?/)
    end
  end

end