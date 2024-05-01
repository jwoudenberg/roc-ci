app "roc-ci"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br",
        rvn: "../../rvn/package/main.roc",
    }
    imports [
        pf.Task.{ Task },
        pf.Stdout,
        pf.Arg,
        rvn.Rvn,
        Ci.{ File, Dir },
        Runner.Local,
        Runner.GithubActions,
    ]
    provides [main] to pf

main = Ci.main [
    Runner.Local.onCliCommand "test" buildAndTest,
    Runner.GithubActions.onPullRequest [] buildAndTest,
]

buildAndTest : Ci.Job -> Ci.Job
buildAndTest = \job0 ->
    (job1, repoDetails) = Ci.step0 job0 "setup git" Ci.setupGit
    (job2, binary) = Ci.step1 job1 "build binary" buildBinary repoDetails
    (job3, testsPass) = Ci.step1 job2 "run tests" runTests binary
    (job4, _) = Ci.step2 job3 "release" release binary testsPass
    job3

buildBinary : { gitRoot : Dir }* -> Task File Str

runTests : File -> Task {} Str

release : File, {} -> Task {} Str
