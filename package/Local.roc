interface Local
    exposes [
        # API
        onCliCommand,

        # Internals
        run,
        Hook,
    ]
    imports [
        pf.Task.{ Task },
        Job.{ Job },
    ]

onCliCommand : Str, Job -> ([Local Hook], Job)

Hook : [CliCommand Str]

run : List (Hook, Job), List Str -> Task {} *
