class HelloWorld
  def call(env)
    body = 'Hello, World!'
   [200, { 'Content-Type' => 'text/plain', 'Content-Length' => body.length.to_s }, [body]]
  end
end

run HelloWorld.new
