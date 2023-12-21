#!/Users/omm/.opam/default/bin/liquidsoap -v

some_list_json = '[
        {
            "days": ["Sunday"],
            "show_hours": [0, 7, 20],
            "type": "daysofweek"
        },
        {
            "days": ["Monday", "Tuesday"],
            "show_hours": [0, 7, 10, 20],
            "type": "daysofweek"
        }
]'

    
let json.parse (showschedule_list : [{
        days: [string],
        show_hours: [int],
        type: string
    }]
) = some_list_json


# showschedule_list = [
#     {days = ["Sunday"], show_hours = [0, 7, 20], type = "daysofweek"},
#     {days = ["Monday", "Tuesday"], show_hours = [0, 7, 10, 20], type = "daysofweek"}
# ]


def get_showschedule(thisshowschedule) =
    print("thisshowdata:     #{thisshowschedule}")
    
    print("days:          #{thisshowschedule.days}")
    print("show_hours:    #{thisshowschedule.show_hours}")
    print("type:          #{thisshowschedule.type}")
end
    
list.iter(get_showschedule, showschedule_list)

