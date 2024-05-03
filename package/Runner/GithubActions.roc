module [
    onPullRequest,
    onRelease,
]

import CiInternal exposing [Job]
import Hook exposing [Hook]
import Runner.GithubActionsInternal exposing [PullRequestTriggers, ReleaseTriggers]

onPullRequest : List PullRequestTriggers, Job -> Hook
onPullRequest = \triggers, job ->
    Hook.wrap { job, trigger: GithubActions (PullRequest triggers) }

onRelease : List ReleaseTriggers, Job -> Hook
onRelease = \triggers, job ->
    Hook.wrap { job, trigger: GithubActions (Release triggers) }
