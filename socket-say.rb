#!/usr/bin/ruby -w
require 'socket'

class SocketSay
  def initialize(path)
    validate(path)

    @path = path
  end

  def validate(path)
    if File.exist?(path) && !File.socket?(path)
      puts "error: expected path to point at a unix socket, but got type: #{File.ftype(path)}"
      Process.exit(1)
    end
  end

  def loop
    Socket.unix_server_loop(@path) do |sock, client_addrinfo|
      puts "Listening on UNIX socket at #{@path}"

      begin
        input = read(sock)
        json = parse_json(input)

        if json
          puts "Received: #{json}"
          # say(json["text"], json["output_file"])
          sock.puts "OK"

        else
          puts "Received invalid JSON"
          sock.puts "ERROR"
        end

      ensure
        sock.close
      end
    end
  end


  def read(socket)
    input = ""

    while line = socket.gets
    puts "Received: #{line}"
      input += line
    end

    input
  end

  def parse_json(line)
    parsed = JSON.parse(line)

    if parsed && parsed.key?("text") && parsed.key?("output_file")
      parsed
    else
      puts "error: expected JSON to include keys \"text\" and \"output_file\", but one or both are missing: #{line}"
      nil
    end

  rescue => e
    puts "error parsing JSON: #{e}"
    nil
  end

  def say(text, output_file)
    cmd = "say --output-file=#{output_file} --data-format=LEI16@44100 --channels=2 '#{text}'"
    puts "--> Executing say command: #{cmd}"
    system(cmd)
  end
end

say = SocketSay.new(ARGV[0])
say.loop
