interface Ci
    exposes [
        Job,
        File,
        Dir,
        main,

        # Job definition
        Input,
        step0,
        step1,
        step2,

        # Setup steps
        setupGit,
    ]
    imports [
        pf.Task.{ Task },
        pf.Arg.{ Parser },
        pf.Stdout,
        rvn.Rvn,
        CiInternal,
        Hook,
        Runner.LocalInternal,
        Runner.GithubActionsInternal,
    ]

# TODO: Figure out how to pull File/Dir values out of arbitrary input structures

Job : CiInternal.Job

Hook : Hook.Hook

Input val := {
    dependsOn : Str,
}

File := {} implements [Encoding, Decoding]

Dir := {} implements [Encoding, Decoding]

step0 : Job,
    Str,
    Task b Str
    -> (Job, Input b) where b implements Encoding
step0 = \job, name, run ->
    step = {
        name,
        dependencies: [],
        run: \_ ->
            run
            |> Task.map (\output -> Encode.toBytes output Rvn.compact)
            |> Task.mapErr (\err -> UserError err),
    }

    input = @Input { dependsOn: step.name }
    (CiInternal.addStep job step, input)

step1 : Job,
    Str,
    (a -> Task b Str),
    Input a
    -> (Job, Input b) where a implements Decoding, b implements Encoding
step1 = \job, name, run, @Input { dependsOn } ->
    runSerialized = \inputBytes ->
        when Decode.fromBytes inputBytes Rvn.compact is
            Ok arg ->
                run arg
                |> Task.map (\output -> Encode.toBytes output Rvn.compact)
                |> Task.mapErr (\err -> UserError err)

            Err _ ->
                Task.err InputDecodingFailed

    step = {
        name,
        dependencies: [dependsOn],
        run: runSerialized,
    }

    input = @Input { dependsOn: step.name }
    (CiInternal.addStep job step, input)

step2 : Job,
    Str,
    (a, b -> Task c Str),
    Input a,
    Input b
    -> (Job, Input c) where a implements Decoding, b implements Decoding, c implements Encoding
step2 = \job, name, run, @Input input1, @Input input2 ->
    runSerialized = \inputBytes ->
        { result, rest } = Decode.fromBytesPartial inputBytes Rvn.compact
        arg1 <-
            result
            |> Result.mapErr (\_ -> InputDecodingFailed)
            |> Task.fromResult
            |> Task.await

        result2 = Decode.fromBytes rest Rvn.compact
        arg2 <-
            result2
            |> Result.mapErr (\_ -> InputDecodingFailed)
            |> Task.fromResult
            |> Task.await

        run arg1 arg2
        |> Task.map (\output -> Encode.toBytes output Rvn.compact)
        |> Task.mapErr (\err -> UserError err)

    step = {
        name,
        dependencies: [input1.dependsOn, input2.dependsOn],
        run: runSerialized,
    }

    input = @Input { dependsOn: step.name }
    (CiInternal.addStep job step, input)

setupGit : Task { gitRoot : Dir, branch : Str, hash : Str, author : Str } Str
setupGit = Task.err "setupGit unimplemented"

main : List Hook -> Task {} I32
main = \hooks ->
    args <- Arg.list |> Task.await

    { githubActions, local } =
        List.walk
            hooks
            { githubActions: [], local: [] }
            (\state, hook ->
                when Hook.unwrap hook is
                    { trigger: GithubActions x, job } ->
                        { state & githubActions: List.append state.githubActions (x, job) }

                    { trigger: Local x, job } ->
                        { state & local: List.append state.local (x, job) }
            )

    when List.dropFirst args 1 is
        ["local", .. as rest] if !(List.isEmpty local) ->
            Runner.LocalInternal.run local rest

        ["github-actions", .. as rest] if !(List.isEmpty githubActions) ->
            Runner.GithubActionsInternal.run githubActions rest

        _ ->
            {} <- Stdout.line "Usage: roc-ci <runner> [params]" |> Task.await
            {} <- Stdout.line "" |> Task.await

            if List.isEmpty hooks then
                Stdout.line "Add some hooks to run this pipeline!"
            else
                printIf = \line, list, andThen ->
                    if List.isEmpty list then
                        Task.ok {} |> Task.await andThen
                    else
                        Stdout.line line |> Task.await andThen

                {} <- "runners:" |> Stdout.line |> Task.await
                {} <- "  local             Run jobs on this machine" |> printIf local
                {} <- "  github-actions    Generate github actions files" |> printIf githubActions
                Task.ok {}
