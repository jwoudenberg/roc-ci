interface Local
    exposes [
        onCliCommand,
    ]
    imports [
        CiInternal.{ Job },
        Hook.{ Hook },
    ]

onCliCommand : Str, Job -> Hook
