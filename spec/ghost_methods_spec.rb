require 'lib/meta_programming'

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
        class A2
          define_ghost_method(1) { puts 1}
        end
      }.should raise_exception(ArgumentError)
    end
    it "should scream if there's no block given" do
      lambda {
        class A3
          define_ghost_method(:tree)
        end
      }.should raise_exception
    end
    it "should define a ghost method using a symbol" do
      class A1
        define_ghost_method(:catch_this_one) { 'catch_this_one' }
      end
      lambda { A1.new.not_this_one }.should raise_exception(NoMethodError)
      lambda { A1.new.catch_this_one.should == 'catch_this_one' }.should_not raise_exception
      lambda { A1.new.catch_this_one_too }.should raise_exception(NoMethodError)
    end
    it "should warn about using 'return' keyword in method block" do
      class A4
        define_ghost_method(:catch_this_one) { return 'catch_this_one'}
      end
      lambda { A4.new.catch_this_one }.should raise_exception(LocalJumpError, /'return' keyword/)
    end
    it "should define a ghost method using a string" do
      class A5
        define_ghost_method('catch_another') { 'catch_another_one'}
      end
      lambda { A5.new.catch_another.should == 'catch_another_one'}.should_not raise_exception
      lambda { A5.new.catch_another_one }.should raise_exception(NoMethodError)
    end
    it "should define a ghost method using a regular expression" do
      class A6
        define_ghost_method(/catch/) do |object, symbol|
          symbol
        end
      end
      lambda { A6.new.catch_this_one.should == :catch_this_one }.should_not raise_exception
      lambda { A6.new.some_catch_here.should == :some_catch_here }.should_not raise_exception
      lambda { A6.new.atchoo }.should raise_exception(NoMethodError)
    end
    it "should pass arguments to the block" do
      class A7
        define_ghost_method(/ghost/) do |object, symbol, *args|
          "#{symbol.to_s.gsub(/_/, ' ')} #{args.join(' ')}"
        end
      end
      lambda { A7.new.ghost_methods('kick', 'butt').should == 'ghost methods kick butt'}.should_not raise_exception
    end
    it "should define ghost methods for class Object" do
      class Object
        define_ghost_method(:alive!) do
          'ALIVE'
        end
      end
      lambda { Object.new.alive!.should == 'ALIVE'}.should_not raise_exception
    end
    it "should accept lambda as an advanced matcher and lambda parameters should be object, matcher_result, *args" do
      class TestObject1
        def yes?; true; end
        def no?; false; end

        matcher = lambda {|obj, sym, *args| sym.to_s =~ /^yn_(.*\?)$/ && obj.methods.map(&:to_sym).include?($1.to_sym) && $1.to_sym }
        define_ghost_method(matcher) do |obj, res, *args|
          obj.__send__(res, *args) ? 'yes' : 'no'
        end
      end
      lambda { TestObject1.new.yes?.should == true}.should_not raise_exception
      lambda { TestObject1.new.no?.should == false }.should_not raise_exception
      lambda { TestObject1.new.yn_yes?.should == 'yes'}.should_not raise_exception
      lambda { TestObject1.new.yn_no?.should == 'no'}.should_not raise_exception
      lambda { TestObject1.new.yessir? }.should raise_exception(NoMethodError)
      lambda { TestObject1.new.yn_yessir? }.should raise_exception(NoMethodError)
    end
    it "should accept Procs as an advanced matcher and the parameters should be obj, matcher_result, *args" do
      class TestObject2
        def yes?; true; end
        def no?; false; end

        matcher = Proc.new{|obj, sym, *args| sym.to_s =~ /^yn_(.*\?)$/ && obj.methods.map(&:to_sym).include?($1.to_sym) && $1.to_sym }
        define_ghost_method(matcher) do |obj, res, *args|
          obj.__send__(res, *args) ? 'yes' : 'no'
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
        define_ghost_method('my_method') { 'yes_my_method'}
      end
      lambda { StringMatcher.new.my_method.should == 'yes_my_method'}.should_not raise_exception      
      lambda { StringMatcher.new.respond_to?(:my_method2).should be_false}.should_not raise_exception
      lambda { StringMatcher.new.respond_to?(:my_method).should be_true }.should_not raise_exception
      StringMatcher.new.respond_to?(:hello).should be_true
    end
    it "should create an appropriate respond_to? for the symbol matchers" do
      class SymbolMatcher
        def hello; end
        define_ghost_method(:my_method2) { 'yep_my_method'}
      end
      lambda { SymbolMatcher.new.my_method2.should == 'yep_my_method'}.should_not raise_exception
      lambda { SymbolMatcher.new.respond_to?(:my_method2).should be_true}.should_not raise_exception
      SymbolMatcher.new.respond_to?(:my_method).should be_false
      SymbolMatcher.new.respond_to?(:hello).should be_true
    end
    it "should create an appropriate respond_to? for the regexp matchers" do
      class RegexpMatcher
        def hello; end
        define_ghost_method(/^my_method$/) { 'yo_my_method'}
      end
      lambda { RegexpMatcher.new.my_method.should == 'yo_my_method'}.should_not raise_exception
      lambda { RegexpMatcher.new.respond_to?(:my_method).should be_true}.should_not raise_exception
      RegexpMatcher.new.respond_to?(:hello).should be_true
      class RegexpMatcher2
        def hello; end
        define_ghost_method(/^my_method\d$/) { 'yoo_my_method'}
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
        define_ghost_method(lambda{|obj, sym| sym.to_s =~ /^my_method\d$/ }) { 'uhhuh_my_method'}
      end
      lambda { LambdaMatcher.new.my_method2.should == 'uhhuh_my_method'}.should_not raise_exception
      lambda { LambdaMatcher.new.my_method}.should raise_exception(NoMethodError)
      lambda { LambdaMatcher.new.respond_to?(:my_method).should be_false}.should_not raise_exception
      lambda { LambdaMatcher.new.respond_to?(:my_method5).should be_true}.should_not raise_exception
      lambda { LambdaMatcher.new.respond_to?(:my_methods).should be_false}.should_not raise_exception
      LambdaMatcher.new.respond_to?(:hello).should be_true
    end
  end

end