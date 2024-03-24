interface Ci
    exposes [
        Job,
        File,
        Dir,
        main,

        # Job definition
        Input,
        done,
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

done = CiInternal.done

Input val := {
    dependsOn : Str,
}

File := {} implements [Encoding, Decoding]

Dir := {} implements [Encoding, Decoding]

step0 : Str,
    Task b Str,
    (Input b -> Job)
    -> Job where b implements Encoding
step0 = \name, run, next ->
    step = {
        name,
        dependencies: [],
        run: \_ ->
            run
            |> Task.map (\output -> Encode.toBytes output Rvn.compact)
            |> Task.mapErr (\err -> UserError err),
    }

    next (@Input { dependsOn: step.name })
    |> CiInternal.addStep step

step1 : Str,
    (a -> Task b Str),
    Input a,
    (Input b -> Job)
    -> Job where a implements Decoding, b implements Encoding
step1 = \name, run, @Input { dependsOn }, next ->
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

    next (@Input { dependsOn: step.name })
    |> CiInternal.addStep step

step2 : Str,
    (a, b -> Task c Str),
    Input a,
    Input b,
    (Input c -> Job)
    -> Job where a implements Decoding, b implements Decoding, c implements Encoding
step2 = \name, run, @Input input1, @Input input2, next ->
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

    next (@Input { dependsOn: step.name })
    |> CiInternal.addStep step

setupGit : Task { gitRoot : Dir, branch : Str, hash : Str, author : Str } Str

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

    when args is
        ["local", .. as rest] -> Runner.LocalInternal.run local rest
        ["github-actions", .. as rest] -> Runner.GithubActionsInternal.run githubActions rest
        _ ->
            Stdout.line
                """
                roc-ci <runner>

                runner:
                    local             Run Job on this machine
                    github-actions    Generate github actions files
                """
