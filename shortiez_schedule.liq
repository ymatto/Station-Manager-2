# Music (shuffle mode is default)
pl_shortiez1 = playlist(id="Shortiez1", list.assoc(default="error", "Shortiez1", !show_paths))
pl_shortiez2 = playlist(id="Shortiez2", list.assoc(default="error", "Shortiez2", !show_paths))

radio = mksafe(
          crossfade(
            switch(
              [
                ({ 0m-2m }, pl_shortiez1),
                ({ 2m-4m }, pl_shortiez2),
                ({ 4m-6m }, pl_shortiez1),
                ({ 6m-8m }, pl_shortiez2),
                ({ 8m-10m }, pl_shortiez1),
                ({ 10m-12m }, pl_shortiez2),
                ({ 12m-14m }, pl_shortiez1),
                ({ 14m-16m }, pl_shortiez2),
                ({ 16m-18m }, pl_shortiez1),
                ({ 18m-20m }, pl_shortiez2),
                ({ 20m-22m }, pl_shortiez1),
                ({ 22m-24m }, pl_shortiez2),
                ({ 24m-26m }, pl_shortiez1),
                ({ 26m-28m }, pl_shortiez2),
                ({ 28m-30m }, pl_shortiez1),
                ({ 30m-32m }, pl_shortiez2),
                ({ 32m-34m }, pl_shortiez1),
                ({ 34m-36m }, pl_shortiez2),
                ({ 36m-38m }, pl_shortiez1),
                ({ 38m-40m }, pl_shortiez2),
                ({ 40m-42m }, pl_shortiez1),
                ({ 42m-44m }, pl_shortiez2),
                ({ 44m-46m }, pl_shortiez1),
                ({ 46m-48m }, pl_shortiez2),
                ({ 48m-50m }, pl_shortiez1),
                ({ 50m-52m }, pl_shortiez2),
                ({ 52m-54m }, pl_shortiez1),
                ({ 54m-56m }, pl_shortiez2),
                ({ 56m-58m }, pl_shortiez1),
                ({ 58m-60m }, pl_shortiez2)
              ]
            )
          )
        )
