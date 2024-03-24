interface Runner.GithubActionsInternal
    exposes [
        run,
        Hook,
        PullRequestTriggers,
        ReleaseTriggers,
    ]
    imports [
        pf.Task.{ Task },
        CiInternal.{ Job },
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

ReleaseTriggers : [
    Published,
    Unpublished,
    Created,
    Edited,
    Deleted,
    Prereleased,
    Released,
]

Hook : [
    PullRequest (List PullRequestTriggers),
    Release (List ReleaseTriggers),
]

run : List (Hook, Job), List Str -> Task {} *
