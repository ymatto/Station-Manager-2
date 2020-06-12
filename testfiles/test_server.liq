#!/Users/omm/.opam/default/bin/liquidsoap -v

set("server.telnet",true)

set("log.file.path","/tmp/simpletest.log")

%include "passwords.liq"  # sets variable: icecastpassword

radio1 = mksafe(playlist("/Users/omm/Radio Station/Music/Afterparty/"))

output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8000,
  password = icecastpassword, mount = "basscadettest.mp3",
  name = "BASSCADETTEST", radio1)

# ----

def cb_test (input_string) =
    server.write "#{input_string}\n" then
        "Done"
    end
end

server.register(namespace="cb",
                usage="test <something>",
                description="This is a test.",
                "test",
                cb_test)




def looper () =
    5.0
end

add_timeout(0.0, looper)
