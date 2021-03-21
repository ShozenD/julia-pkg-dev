using PkgTemplates

t = Template(;
    user="ShozenD",
    dir="/Users/shozendan/Documents/",
    plugins=[
        Codecov(),
        AppVeyor(),
        GitHubActions(; linux=true, osx=true),
        GitLabCI(; coverage=true),
        Documenter{GitHubActions}()
    ]
)

t("JuliaPkgDev")
