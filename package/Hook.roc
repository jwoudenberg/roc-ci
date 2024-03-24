interface Hook
    exposes [
        Hook,
        wrap,
        unwrap,
    ]
    imports [
        GithubActionsInternal,
        LocalInternal,
        CiInternal.{ Job },
    ]

HookContents : {
    trigger : [
        GithubActions GithubActionsInternal.Hook,
        Local LocalInternal.Hook,
    ],
    job : Job,
}

Hook := HookContents

wrap : HookContents -> Hook
wrap = \options -> @Hook options

unwrap : Hook -> HookContents
unwrap = \@Hook options -> options
