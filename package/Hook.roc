module [
    Hook,
    wrap,
    unwrap,
]

import Runner.GithubActionsInternal
import Runner.LocalInternal
import CiInternal exposing [Job]

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
