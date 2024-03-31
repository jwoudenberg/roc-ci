interface CiTask
    exposes [
        Task,
        ok,
        err,
        forever,
        await,
        attempt,
        loop,
        onErr,
        map,
        mapErr,
        fromResult,
        batch,
        seq,
        forEach,
        stdoutLine,
        argList,
        toPlatformTask,
    ]
    imports [
        pf.Task,
        pf.Arg,
        pf.Stdout,
    ]

Task val err := Task.Task val err

ok : a -> Task a *
ok = \val -> @Task (Task.ok val)

err : a -> Task * a
err = \val -> @Task (Task.err val)

forever : Task a err -> Task * err

await : Task a err, (a -> Task b err) -> Task b err
await = \@Task task, fn ->
    Task.await
        task
        (\a ->
            (@Task b) = fn a
            b
        )
    |> @Task

attempt : Task a b, (Result a b -> Task c d) -> Task c d

loop :
    state,
    (state
    -> Task
        [
            Step state,
            Done done,
        ]
        err)
    -> Task done err

onErr : Task a b, (b -> Task a c) -> Task a c

map : Task a c, (a -> b) -> Task b c

mapErr : Task c a, (a -> b) -> Task c b

fromResult : Result a b -> Task a b

batch : Task a c, Task (a -> b) c -> Task b c

seq : List (Task ok err) -> Task (List ok) err

forEach : List a, (a -> Task {} b) -> Task {} b

stdoutLine : Str -> Task {} *
stdoutLine = \line -> @Task (Stdout.line line)

argList : Task (List Str) *
argList = @Task Arg.list

toPlatformTask : Task val err -> Task.Task val err
toPlatformTask = \@Task task -> task
