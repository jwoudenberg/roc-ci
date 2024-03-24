interface Hook
    exposes [
        Hook,
        wrap,
        unwrap,
    ]
    imports [
        Runner.GithubActionsInternal,
        Runner.LocalInternal,
        CiInternal.{ Job },
    ]

HookContents : {
    trigger : [
        GithubActions Runner.GithubActionsInternal.Hook,
        Local Runner.LocalInternal.Hook,
    ],
    job : Job,
}

Hook := HookContents

wrap : HookContents -> Hook
wrap = \options -> @Hook options

unwrap : Hook -> HookContents
unwrap = \@Hook options -> options
