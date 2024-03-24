interface Runner.GithubActions
    exposes [
        onPullRequest,
        onRelease,
    ]
    imports [
        CiInternal.{ Job },
        Hook.{ Hook },
        Runner.GithubActionsInternal.{ PullRequestTriggers, ReleaseTriggers },
    ]

onPullRequest : List PullRequestTriggers, Job -> Hook
onPullRequest = \triggers, job ->
    Hook.wrap { job, trigger: GithubActions (PullRequest triggers) }

onRelease : List ReleaseTriggers, Job -> Hook
onRelease = \triggers, job ->
    Hook.wrap { job, trigger: GithubActions (Release triggers) }
