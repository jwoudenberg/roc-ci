module [
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

import pf.Task exposing [Task]
import pf.Arg
import pf.Stdout
import rvn.Rvn
import CiInternal
import Hook
import Runner.LocalInternal
import Runner.GithubActionsInternal

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
        arg1 =
            result
                |> Result.mapErr (\_ -> InputDecodingFailed)
                |> Task.fromResult!

        result2 = Decode.fromBytes rest Rvn.compact
        arg2 =
            result2
                |> Result.mapErr (\_ -> InputDecodingFailed)
                |> Task.fromResult!

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
setupGit = Task.err "setupGit unimplemented"

printIfExists : Str, List a -> Task {} _
printIfExists = \line, list ->
    if List.isEmpty list then
        Task.ok! {}
    else
        Stdout.line! line

main : List Hook -> Task {} _
main = \hooks ->
    args = Arg.list!

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
            Stdout.line! "Usage: roc-ci <runner> [params]"
            Stdout.line! ""

            if List.isEmpty hooks then
                Stdout.line "Add some hooks to run this pipeline!"
            else
                Stdout.line! "runners:"
                printIfExists! "  local             Run jobs on this machine" local
                printIfExists "  github-actions    Generate github actions files" githubActions
