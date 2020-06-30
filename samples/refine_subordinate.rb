module DD
  def self.dd
    p "DD.dd going to call .hello"
    'From another ruby file'.hello
    p "DD.dd done with .hello"
  end
end
