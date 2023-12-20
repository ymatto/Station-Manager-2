#!/Users/omm/.opam/default/bin/liquidsoap -v

some_list_json = '{
    "show_list": {
        "Bump": {
            "signon": "This is the Bump.",
            "signoff": "Thanks for listening to the Bump."
        },
        "Headnod": {
            "signon": "This is the Head Nod.",
            "signoff": "Thanks for listening to the Head Nod."  
        }
    }
}'

    
let json.parse ({
    show_list
} : {
    show_list: [(string * [(string * string)])]
}) = some_list_json


def get_show(thisshow) =
    thisshowkey = fst(thisshow)
    thisshowdata = snd(thisshow)
    
    thisshowsignon = list.assoc (default="error", "signon", thisshowdata)
    print("signon:     #{thisshowsignon}")
end
    
list.iter(get_show, show_list)
