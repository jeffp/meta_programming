require 'spec_helper'

describe "blank_slate" do

  def collect_test_methods(instance, exceptions=[])
    all_methods = [:public_methods, :protected_methods, :private_methods].map do |method|
      instance.send(method)
    end.flatten.map(&:to_sym).uniq
    matchers = (['^__', '^object_id$'] + (exceptions.is_a?(Array) ? exceptions : [exceptions])).join('|')
    allowed_methods = all_methods.select{|method| method.to_s =~ Regexp.new(matchers)}.map(&:to_sym)
    all_methods - allowed_methods
  end
  
  it "should only have certain instance methods (it's a blank slate)" do
    class BlankSlate1
      blank_slate
    end
    test_methods = collect_test_methods(Object.new, ['^method_missing', '^respond_to'])

    bs = BlankSlate1.new
    test_methods.each do |method|
      bs.respond_to?(method).should be_false
    end
  end

  it "should remove all but ^__ methods for option :all" do
    class BlankSlate2
      blank_slate :all=>true
      public :__send__
    end
    test_methods = collect_test_methods(Object.new)

    bs = BlankSlate2.new
    test_methods.each do |method|
#      lambda { bs.__send__(method); nil }.should raise_exception(NoMethodError)
    end
  end

  it "should work for exceptions" do
    class BlankSlate3
      blank_slate :except=>[:methods]
    end
    test_methods = collect_test_methods(Object.new, ['^methods$', '^method_missing', '^respond_to'])

    bs=BlankSlate3.new
    test_methods.each do |method|
      bs.respond_to?(method).should == false
    end

  end

end


  