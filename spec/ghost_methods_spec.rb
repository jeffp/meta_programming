require 'lib/meta_programming'

describe "MetaProgramming" do

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
  end

end