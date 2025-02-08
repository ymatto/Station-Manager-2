#!/usr/bin/ruby -w

# Expects JSON messages with the following structure:
#   {"text": "Text to convert to speech", "output_file": "/some/file/path.wav" }
#
# The values are fed to `say` like this:
#   `say --output-file=#{output_file} '#{text}'`

require 'webrick'
require 'json'
require 'date'



def macos_say(text, voice, output_file)
  cmd = "say --output-file=#{output_file} --data-format=LEI16@44100 --channels=2 -v '#{voice}' '#{text}'"
  puts "--> Executing say command: #{cmd}"
  system(cmd)
  # TODO make sure the system(cmd) didn't return an error
end

def parse_json(line)
  parsed = JSON.parse(line)

  if parsed && parsed.key?("tts_type") && parsed.key?("voice") && parsed.key?("text") && parsed.key?("output_path")
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

    res_result = "ERROR"
    res_data = ""

    if json
        tts_type = json["tts_type"]
        voice = json["voice"]
        say_text = json["text"]
        output_path = json["output_path"]

        if tts_type == "macos"
          output_file = output_path + "tts_macos_" + Time.now.strftime("%d-%m-%Y_%H%M%S") + ".wav"

          macos_say(say_text, voice, output_file)

          res_result = "SUCCESS"
          res_data = output_file
        else
          res_result = "ERROR"
          res_data = "TTS type not recognized"
        end
    else
        res_result = "ERROR"
        res_data = "Bad say request"
    end

    response = {
      'result' => res_result,
      'data' => res_data
    }
    # return response to POST
    res.body = JSON[response]
end

server.start