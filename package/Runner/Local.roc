interface Runner.Local
    exposes [
        onCliCommand,
    ]
    imports [
        CiInternal.{ Job },
        Hook.{ Hook },
    ]

onCliCommand : Str, (Job -> Job) -> Hook
onCliCommand = \cmd, mkJob ->
    Hook.wrap { job: mkJob CiInternal.empty, trigger: Local (CliCommand cmd) }
