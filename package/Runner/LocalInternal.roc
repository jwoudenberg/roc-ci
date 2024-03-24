interface Runner.LocalInternal
    exposes [
        run,
        Hook,
    ]
    imports [
        pf.Task.{ Task },
        CiInternal.{ Job },
    ]

Hook : [CliCommand Str]

run : List (Hook, Job), List Str -> Task {} *
