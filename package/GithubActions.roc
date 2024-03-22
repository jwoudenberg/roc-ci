interface GithubActions
    exposes [
        # API
        onPullRequest,
        onRelease,

        # Internals
        run,
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

onPullRequest : List PullRequestTriggers, Job -> (Hook *, Job)

ReleaseTriggers : [
    Published,
    Unpublished,
    Created,
    Edited,
    Deleted,
    Prereleased,
    Released,
]

onRelease : List ReleaseTriggers, Job -> (Hook *, Job)

Hook a : [PullRequest PullRequestTriggers, Release ReleaseTriggers]a

run : List (Hook *, Job), List Str -> Task {} *
