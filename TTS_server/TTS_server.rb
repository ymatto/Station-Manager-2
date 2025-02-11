#!/usr/bin/ruby -w

# Expects JSON messages with the following structure:
#   {
#     "tts_type": "macos",
#     "voice": "Daniel (Enhanced)",
#     "text": "Hello, my name is Daniel... Enhanced."
#   }
#
# The values are fed to a supported TTS tool, and a complete path to the resulting file returned.
#
# Use environment variables to set:
#   PORT (defaults to 3000) for the port the server will listen for requests
#   ENDPOINT (defaults to "/say") for the HTTP path for the endpoint for requests
#   OUTPUT_PATH (defaults to "tmp/") for the resulting audio file
#     If using TTS_server with a client calling from docker, make sure the OUTPUT_PATH is visible to the docker environment.

require 'webrick'
require 'json'
require 'date'


# TTS handler functions
def macos_say(text, voice, output_file)
  # clean up the strings for safety
  text = text.delete('"')
  voice = voice.delete('"')
  output_file = output_file.delete('"')

  cmd = "say --output-file=\"#{output_file}\" --data-format=LEI16@44100 --channels=2 -v \"#{voice}\" \"#{text}\""
  puts "--> Executing say command: #{cmd}"
  system(cmd)
end


def parse_json(line)
  parsed = JSON.parse(line)

  if parsed && parsed.key?("tts_type") && parsed.key?("voice") && parsed.key?("text")
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
endpoint = ENV['ENDPOINT'] || "/say"
output_path = ENV['OUTPUT_PATH'] || "tmp/"
server = WEBrick::HTTPServer.new :Port => port
trap 'INT' do server.shutdown end

server.mount_proc endpoint do |req, res|
    request = req.body
    json = parse_json(request)

    res_result = "ERROR"
    res_data = ""

    if json
        tts_type = json["tts_type"]
        voice = json["voice"]
        say_text = json["text"]

        timestamp = Time.now.strftime("%d-%m-%Y_%H%M%S")

        # other TTS handlers can go in here
        if tts_type == "macos"
          # TODO make the output location configred via ENV or something, where the client knows where to look
          output_filename = "tts_macos_#{timestamp}.wav"
          output_file = "#{output_path}#{output_filename}"

          system_result = macos_say(say_text, voice, output_file)

          if system_result
            res_result = "SUCCESS"
            # we just return the filename because the client needs to know where to look
            res_data = output_filename
          else
            res_result = "ERROR"
            res_data = "TTS command returned error or does not exist"
          end
        # we don't have a handler for whatever the client asked for
        else
          res_result = "ERROR"
          res_data = "TTS type not recognized"
        end
    # bad JSON from the requester
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