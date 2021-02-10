# A Basic Guide for Package Development in Julia
**Author:** Shozen Dan, Stat&CS Undergrad @ Keio University (JPN) & UC Davis (USA)

**Last Update**: 2019/02/10

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
While it is not a requirement, many Julia packages implements continuous integration. In my opinion, the work required to implement continuous integration outweights its benefits. However, when packages become large and entangled, CI can provide a consitent and automated way to build, package, and test your package's functionalities. Implementing CI can also reassure potential users that your package is reliable and devoid of major bugs. 

### 2.1 Travis CI
A CI platform that is common among Julia developers is [Travis CI](https://travis-ci.org/). You will need to link your GitLab or GitHub accouunt to Travis in order to use it's services. For official documentation on how to use Travis CI refer to the following documents: [GitHub Docs](https://docs.travis-ci.com/user/tutorial/#to-get-started-with-travis-ci-using-github), [GitLab Docs](https://docs.travis-ci.com/user/tutorial/#to-get-started-with-travis-ci-using-gitlab). However, the following implementation tutorial should be sufficient for most applications.

### Step 1
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

after_success:
  - julia -e 'using Pkg; Pkg.add("Coverage"); using Coverage; Codecov.submit(process_folder())'
  - julia -e 'using Pkg; Pkg.add("Coverage"); using Coverage; Coveralls.submit(process_folder())'
```
### Step 2
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
*Working on it...*

### 3. Code Coverage
*Working on it...*

### 4. Managing Julia Code on GitLab and GitHub
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
