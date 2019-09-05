#!/usr/bin/env ruby -v

class Foo
  def method
    "method"
  end
end

class Foo
   old_method = instance_method(:method)

   define_method(:method) { |*args|
       # do something here ...
       a = old_method.bind(self).call(*args)
       a + " is replaced by Foo.define_method(:method)!"
   }
end
#replace.rb:12: warning: method redefined; discarding old method
#replace.rb:4: warning: previous definition of method was here

class Foo
  alias :method2 :method
  def method2
    self.method + " is aliased by Foo.method2"
  end
  #p self.methods
  #p self.instance_methods(false)
end

p Foo.new.method
p Foo.new.method2
