interface GithubActions
    exposes [
        onPullRequest,
        onRelease,
    ]
    imports [
        CiInternal.{ Job },
        Hook.{ Hook },
        GithubActionsInternal.{ PullRequestTriggers, ReleaseTriggers },
    ]

onPullRequest : List PullRequestTriggers, Job -> Hook
onPullRequest = \triggers, job ->
    Hook.wrap { job, trigger: GithubActions (PullRequest triggers) }

onRelease : List ReleaseTriggers, Job -> Hook
onRelease = \triggers, job ->
    Hook.wrap { job, trigger: GithubActions (Release triggers) }
