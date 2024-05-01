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

onPullRequest : List PullRequestTriggers, (Job -> Job) -> Hook
onPullRequest = \triggers, mkJob ->
    Hook.wrap { job: mkJob CiInternal.empty, trigger: GithubActions (PullRequest triggers) }

onRelease : List ReleaseTriggers, (Job -> Job) -> Hook
onRelease = \triggers, mkJob ->
    Hook.wrap { job: mkJob CiInternal.empty, trigger: GithubActions (Release triggers) }
