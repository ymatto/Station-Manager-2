#!/Users/omm/.opam/default/bin/liquidsoap -v

def thefunction(~sec, ~min, ~hour, ~mday, ~mon, ~year, ~wday, ~yday, ~isdst) =
    daymapping = [
        (0, "Sunday"),
        (1, "Monday"),
        (2, "Tuesday"),
        (3, "Wednesday"),
        (4, "Thursday"),
        (5, "Friday"),
        (6, "Saturday")
    ]
    list.assoc(default="bad time provided", wday, daymapping)
end

result = localtime(gettimeofday(),thefunction)

print(result)
