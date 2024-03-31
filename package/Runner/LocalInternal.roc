interface Runner.LocalInternal
    exposes [
        run,
        Hook,
    ]
    imports [
        pf.Task.{ Task },
        CiInternal.{ Job, Step, StepError },
        pf.Stdout,
    ]

Hook : [CliCommand Str]

run : List (Hook, Job), List Str -> Task {} I32
run = \hooks, args ->
    when args is
        [cmd] ->
            jobResult = List.findFirst hooks (\(CliCommand name, _) -> name == cmd)
            when jobResult is
                Err NotFound ->
                    {} <- Stdout.line "unknown command '$(cmd)'" |> Task.await
                    {} <- Stdout.line "" |> Task.await
                    showHelp hooks

                Ok (_, job) ->
                    runJob job
                    |> Task.onErr (\err -> Stdout.line (runErrorToStr err))

        _ -> showHelp hooks

showHelp : List (Hook, Job) -> Task {} I32
showHelp = \hooks ->
    {} <- Stdout.line "Usage: roc-ci local <cmd>" |> Task.await
    {} <- Stdout.line "" |> Task.await
    {} <- Stdout.line "commands:" |> Task.await
    {} <- taskForEach hooks (\(CliCommand cmd, _) -> Stdout.line "  $(cmd)") |> Task.await
    Task.err 1

runJob : Job -> Task {} StepError
runJob = \job ->
    errors = CiInternal.jobErrors job
    if !(List.isEmpty errors) then
        Task.err (ConstructionErrors errors)
    else
        Task.loop
            (CiInternal.jobSteps job, Dict.empty {})
            (\(accSteps, results) ->
                when accSteps is
                    [] ->
                        Task.ok (Done {})

                    [step, .. as rest] ->
                        newResults <- runStep step results |> Task.await
                        Task.ok (Step (rest, newResults))
            )

runErrorToStr : StepError -> Str
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

runStep : Step, Dict Str (List U8) -> Task (Dict Str (List U8)) StepError
runStep = \step, results ->
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
    step.run input
    |> Task.map (\output -> Dict.insert results step.name output)

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
