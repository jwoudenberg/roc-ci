interface Hook
    exposes [
        Hook,
        unwrap,
    ]
    imports [
        GithubActionsInternal,
        LocalInternal,
        CiInternal.{ Job },
    ]

HookContents : (
    [
        GithubActions GithubActionsInternal.Hook,
        Local LocalInternal.Hook,
    ],
    Job,
)

Hook := HookContents

unwrap : Hook -> HookContents
unwrap = \@Hook options -> options
