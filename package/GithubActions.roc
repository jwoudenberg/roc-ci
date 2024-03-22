interface GithubActions
    exposes [
        # API
        onPullRequest,
        onRelease,

        # Internals
        run,
        Hook,
    ]
    imports [
        pf.Task.{ Task },
        Job.{ Job },
    ]

PullRequestTriggers : [
    Assigned,
    Unassigned,
    Labeled,
    Unlabeled,
    Opened,
    Edited,
    Closed,
    Reopened,
    Synchronize,
    ConvertedToDraft,
    Locked,
    Unlocked,
    Enqueued,
    Dequeued,
    Milestoned,
    Demilestoned,
    ReadyForReview,
    ReviewRequested,
    ReviewRequestRemoved,
    AutoMergeEnabled,
    AutoMergeDisabled,
]

onPullRequest : List PullRequestTriggers, Job -> ([GithubActions Hook], Job)

ReleaseTriggers : [
    Published,
    Unpublished,
    Created,
    Edited,
    Deleted,
    Prereleased,
    Released,
]

onRelease : List ReleaseTriggers, Job -> ([GithubActions Hook], Job)

Hook : [
    PullRequest PullRequestTriggers,
    Release ReleaseTriggers,
]

run : List (Hook, Job), List Str -> Task {} *
