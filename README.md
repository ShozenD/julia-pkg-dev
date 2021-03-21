# A Basic Guide for Package Development in Julia
**Author:** Shozen Dan, Stat&CS Undergrad @ Keio University (JPN) & UC Davis (USA)

**Last Update**: 2019/03/21

## Introduction
This tutorial assumes that the reader has some knowledge of using Julia to write programs. This tutorial aims to provide an one-stop tutorial for basic package development. 

## 1. Initiating a Project

### 1.1 Starting from scratch
If you're developing a package from scratch, the easiest way to initiate a project in Julia is enter the Pkg REPL mode by pressing ``]`` and using the following command.
```{julia}
(v1.5) pkg> generate PackageName
```
This will create a directory called ``PackageName`` which contains the ``src`` subdirectory and ``Project.toml`` file. The ``src`` will house the source code while ``Project.toml`` is used to manage the dependencies. 

Before addning new dependencies to your package, first activate the environment of package by entering the Pkg REPL mode again and entering the following:
```{julia}
(v1.5) pkg> activate PackageName
```

To add a dependency, use ``add``:
```{julia}
(PackageName) pkg> add LinearAlgebra
```
If it is not already present, this command will have Julia create a ``Manifest.toml`` file that contains all dependency information such as package names, UUID, and interdependencies.

To remove a dependency, use ``rm``:
```{julia}
(PackageName) pkg> rm LinearAlgebra
```

To update a dependency, use ``update``:
```{julia}
(PackageName) pkg> update LinearAlgebra
```
### 1.2 If you already have some code
If you already have a directory with Julia code that you have developed, you can ``activate`` the environment and use the ``add`` command to add a new or existent dependency. If ``Project.toml`` and/or ``Manifest.toml`` is not present within your project directory, Julia will automatically create the pair for you.
```{julia}
(v1.5) pkg> activate PackageName
(PackageName) pkg> add LinearAlgebra
```

## 2. Continuous Integration and Develpment (CI/CD)
While it is not a requirement, many Julia packages implements CI. For small packaages, the work required to implement CI outweights its benefits. But, when packages become large and entangled, CI provide an automated way to build and test your package's functionalities. CI can also reassure potential users that your package is reliable and devoid of major bugs.

The following table shows the pricing plans for 3 commonly used CI/CD services. For independent researchers or developers, GitHub workflows is a good choice because its free tier offers the most run time. But for large scale projects run by a team, it may be worth while to investigate the benefits paid tiers and other services such as GitLab and Travis CI has to offer.
<table>
  <tr>
    <th></th>
    <th>GitHub Actions</th>
    <th>GitLab CI/CD</th>
    <th>Travis CI</th>
  </tr>  
  <tr>
    <td><b>Free Tier</td>
    <td><li>2000 min/month</td>
    <td><li>400 min/month</td>
    <td><li>10000 credits max</td>
  </tr>  
  <tr>
    <td><b>Cheapest</td>
    <td>
      <li> $4 per user/month
      <li> 3000 min/month
    </td>
    <td>
      <li> $19 per user/month
      <li> 10000 min/month
    </td>
    <td>
      <li> $69/month
      <li> Adjustable Credits
    </td>
  </tr>  
  <tr>
  </tr>  
</table>

