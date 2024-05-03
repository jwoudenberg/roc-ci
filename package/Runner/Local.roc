module [
    onCliCommand,
]

import CiInternal exposing [Job]
import Hook exposing [Hook]

onCliCommand : Str, Job -> Hook
onCliCommand = \cmd, job ->
    Hook.wrap { job, trigger: Local (CliCommand cmd) }
