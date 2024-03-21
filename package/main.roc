app "roc-ci"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br",
        rvn: "../../rvn/package/main.roc",
    }
    imports [pf.Task, rvn.Rvn, Example]
    provides [main] to pf

main =
    _ = Example.job
    crash "UNIMPLEMENTED"
