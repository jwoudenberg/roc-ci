app "roc-ci"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br",
        rvn: "../../rvn/package/main.roc",
    }
    imports [
        pf.Task.{ Task },
        pf.Arg.{ Parser },
        pf.Stdout,
        rvn.Rvn,
        Example,
        Local,
        GithubActions,
    ]
    provides [main] to pf

main : Task {} I32
main =
    args <- Arg.list |> Task.await

    # Job is currently a module in this project. The plan is for this ci
    # project to turn into a platform, and then the job file will be a Roc
    # application using that platform.
    jobs = Example.jobs

    when args is
        ["local", .. as rest] -> Local.run jobs rest
        ["gh-actions", .. as rest] -> GithubActions.run jobs rest
        _ ->
            Stdout.line
                """
                roc-ci <runner>

                runner:
                    local             Run Job on this machine
                    github-actions    Generate github actions files
                """
