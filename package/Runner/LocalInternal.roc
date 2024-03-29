interface Runner.LocalInternal
    exposes [
        run,
        Hook,
    ]
    imports [
        pf.Task.{ Task },
        CiInternal.{ Job, Step },
        pf.Stdout,
    ]

Hook : [CliCommand Str]

Error : [
    MissingDependency Str,
    InputDecodingFailed,
    UserError Str,
    ConstructionErrors (List Str),
]

run : List (Hook, Job), List Str -> Task {} []
run = \hooks, args ->
    jobsByCommand =
        List.walk
            hooks
            (Dict.empty {})
            (\dict, (CliCommand cmd, job) -> Dict.insert dict cmd job)

    when args is
        [cmd] ->
            when Dict.get jobsByCommand cmd is
                Err KeyNotFound ->
                    {} <- Stdout.line "unknown command '$(cmd)'" |> Task.await
                    {} <- Stdout.line "" |> Task.await
                    showHelp (Dict.keys jobsByCommand)

                Ok job ->
                    runJob job
                    |> Task.mapErr runErrorToStr
                    |> Task.onErr Stdout.line

        _ -> showHelp (Dict.keys jobsByCommand)

showHelp : List Str -> Task {} []
showHelp = \cmds ->
    {} <- Stdout.line "Usage: roc-ci local <cmd>" |> Task.await
    {} <- Stdout.line "" |> Task.await
    {} <- Stdout.line "commands:" |> Task.await
    taskForEach cmds (\cmd -> Stdout.line "  $(cmd)")

runJob : Job -> Task {} Error
runJob = \job ->
    { steps, runFns, errors } = CiInternal.spec job
    if !(List.isEmpty errors) then
        Task.err (ConstructionErrors errors)
    else
        runSteps steps runFns (Dict.empty {})

runErrorToStr : Error -> Str
runErrorToStr = \err ->
    when err is
        MissingDependency name ->
            "Internal error: MissingDependency $(name)"

        InputDecodingFailed ->
            "Internal error: InputDecodingFailed"

        UserError msg ->
            msg

        ConstructionErrors msgs ->
            List.walk
                msgs
                "I found some problems with this job:\n"
                (\acc, msg -> Str.concat acc "- $(msg)\n")

runSteps :
    List Step,
    List (List U8 -> Task (List U8) [UserError Str, InputDecodingFailed]),
    Dict Str (List U8)
    -> Task {} Error
runSteps = \steps, runFns, results ->
    when steps is
        [] -> Task.ok {}
        [step, .. as restSteps] ->
            input <-
                List.walk
                    step.dependencies
                    (Ok [])
                    (\acc, dependency ->
                        inputSoFar <- Result.try acc
                        newInput <-
                            Dict.get results dependency
                            |> Result.mapErr (\KeyNotFound -> MissingDependency dependency)
                            |> Result.try
                        Ok (List.concat inputSoFar newInput)
                    )
                |> Task.fromResult
                |> Task.await
            (runFn, restRunFns) =
                when runFns is
                    [] -> crash ""
                    [head, .. as rest] -> (head, rest)
            output <-
                runFn input
                |> Task.mapErr
                    (\err ->
                        when err is
                            UserError msg -> UserError msg
                            InputDecodingFailed -> InputDecodingFailed
                    )
                |> Task.await
            runSteps
                restSteps
                restRunFns
                (Dict.insert results step.name output)

# Replacement for Task.forEach which at the moment crashes for me.
taskForEach : List a, (a -> Task {} b) -> Task {} b
taskForEach = \list, fn ->
    Task.loop
        list
        (\elems ->
            when elems is
                [] -> Task.ok (Done {})
                [elem, .. as rest] ->
                    {} <- fn elem |> Task.await
                    Task.ok (Step rest)
        )
