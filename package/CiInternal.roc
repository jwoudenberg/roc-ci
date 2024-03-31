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
    imports [CiTask.{ Task }]

Job : { steps : List Step, errors : List Str }

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
addStep = \{ steps, errors }, step ->
    nameAlreadyUsed = List.any steps (\{ name } -> name == step.name)
    if nameAlreadyUsed then
        {
            steps,
            errors: List.append errors "Duplicate step name: $(step.name)",
        }
    else
        {
            steps: List.append steps step,
            errors,
        }

done : Job
done = { steps: [], errors: [] }

jobErrors : Job -> List Str
jobErrors = \{ errors } -> errors

jobSteps : Job -> List Step
jobSteps = \{ steps } -> steps