### GitHub Actions
If your code is on GitHub, the simplest option is to use [GitHub Actions](https://github.com/features/actions). If you want detailed information on how GitHub Actions work, please visit the website. Otherwise the following steps should suffice.

#### Step 1
Create a `test` directory under your root directory and add the file `runtest.jl`. Navigate into the `test` directory and add your test dependencies with REPL as such:
```{julia}
<pkg> activate ./test
<pkg> add Test
<pkg> add LinearAlgebra # e.g. I'm using LinearAlgebra to test my package
```
This will create a separate `Project.toml` and `Manifest.toml` inside the `test` directory. Make sure to add every package that you are importing in `runtest.jl` file using REPL, otherwise CI will fail. 

```{julia}
using
    Test,
    <PackageName>,
    LinearAlgebra

@test somefunction(1,1)
@test somefunction2(2,3)

@testset "Test norm" begin
  @test norm(somefunction(5,8) - somefunction(8,5)) == 0 # I am using the norm function from the LinearAlgebra package.
end
```
After you are done writing tests, its good practice to run `runtest.jl` locally before pushing it to your repository as it will help you find bugs prior CI, saveing you time and credits. 

#### Step 2
In you root directory create a directory named `.github/workflows`. Within that directory, include the following `CI.yml`. 
```{yaml}
# Generated using the wonderful PkgTemplates.jl and altered slightly 
name: CI
on:
  push:
    paths: # Specifying which files to run CI/CD for
    - src/* 
    - test/runtests.jl
    - Manifest.toml
    - Project.toml
  pull_request:
    paths:
    - src/* 
    - test/runtests.jl
    - Manifest.toml
    - Project.toml
jobs:
  test:
    name: Julia ${{ matrix.version }} - ${{ matrix.os }} - ${{ matrix.arch }} - ${{ github.event_name }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        version:
          - '1.0'
          - '1.5'
          - 'nightly'
        os:
          - ubuntu-latest
          - macOS-latest
        arch:
          - x64
    steps:
      - uses: actions/checkout@v2
      - uses: julia-actions/setup-julia@v1
        with:
          version: ${{ matrix.version }}
          arch: ${{ matrix.arch }}
      - uses: actions/cache@v1
        env:
          cache-name: cache-artifacts
        with:
          path: ~/.julia/artifacts
          key: ${{ runner.os }}-test-${{ env.cache-name }}-${{ hashFiles('**/Project.toml') }}
          restore-keys: |
            ${{ runner.os }}-test-${{ env.cache-name }}-
            ${{ runner.os }}-test-
            ${{ runner.os }}-
      - uses: julia-actions/julia-buildpkg@v1
      - uses: julia-actions/julia-runtest@v1
      - uses: julia-actions/julia-processcoverage@v1
      - uses: codecov/codecov-action@v1 
        with:
          file: lcov.info
```
`push` and `pull_request` events means that your CI/CD pipeline will only run on a push or pull request. Although its not covered here, you can specify branches and tags as well.

Generally, you don't want to run CI/CD for every single change you make (e.g. changes to README.md file). Under `paths` you can specify which files you want to run CI/CD for. You can also use `paths-ignore` which will only run CI/CD if the altered code belongs to a file not specified under it. 

You can specify which version of Julia you want to test and what machine you want to use under `matrix`. Here we test Julia 1.0, 1.5, and nightly(latest unstable ver.) on macOS and ubuntu machines. When you are testing your CI/CD pipeline, it may be prudent to comment some of these out to save time.

#### Step 3
The final step is to add code coverage (if you want). Code coverage is how many lines/arcs/blocks of your code is executed while performing the automated test that you have setup in your CI/CD process. While it is not a requirement, good code coverage statistics can give users insights about how well your package is tested (i.e. how reliable it is). There are numerous code coverage services you can choose from but the `CI.yml` file above assumes you are using [CodeCov](https://about.codecov.io/). Simply go to their website and follow the steps to link your package to CodeCov. 

Now, when you push your code to GitHub, it will automatically start testing you package. Don't forget to add the workflow status badge and the code coverage badge so that people can see that your package passes all the tests and how much code is covered in the process.

GitHub workflow status badge: `https://docs.github.com/en/actions/managing-workflow-runs/adding-a-workflow-status-badge`

CodeCov badge: `https://codecov.io/gh/<your-organisation>/<your-project>/settings/badge`

### GitLab CI/CD
If you are managing you code on GitLab, you can use GitLab CI/CD. After finishing **Step 1** from above, create a `.gitlab-ci.yml` file under you root directory and add the following:
```{yaml}
.check: # Specifying files to run CI/CD
  script: echo "Running CI/CD only if specific files are changed"
  rules:
  - if: $CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH
    changes:
    - src/*
    - test/runtest.jl
    - Project.toml
    - Manifest.toml 
    when: manual

# Generated using PkgTemplate and altered to check specific files for changes
.script:
  script:
    - |
      julia --project=@. -e '
        using Pkg
        Pkg.build()
        Pkg.test(coverage=true)'
.coverage:
  coverage: /Test coverage (\d+\.\d+%)/
  after_script:
    - |
      julia -e '
        using Pkg
        Pkg.add("Coverage")
        using Coverage
        c, t = get_summary(process_folder())
        using Printf
        @printf "Test coverage %.2f%%\n" 100c / t'

Julia 1.0:
  image: julia:1.0
  extends:
    - .check
    - .script
    - .coverage

Julia 1.5:
  image: julia:1.5
  extends:
    - .check
    - .script
    - .coverage
``` 
As in the case of GitHub Actions, the code under `.check` will ensure that the CI/CD is not run for anything but a push or pull request to one of the specified files. 

## 3. Managing Julia Code on GitLab and GitHub
### Transfering Code from GitLab to GitHub
1. Create an [new repository](https://docs.github.com/en/github/getting-started-with-github/create-a-repo) on GitHub.

2. Navigate to your project dirrectory and use the following command to add your code to the newly created GitHub repository.
```
git remote add github https://yourLogin@github.com/yourLogin/yourRepoName.git
```

3. Use the usual commands to `add` and `commit` new changes. When you want to push the code to GitLab, use ``git push``. When you want to push the code to GitHub use 
```
git push --mirror github
```

## 4. Registering your Package
Currently, there are 2 ways of registering your package.
1. Via the [Web Interface](https://juliahub.com). 
2. Via the GitHub App. 

Documentation for both methods can be found @ the [Julia Registrator](https://github.com/JuliaRegistries/Registrator.jl). The following tutorial is copied from the Julia Registrator GitHub page for registering the package via GitHub.

1. Install the Julia Registrator: [![install](https://img.shields.io/badge/-install%20app-blue.svg)](https://github.com/apps/juliateam-registrator/installations/new)
2. Set the (Julia)Project.toml version field in your repository to your new desired version.
Comment `@JuliaRegistrator register` on the commit/branch you want to register (e.g. like [here](https://github.com/JuliaRegistries/Registrator.jl/issues/61#issuecomment-483486641) or [here](https://github.com/chakravala/Grassmann.jl/commit/3c3a92610ebc8885619f561fe988b0d985852fce#commitcomment-33233149)).
3. If something is incorrect, adjust, and redo step 
4. If the automatic tests pass, but a moderator makes suggestions (e.g., manually updating your (Julia)Project.toml to include a [compat] section with version requirements for dependancies), then incorporate suggestions as you see fit into a new commit, and redo step 2 for the new commit. You don't need to do anything to close out the old request.
5. Finally, either rely on the TagBot GitHub Action to tag and make a github release or alternatively tag the release manually.

### Extra. Creating Code Documentation for Julia Packages
1. Install `Documentor.jl`

2. Follow the [tutorial](https://juliadocs.github.io/Documenter.jl/stable/man/guide/) for `Documentor.jl`