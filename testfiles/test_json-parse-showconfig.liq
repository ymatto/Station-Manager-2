#!/Users/omm/.opam/default/bin/liquidsoap -v

some_list_json = '{
        "Bump": {
            "signon": "This is the Bump.",
            "signoff": "Thanks for listening to the Bump."
        },
        "Headnod": {
            "signon": "This is the Head Nod.",
            "signoff": "Thanks for listening to the Head Nod."  
        }
}'

    
let json.parse (show_list : [(
    string * {
        signon: string,
        signoff: string
    })]
    as json.object
) = some_list_json


# show_list = [
#     ("Bump", {signon = "This is the Bump.", signoff = "Thanks for listening..."}),
#     ("Headnod", {signon = "This is the Head nod.", signoff = "Thanks for listening..."})
# ]


def get_show(thisshow) =
    thisshowkey = fst(thisshow)
    thisshowdata = snd(thisshow)
    print("thisshowdata:     #{thisshowdata}")
    
    print("name:        #{thisshowkey}")
    print("signon:      #{thisshowdata.signon}")
    print("signoff:     #{thisshowdata.signoff}")
end
    
list.iter(get_show, show_list)

