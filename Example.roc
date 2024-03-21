interface Example
    exposes [job]
    imports [Ci.{ Task, File, Dir }]

job : Ci.Job
job =
    repoDetails <- Ci.step0 "setup git" Ci.setupGit

    binary <- Ci.step1 "build binary" buildBinary repoDetails

    _ <- Ci.step1 "run tests" runTests binary

    Ci.done

buildBinary : { gitRoot : Dir } -> Task File

runTests : File -> Task {}
