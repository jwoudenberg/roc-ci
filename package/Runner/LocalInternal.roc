interface Runner.LocalInternal
    exposes [
        run,
        Hook,
        foo,
    ]
    imports [
        CiTask.{ Task },
        CiInternal.{ Job, Step, StepError },
    ]

Hook : [CliCommand Str]

foo : List (Hook, Job)
foo = [(CliCommand "hi", { errors: [], steps: [{ name: "", dependencies: [], run: \_ -> CiTask.ok [] }] })]

run : List (Hook, Job), List Str -> Task {} I32
run = \hooks, args ->
    when args is
        [cmd] ->
            jobResult = List.findFirst hooks (\(CliCommand name, _) -> name == cmd)
            when jobResult is
                Err NotFound ->
                    {} <- CiTask.stdoutLine "unknown command '$(cmd)'" |> CiTask.await
                    {} <- CiTask.stdoutLine "" |> CiTask.await
                    showHelp hooks

                Ok (_, job) ->
                    runJob job
                    |> CiTask.onErr (\err -> CiTask.stdoutLine (runErrorToStr err))

        _ -> showHelp hooks

showHelp : List (Hook, Job) -> Task {} I32
showHelp = \hooks ->
    {} <- CiTask.stdoutLine "Usage: roc-ci local <cmd>" |> CiTask.await
    {} <- CiTask.stdoutLine "" |> CiTask.await
    {} <- CiTask.stdoutLine "commands:" |> CiTask.await
    {} <- taskForEach hooks (\(CliCommand cmd, _) -> CiTask.stdoutLine "  $(cmd)") |> CiTask.await
    CiTask.err 1

runJob : Job -> Task {} StepError
runJob = \job ->
    errors = CiInternal.jobErrors job
    if !(List.isEmpty errors) then
        CiTask.err (ConstructionErrors errors)
    else
        CiTask.loop
            (CiInternal.jobSteps job, Dict.empty {})
            (\(accSteps, results) ->
                when accSteps is
                    [] ->
                        CiTask.ok (Done {})

                    [step, .. as rest] ->
                        newResults <- runStep step results |> CiTask.await
                        CiTask.ok (Step (rest, newResults))
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
        |> CiTask.fromResult
        |> CiTask.await
    step.run input
    |> CiTask.map (\output -> Dict.insert results step.name output)

# Replacement for CiTask.forEach which at the moment crashes for me.
taskForEach : List a, (a -> Task {} b) -> Task {} b
taskForEach = \list, fn ->
    CiTask.loop
        list
        (\elems ->
            when elems is
                [] -> CiTask.ok (Done {})
                [elem, .. as rest] ->
                    {} <- fn elem |> CiTask.await
                    CiTask.ok (Step rest)
        )
