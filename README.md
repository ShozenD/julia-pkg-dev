# A Basic Guide for Package Development in Julia
**Author:** Shozen Dan, Stat&CS Undergrad @ Keio University (JPN) & UC Davis (USA)

**Last Update**: 2019/02/12

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

## 2. Continuous Integration (CI)
While it is not a requirement, many Julia packages implements continuous integration. In my opinion, for small and simple packaages, the work required to implement continuous integration outweights its benefits. However, when packages become large and entangled, CI can provide a consitent and automated way to build, package, and test your package's functionalities. Implementing CI can also reassure potential users that your package is reliable and devoid of major bugs.

There are many CI services available. You may have heard of [Travis CI](https://travis-ci.org/) and [AppVeyor](https://www.appveyor.com/) as they are well used among Julia developers. However most CI services have a limited number of free credits that you can use thus they are not sustainable if you are an independent developer looking to test your open-source package. 

### GitHub Actions
If you are keeping your code on GitHub, I think the simplest option is to use [GitHub Actions](https://github.com/features/actions). Its fast and you get 2,000 credits/month (equivalent to about 65 min per day) for free, so as long as you don't run a test for every small change, its more than enough to work with. If you want detailed information on how GitHub Actions work, please visit the website. Otherwise the following steps should suffice.

#### Step 1
In you GitHub repository create a directory named `.github/workflows`. Within that directory, include the following `CI.yml`. 
```{yaml}
# Generated using the wonderful PkgTemplates.jl
name: CI
on:
  - push
  - pull_request
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
### Step 2
Next, you will need to create a `test` directory under your root directory and add the file `runtest.jl`. You will also need to use the REPL to add your test dependencies.
```{julia}
<pkg> activate ./test
<pkg> add Test
<pkg> add LinearAlgebra # e.g. I'm using LinearAlgebra to test my package
```
This will create a separate `Project.toml` and `Manifest.toml` inside the `test` directory that you have created. Make sure you add every package that you are importing within the following `runtest.jl` file, otherwise the CI pipeline will fail. 

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
In my opinion, its always a good idea to run `runtest.jl` locally, before pushing it to your repository because it often saves time and GitHub Action credits. 

### Step 3
The final step is to add code coverage (if you want). Code coverage is how many lines/arcs/blocks of your code is executed while performing the automated test that you have setup in your CI/CD process. While it is not a requirement, good code coverage statistics can give users insights about how well your package is tested (i.e. how reliable it is). There are numerous code coverage services you can choose from but the `CI.yml` file above assumes you are using [CodeCov](https://about.codecov.io/). Simply go to their website and follow the steps to link your package to CodeCov. 

Now, when you push your code to GitHub, it will automatically start testing you package. Don't forget to add the workflow status badge and the code coverage badge so that people can see that your package passes all the tests and how much code is covered in the process.

GitHub workflow status badge: https://docs.github.com/en/actions/managing-workflow-runs/adding-a-workflow-status-badge

CodeCov badge: `https://codecov.io/gh/<your-organisation>/<your-project>/settings/badge`

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