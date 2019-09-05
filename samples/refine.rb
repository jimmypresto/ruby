#!/usr/bin/env ruby -w
#
class A
  def foo
    "foo"
  end
end 

module B
  refine A do
    def foo
      "A.foo is refined by B.foo"
    end
  end
end

p A.new.foo

using B
p A.new.foo

