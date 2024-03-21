interface Ci
    exposes [
        Task,
        Job,
        File,
        Dir,

        # Job definition
        Input,
        done,
        step0,
        step1,
        step2,

        # Setup steps
        setupGit,
    ]
    imports []

# TODO: Figure out how to pull File/Dir values out of arbitrary input structures

Task val := {}

Step : {
    name : Str,
    dependencies : List Str,
    run : List U8 -> Task (List U8),
}

Job := List [Step Step, ConstructionError Str]

addStep : Job, Step -> Job
addStep = \@Job steps, step ->
    nameAlreadyUsed = List.any
        steps
        (\otherStep ->
            when otherStep is
                ConstructionError _ -> Bool.false
                Step { name } -> name == step.name
        )
    if nameAlreadyUsed then
        @Job (List.append steps (ConstructionError "Duplicate step name: $(step.name)"))
    else
        @Job (List.append steps (Step step))

Input val := {
    dependsOn : Str,
}

File := {}

Dir := {}

done : Job
done = @Job []

step0 :
    Str,
    Task b,
    (Input b -> Job)
    -> Job
step0 = \name, _run, next ->
    step = {
        name,
        dependencies: [],
        run: crash "unimplemented",
    }

    next (@Input { dependsOn: step.name })
    |> addStep step

step1 :
    Str,
    (a -> Task b),
    Input a,
    (Input b -> Job)
    -> Job
step1 = \name, _run, @Input { dependsOn }, next ->
    step = {
        name,
        dependencies: [dependsOn],
        run: crash "unimplemented",
    }

    next (@Input { dependsOn: step.name })
    |> addStep step

step2 :
    Str,
    (a, b -> Task c),
    Input a,
    Input b,
    (Input c -> Job)
    -> Job
step2 = \name, _run, @Input input1, @Input input2, next ->
    step = {
        name,
        dependencies: [input1.dependsOn, input2.dependsOn],
        run: crash "unimplemented",
    }

    next (@Input { dependsOn: step.name })
    |> addStep step
setupGit : Task { gitRoot : Dir }
