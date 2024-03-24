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

JobSpec : { steps : List Step, errors : List Str }

Step : {
    name : Str,
    dependencies : List Str,
    run : List U8 -> Task (List U8) [UserError Str, InputDecodingFailed],
}

addStep : Job, Step -> Job
addStep = \@Job { steps, errors }, step ->
    nameAlreadyUsed = List.any steps (\{ name } -> name == step.name)
    if nameAlreadyUsed then
        @Job {
            steps,
            errors: List.append errors "Duplicate step name: $(step.name)",
        }
    else
        @Job {
            steps: List.append steps step,
            errors,
        }

done : Job
done = @Job { steps: [], errors: [] }

spec : Job -> JobSpec
spec = \@Job job -> job
