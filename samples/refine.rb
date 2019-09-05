#!/usr/bin/env ruby -w

class A
  def foo
    "foo"
  end
end 

module B
  refine A do
    def foo
      super + " refined by B.foo"
    end
  end
end

using B
p A.new.foo

