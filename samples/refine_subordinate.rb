module AA
  def self.dd
    p "AA.dd going to call .hello"
    'From another ruby file'.hello
    p "AA.dd done with .hello"
  end
end
