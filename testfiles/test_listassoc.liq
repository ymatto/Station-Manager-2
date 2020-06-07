#!/Users/omm/.opam/default/bin/liquidsoap -v

pair_list = [("this", "thing1"), ("that", "thing2"), ("this", "thing3")]

result = list.assoc (default="error", "that", pair_list)

print(result)
