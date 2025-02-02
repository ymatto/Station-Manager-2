#!/usr/bin/ruby -w
require "socket"

unless ARGV[0]
  puts "error: expected path to unix socket as first argument"
  Process.exit(1)
end

close = false
socket = UNIXSocket.new(ARGV[0])
while close == false do
  puts "Type a JSON message and press enter. Type 'exit' to quit."
  puts ">"
  message = STDIN.gets
  puts "INPUT: #{message}"
  Process.exit(0) if message.strip == "exit"

  begin
    socket.write(message)
    response = socket.readline
    puts response
  rescue Errno::EPIPE
    puts "lost server connection!"
    close = true
    socket.close
  end
end
