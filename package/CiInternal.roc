interface CiInternal
    exposes [
        Job,
        addStep,
        done,
        spec,
        JobSpec,
        Step,
    ]
    imports [pf.Task.{ Task }]

Job := JobSpec

JobSpec : {
    steps : List Step,
    runFns : List (List U8 -> Task (List U8) [UserError Str, InputDecodingFailed]),
    errors : List Str,
}

Step : {
    name : Str,
    dependencies : List Str,
}

addStep :
    Job,
    Step,
    (List U8 -> Task (List U8) [UserError Str, InputDecodingFailed])
    -> Job
addStep = \@Job { steps, runFns, errors }, { name, dependencies }, run ->
    nameAlreadyUsed = List.any steps (\otherStep -> name == otherStep.name)
    if nameAlreadyUsed then
        @Job {
            steps,
            runFns,
            errors: List.append errors "Duplicate step name: $(name)",
        }
    else
        @Job {
            steps: List.append steps { name, dependencies },
            runFns: List.append runFns run,
            errors,
        }

done : Job
done = @Job { steps: [], errors: [], runFns: [] }

spec : Job -> JobSpec
spec = \@Job job -> job
