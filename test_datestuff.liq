#!/Users/omm/.opam/default/bin/liquidsoap -v

def thefunction(~sec, ~min, ~hour, ~mday, ~mon, ~year, ~wday, ~yday, ~isdst) =
    hour
end

result = localtime(gettimeofday(),thefunction)

print(result)
