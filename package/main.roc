app [main] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br",
    rvn: "../../rvn/package/main.roc",
}

import pf.Task exposing [Task]
import Ci exposing [File, Dir]
import Runner.Local
import Runner.GithubActions

main = Ci.main [
    Runner.Local.onCliCommand "test" buildAndTest,
    Runner.GithubActions.onPullRequest [] buildAndTest,
]

buildAndTest : Ci.Job
buildAndTest =
    repoDetails <- Ci.step0 "setup git" Ci.setupGit
    binary <- Ci.step1 "build binary" buildBinary repoDetails
    testsPass <- Ci.step1 "run tests" runTests binary
    _ <- Ci.step2 "release" release binary testsPass
    Ci.done

buildBinary : { gitRoot : Dir }* -> Task File Str

runTests : File -> Task {} Str

release : File, {} -> Task {} Str
