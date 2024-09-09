app [main] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.15.0/SlwdbJ-3GR7uBWQo6zlmYWNYOxnvo8r6YABXD-45UOw.tar.br",
    rvn: "https://github.com/jwoudenberg/rvn/releases/download/0.2.0/omuMnR9ZyK4n5MaBqi7Gg73-KS50UMs-1nTu165yxvM.tar.br",
}

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
