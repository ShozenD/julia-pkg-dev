# A Basic Guide for Package Development in Julia
**Author:** Shozen Dan, Stat&CS Undergrad @ Keio University (JPN) & UC Davis (USA)

**Last Update**: 2019/02/11

## Introduuction
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

### 2.1 Travis CI
A CI platform that is common among Julia developers is [Travis CI](https://travis-ci.org/). You will need to link your GitLab or GitHub accouunt to Travis in order to use it's services. For official documentation on how to use Travis CI refer to the following documents: [GitHub Docs](https://docs.travis-ci.com/user/tutorial/#to-get-started-with-travis-ci-using-github), [GitLab Docs](https://docs.travis-ci.com/user/tutorial/#to-get-started-with-travis-ci-using-gitlab). However, the following implementation tutorial should be sufficient for most applications.

#### Step 1
**After you have linked your GitHub or GitLab account to Travis** (Please check the official documentation as well), you will need to add a ``.travis.yml`` file in the root directory of your package (e.g. PackageName/.travis.yml). The following template should be good enough for most packages.
```{yaml}
language: julia

os:
  - osx
  - linux

julia:
  - 1.0
  - 1.4
  - 1.5
  - nightly

jobs:
  allow_failures:
    - julia: nightly

notifications:
  email: false
```
Note that under `after_success`, there are two lines that deal with `Codecov` and `Coveralls`. These are used to update code coverage which is discussed in section 3.

#### Step 2
Next, you will need to create a `test` directory under your root directory and add the file `runtest.jl`. Also make sure to install the `Test.jl` package and add it to the list of dependencits in `Project.toml` and `Manifest.toml` (This should be automatically done when you use the `add` command). 

Within ``Test.jl`` you can define tests for your functions. When Travis performs continuous integration, it will run these tests and report whether they were sucessful. This will also effect Code Coverage, which is discussed in the next section. 
```{julia}
using
    Test,
    PackageName,
    LinearAlgebra

@test somefunction(1,1)
@test somefunction2(2,3)
@test somefunction3(5,8)
```

### 2.2 AppVeyor
[AppVeyor](https://www.appveyor.com/) is another CI platform that is backed by the Windows Azure platform. I use Travis CI to test my package on MacOS and Linux platforms while I use AppVeyor to test my package's compatibility with Windows platforms. To use AppVeyor, create an account @ https://www.appveyor.com/ and link your repository to it. Then add a `.appveyor.yml` file in the root directory of your package. The following template should be good enough for most cases.
```{julia}
# Documentation: https://github.com/JuliaCI/Appveyor.jl
environment:
  matrix:
  - julia_version: 1.3
  - julia_version: 1.4
  - julia_version: 1.5
  - julia_version: nightly
platform:
  - x86
  - x64
matrix:
  allow_failures:
    - julia_version: nightly
branches:
  only:
    - master
    - /release-.*/
notifications:
  - provider: Email
    on_build_success: false
    on_build_failure: false
    on_build_status_changed: false
install:
  - ps: iex ((new-object net.webclient).DownloadString("https://raw.githubusercontent.com/JuliaCI/Appveyor.jl/version-1/bin/install.ps1"))
build_script:
  - echo "%JL_BUILD_SCRIPT%"
  - C:\julia\bin\julia -e "%JL_BUILD_SCRIPT%"
test_script:
  - echo "%JL_TEST_SCRIPT%"
  - C:\julia\bin\julia -e "%JL_TEST_SCRIPT%"
```

## 3. Code Coverage
Code coverage is how many lines/arcs/blocks of your code is executed while performing the automated test that you have setup in your CI/CD process. While it is not a requirement, good code coverage statistics can give users insights about how well your package is tested (i.e. how reliable it is). In this section I will introduce two code coverage platforms: `Codecov` and `Coverall`.

### 1. Codecov
[Codecov](https://about.codecov.io/) is a popular code coverage platform used in numerous Julia packagees. Using it is extremely simple: 
1. create an account @ `codecov.io` and link your GitHub/GitLab/Bitbucket repository.
2. Add the following line of code to the end of your `.travis.yml` file. 
```{yaml}
after_success:
  - julia -e 'using Pkg; Pkg.add("Coverage"); using Coverage; Codecov.submit(process_folder())'
```
OR you can add this to the end of your `.appveyor.yml` file.
```{yaml}
on_success:
  - echo "%JL_CODECOV_SCRIPT%"
  - C:\julia\bin\julia -e "%JL_CODECOV_SCRIPT%"
```

### 2. Coverall
[Coveralls](https://coveralls.io/) is another code coverage platform that you can use. The way that code coverage is displayed is slightly different so it is up to the developer to choose whether to use `Codecov` or `Coveralls`. Using `Coveralls` is also very simple:
1. Create an account @ `coveralls.io` and link your GitHub/GitLab/Bitbucket repository
2. Add the following line of code to the end of your `.travis.yml` file.
```{yaml}
after_success
  - julia -e 'using Pkg; Pkg.add("Coverage"); using Coverage; Coveralls.submit(process_folder())'
```

## 4. Managing Julia Code on GitLab and GitHub
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

### Extra. Creating Code Documentation for Julia Packages
1. Install `Documentor.jl`

2. Follow the [tutorial](https://juliadocs.github.io/Documenter.jl/stable/man/guide/) for `Documentor.jl`
