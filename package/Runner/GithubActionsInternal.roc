module [
    run,
    Hook,
    PullRequestTriggers,
    ReleaseTriggers,
]

import pf.Task exposing [Task]
import CiInternal exposing [Job]

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

run : List (Hook, Job), List Str -> Task {} I32
