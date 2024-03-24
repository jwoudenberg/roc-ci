interface Runner.Local
    exposes [
        onCliCommand,
    ]
    imports [
        CiInternal.{ Job },
        Hook.{ Hook },
    ]

onCliCommand : Str, Job -> Hook
onCliCommand = \cmd, job ->
    Hook.wrap { job, trigger: Local (CliCommand cmd) }
