interface Example
    exposes [jobs]
    imports [
        pf.Task.{ Task },
        Ci.{ File, Dir },
        Local,
        GithubActions,
    ]

jobs = [
    Local.onCliCommand "test" buildAndTest,
    GithubActions.onPullRequest [] buildAndTest,

]

buildAndTest : Ci.Job
buildAndTest =
    repoDetails <- Ci.step0 "setup git" Ci.setupGit
    binary <- Ci.step1 "build binary" buildBinary repoDetails
    testsPass <- Ci.step1 "run tests" runTests binary
    _ <- Ci.step2 "release" release binary testsPass
    Ci.done

buildBinary : { gitRoot : Dir }* -> Task File Str

runTests : File -> Task [TestsPass] Str

release : File, [TestsPass] -> Task {} Str
