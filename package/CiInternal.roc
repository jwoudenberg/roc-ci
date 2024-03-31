interface CiInternal
    exposes [
        Job,
        addStep,
        done,
        jobErrors,
        jobSteps,
        Step,
        StepError,
    ]
    imports [pf.Task.{ Task }]

Job := { steps : List Step, errors : List Str }

Step : {
    name : Str,
    dependencies : List Str,
    run : List U8 -> Task (List U8) StepError,
}

StepError : [
    MissingDependency Str,
    InputDecodingFailed,
    UserError Str,
    ConstructionErrors (List Str),
]

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

jobErrors : Job -> List Str
jobErrors = \@Job { errors } -> errors

jobSteps : Job -> List Step
jobSteps = \@Job { steps } -> steps
