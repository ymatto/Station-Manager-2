#!/usr/bin/ruby -w

# Expects JSON messages with the following structure:
#   {"text": "Text to convert to speech", "output_file": "/some/file/path.wav" }
#
# The values are fed to `say` like this:
#   `say --output-file=#{output_file} '#{text}'`

require 'webrick'
require 'json'




def say(text, output_file)
  cmd = "say --output-file=#{output_file} --data-format=LEI16@44100 --channels=2 '#{text}'"
  puts "--> Executing say command: #{cmd}"
  system(cmd)
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


##
## HTTP server
##
port = ENV['PORT'] || 3000
server = WEBrick::HTTPServer.new :Port => port
trap 'INT' do server.shutdown end

server.mount_proc '/say' do |req, res|
    request = req.body
    json = parse_json(request)
    if json
        say_text = json["text"]
        output_file = json["output_file"]
        say(say_text, output_file)
        res.body = output_file
    else
        res.body = "Bad say request"
    end
end

server.start