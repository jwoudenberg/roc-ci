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

onRelease : List ReleaseTriggers, Job -> Hook
