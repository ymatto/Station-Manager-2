# Music (shuffle mode is default)
pl_afterparty = playlist(id="Afterparty", list.assoc(default="error", "Afterparty", !show_paths))
pl_braindance = playlist(id="Braindance", list.assoc(default="error", "Braindance", !show_paths))
pl_bump = playlist(id="Bump", list.assoc(default="error", "Bump", !show_paths))
pl_beats = playlist(id="Beats", list.assoc(default="error", "Beats", !show_paths))
pl_headnod = playlist(id="Headnod", list.assoc(default="error", "Headnod", !show_paths))
pl_nightmode = playlist(id="Nightmode", list.assoc(default="error", "Nightmode", !show_paths))
pl_groovestyle = playlist(id="Groovestyle", list.assoc(default="error", "Groovestyle", !show_paths))

radio = mksafe(
          crossfade(
            switch(
              [
                ({ 0w and 0h-7h }, pl_afterparty),
                ({ 0w and 7h-20h }, pl_groovestyle),
                ({ 0w and 20h-24h }, pl_nightmode),
                ({ (1w or 3w) and 0h-7h }, pl_afterparty),
                ({ (1w or 3w) and 7h-10h }, pl_groovestyle),
                ({ (1w or 3w) and 10h-20h }, pl_braindance),
                ({ (1w or 3w) and 20h-24h }, pl_nightmode),
                ({ (2w or 4w) and 0h-7h }, pl_beats),
                ({ (2w or 4w) and 7h-11h }, pl_headnod),
                ({ (2w or 4w) and 11h-16h }, pl_bump),
                ({ (2w or 4w) and 16h-22h }, pl_headnod),
                ({ (2w or 4w) and 22h-24h }, pl_beats),
                ({ 5w and 0h-4h }, pl_afterparty),
                ({ 5w and 4h-10h }, pl_groovestyle),
                ({ 5w and 10h-20h }, pl_braindance),
                ({ 5w and 20h-24h }, pl_afterparty),
                ({ 6w and 0h-7h }, pl_afterparty),
                ({ 6w and 7h-12h }, pl_groovestyle),
                ({ 6w and 12h-20h }, pl_braindance),
                ({ 6w and 20h-24h }, pl_nightmode)
              ]
            )
          )
        )
