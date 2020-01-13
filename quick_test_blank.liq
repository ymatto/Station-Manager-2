#!/Users/omm/.opam/default/bin/liquidsoap -v
# Log dir
set("log.file.path","/tmp/quick_test_blank.log")

thing = "yo"

log (thing)


# Generic make-it-run crap
radio = blank()
output.dummy(radio)
