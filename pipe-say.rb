# Pipe say expects JSON messages with the following structure:
#   {"text": "Text to convert to speech", "output_file": "/some/file/path.wav" }
#
# The values are fed to `say` like this:
#   `say --output-file=#{output_file} '#{text}'`
#
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
## Main
##
def main
  pipe = ENV['PIPE_PATH']
  raise "error: expected PIPE_PATH environment variable to be set" unless pipe
  raise "error: no file found at PIPE_PATH: #{pipe}" unless File.exists?(pipe)
  raise "error: expected PIPE_PATH to point at a named pipe, but got type: #{File.ftype(pipe)}" unless File.pipe?(pipe)

  f = File.open(pipe, 'r')

  while true do
    f.each_line do |line|
      json = parse_json(line)

      if json
        say(json["text"], json["output_file"])
      end
    end
  end
end

main()
