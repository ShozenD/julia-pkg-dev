# A Basic Guide for Package Development in Julia
**Authors:**   
* Shozen Dan, Stat&CS Undergrad @ Keio University (JPN) & UC Davis (USA)
* Zeng Fung Liew, MS. Statistics @ UC Davis

**Last Update**: 2021/05/03

## Table of Contents
1. [Initiating a Project](#initialization)
2. [Continuous Integration and Development (CI/CD)](#ci)
3. [Managing Julia Code on GitLab and GitHub](#remote)
4. [Registering Your Package](#registration)
5. [Documentations](#docs)
6. [Version Tagging and Package Maintainance](#tags)
7. [Using CompatHelper.yml](#compathelper)

## Introduction
This tutorial assumes that the reader has some knowledge of using Julia to write programs. This tutorial aims to provide an one-stop tutorial for basic package development. 

## 1. Initiating a Project <a name="initialization"></a>
### 1.1 Starting from scratch
If you're developing a package from scratch, the easiest way to initiate a project in Julia is enter the Pkg REPL mode by pressing ``]`` and using the following command.
```julia
(@v1.x) pkg> generate PackageName
```
This will create a directory called ``PackageName`` which contains the ``src`` subdirectory and ``Project.toml`` file. The ``src`` will house the source code while ``Project.toml`` is used to manage the dependencies. 

Before addning new dependencies to your package, first activate the environment of package by entering the Pkg REPL mode again and entering the following:
```julia
(@v1.x) pkg> activate PackageName
```

To add a dependency, use ``add``:
```julia
(PackageName) pkg> add LinearAlgebra
```
If it is not already present, this command will have Julia create a ``Manifest.toml`` file that contains all dependency information such as package names, UUID, and interdependencies.

To remove a dependency, use ``rm``:
```julia
(PackageName) pkg> rm LinearAlgebra
```

To update a dependency, use ``update``:
```julia
(PackageName) pkg> update LinearAlgebra
```
**A note about the `Project.toml` file**: Everytime you add a dependency for your package development, it will be reflected on the `Project.toml` and the `Manifest.toml` files. For package development purposes, the convention is that the `Manifest.toml` file should not be commited into your Github repository, and therefore all the necessary information should be contained in the `Project.toml` file. By default, everytime a dependency is added into the project, its changes will be reflected on the `[deps]` section of the `Project.toml` file, but a `[compat]` section is also necessary if you want to get your package registered in the Julia Registries. For instructions on the `[compat]` section, head to [Step 7](#compathelper). Note that a `[compat]` section is not the most important thing if you're at the start of the package development, and hence this step can be temporarily skipped.

### 1.3 If you already have some code
If you already have a directory with Julia code that you have developed, you can ``activate`` the environment and use the ``add`` command to add a new or existent dependency. If ``Project.toml`` and/or ``Manifest.toml`` is not present within your project directory, Julia will automatically create the pair for you.
```julia
(v1.x) pkg> activate PackageName
(PackageName) pkg> add LinearAlgebra
```

## 2. Continuous Integration and Develpment (CI/CD) <a name="ci"></a>
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
    <td><b>Free Tier</b></td>
    <td><li>2000 min/month</li></td>
    <td><li>400 min/month</li></td>
    <td><li>10000 credits max</li></td>
  </tr>  
  <tr>
    <td><b>Cheapest</b></td>
    <td>
      <li> $4 per user/month </li>
      <li> 3000 min/month </li>
    </td>
    <td>
      <li> $19 per user/month </li>
      <li> 10000 min/month </li>
    </td>
    <td>
      <li> $69/month </li>
      <li> Adjustable Credits </li>
    </td>
  </tr> 
</table>

### GitHub Actions
If your code is on GitHub, the simplest option is to use [GitHub Actions](https://github.com/features/actions). If you want detailed information on how GitHub Actions work, please visit the website. Otherwise the following steps should suffice.

#### Step 1
Create a `test` directory under your root directory and add the file `runtest.jl`. Navigate into the `test` directory and add your test dependencies with REPL as such:
```julia
(@v1.x) pkg> activate ./test
(@v1.x) pkg> add Test
(@v1.x) pkg> add LinearAlgebra # e.g. Using LinearAlgebra to test my package
```
This will create a separate `Project.toml` and `Manifest.toml` inside the `test` directory. Make sure to add every package that you are importing in `runtest.jl` file using REPL, otherwise CI will fail. 

```julia
using
    Test,
    <PackageName>,
    LinearAlgebra

@test somefunction(1,1)
@test somefunction2(2,3)

@testset "Test norm" begin
  @test norm(somefunction(5,8) - somefunction(8,5)) == 0 # Using the norm function from LinearAlgebra
end
```
After you are done writing tests, its good practice to run `runtest.jl` locally before pushing it to your repository as it will help you find bugs prior CI, saveing you time and credits. 

#### Step 2
In you root directory create a directory named `.github/workflows`. Within that directory, include the following `CI.yml`. 
```yaml
{% raw %}
# Generated using the wonderful PkgTemplates.jl and altered slightly 
name: CI
on:
  push:
    paths: # Specifying which files to run CI/CD for
    - src/**
    - test/runtests.jl
    - Project.toml
  pull_request:
    paths:
    - src/**
    - test/runtests.jl
    - Project.toml
jobs:
  test:
    name: Julia ${{ matrix.version }} - ${{ matrix.os }} - ${{ matrix.arch }} - ${{ github.event_name }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        version:
          - '1.5'
          - '1.6'
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
{% endraw %}
```
`push` and `pull_request` events means that your CI/CD pipeline will only run on a push or pull request. Although its not covered here, you can specify branches and tags as well.

Generally, you don't want to run CI/CD for every single change you make (e.g. changes to README.md file). Under `paths` you can specify which files you want to run CI/CD for. You can also use `paths-ignore` which will only run CI/CD if the altered code belongs to a file not specified under it. 

You can specify which version of Julia you want to test and what machine you want to use under `matrix`. Here we test Julia 1.5, 1.6, and nightly(latest unstable ver.) on macOS and ubuntu machines. When you are testing your CI/CD pipeline, it may be prudent to comment some of these out to save time.

#### Step 3
The final step is to add code coverage (if you want). Code coverage is how many lines/arcs/blocks of your code is executed while performing the automated test that you have setup in your CI/CD process. While it is not a requirement, good code coverage statistics can give users insights about how well your package is tested (i.e. how reliable it is). There are numerous code coverage services you can choose from but the `CI.yml` file above assumes you are using [CodeCov](https://about.codecov.io/). Simply go to their website and follow the steps to link your package to CodeCov. 

Now, when you push your code to GitHub, it will automatically start testing you package. Don't forget to add the workflow status badge and the code coverage badge so that people can see that your package passes all the tests and how much code is covered in the process.

GitHub workflow status badge: `https://docs.github.com/en/actions/managing-workflow-runs/adding-a-workflow-status-badge`

CodeCov badge: `https://codecov.io/gh/<your-organisation>/<your-project>/settings/badge`

Note: Your CodeCov badge link can be directly obtained from the settings of the package's Codecov repository. Simply enter CodeCov, navigate to the package repository and click on Settings. Your CodeCov badge can be found under the **Badge** tab on the left.

Once this step is completed, one can move on directly to [Step 4: Registering your Package](#registration) and be done with the process of developing a software package in Julia. However, for the sake of long-term maintainability, it is strongly advised that one includes [documentations](#docs), [automated version tagging](#tags), and [automated compatability helper](#compathelper) in the package workflow.

### GitLab CI/CD
If you are managing you code on GitLab, you can use GitLab CI/CD. After finishing **Step 1** from above, create a `.gitlab-ci.yml` file under you root directory and add the following:
```yaml
.check: # Specifying files to run CI/CD
  script: echo "Running CI/CD only if specific files are changed"
  rules:
  - if: $CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH
    changes:
    - src/**
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

## 3. Managing Julia Code on GitLab and GitHub <a name="remote"></a>
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

## 4. Registering your Package <a name="registration"></a>
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

## 5. Documentations <a name="docs"></a>
In order for users to understand how to use your software package and have the work of future maintainers of your package cut out for them, it is important to add documentations for your package. The materials to cover in your documentation can range from package introduction and tutorials, to the documentation of each function in the package. Generally, all the documentations for your Julia package should be contained in the `docs/` directory. `Documenter.jl` and `DocumenterTools.jl` have built-in functions that help make this process run smoothly.

#### **Create `docs/` directory**
If a `docs/` directory is yet to be establish, import `DocumenterTools.jl` in the REPL to get things started.
```julia
julia> cd("path/to/package_repo/")
julia> using Pkg; Pkg.add("DocumenterTools")
julia> using DocumenterTools
julia> DocumenterTools.generate()
```

You should see that a `docs/` directory containing a `src/` folder, and `.gitignore`, `make.jl`, and `Project.toml` files. Here, the `Project.toml` file functions similarly to the one in the main `src/` directory in the package repository, the `src/` folder contains all the markdown files that needs to be generated into webpages, and the `make.jl` file is the key piece of this entire `docs/` directory as it contains the codes to generate the decumentation webpages corresponding to the `docs/src/` directory. Now, one has the liberty to design his/her own package's documentation, but here are some recommendations on what to tweak:  

#### **Configuring `make.jl`**  
Using the `DocumenterTools.generate()` function, the `make.jl` should contain 2 functions: `makedocs()` and `deploydocs()`. The `deploydocs()` function should be configured as follows:
```julia
deploydocs(
  repo = "github.com/<repo-owner-name>/<pkg-name.jl>.git"
)
```
As for the `makedocs()` function, most of the default parameter settings can be kept the way they are, but we recommend working with the `pages` parameter instead of the `modules` parameter for improved flexibility. In the end, the `makedocs()` function should look as follows:
```julia
makedocs(
    sitename = "<pkg-name>.jl",
    format = Documenter.HTML(),
    authors = "<author-name>",
    clean = true,
    pages = Any[
        "Page 1" => "page1.md",
        "Page 2" => Any[
            "Page 2.1" => "page21.md",
            "Page 2.2" => "page22.md"
        ]
    ]
)
```
To dive into the above code, items such as "Page 1" and "Page 2.1" will be included in the table of contents of your documentation webpage, while files such as `page1.md` and `page21.md` are the corresponding markdown files to generate these webpages.

*Tip:* To better organize the markdown folders in `docs/src/`, one can create directories within `docs/src/` to store and organize the files within. For example, one can create `docs/src/pg2_files/` and store `page21.md` and `page22.md`. This means that `page21.md` and `page22.md` in the above code should be changed to `pg2_files/page21.md` and `pg2_files/page22.md` respectively.

#### **Writing markdown files**
Markdown files are created and written in the `docs/src/` folder as mentioned in the previous section. Generally, markdown files have to be written from scratch, especially those that are for tutorial purposes, but `Documenter.jl` provides macros that make writing API documentations much easier. The following example to automatically document all the documentations in your Julia package.
<pre><code>
# Package API

```@index
Modules = [module1, module2, module3]
```

```@autodocs
Modules = [module1, module2, module3]
```
</code></pre>

Additionally, one can use the `@example` macro to write examples/tutorials on the respective package. For example:
<pre><code>
# Package Tutorial

```@example
using MyPkg
foo()
```
</code></pre>

For more information on `Documenter.jl`'s macro usage, visit their documentation [here](https://juliadocs.github.io/Documenter.jl/stable/man/syntax/).

#### **Set up Github workflow using `Documenter.yml`**
Once the documentation is done, a Github workflow has to be set up to build the documentation pages. Navigate to `.github/workflows/` and create the file `Documenter.yml` and add the following lines into that file:
```yaml
name: Documenter
on:
  push:
    branches:
      - master
    tags: '*'
  pull_request:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: julia-actions/setup-julia@latest
        with:
          version: '1.6'
      - name: Install dependencies
        run: julia --project=docs/ -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
      - name: Build and deploy
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} # For authentication with GitHub Actions token
          DOCUMENTER_KEY: ${{ secrets.DOCUMENTER_KEY }} # For authentication with SSH deploy key
        run: julia --project=docs/ docs/make.jl
```

#### **Github Actions Authorization**
Next, we need to set up the `GITHUB_TOKEN` and `DOCUMENTER_KEY` values and make some configurations in the Github repository settings to authorize Github Actions to generate the documentation webpages. The full documentation on this can be found in `Documenter.jl`'s documentation [here](https://juliadocs.github.io/Documenter.jl/stable/man/hosting/index.html), and the following steps are the summary of what needs to be done.  
Open up the REPL and type the following:
```julia
julia> cd("path/to/pkg-name/")
julia> using DocumenterTools
julia> DocumenterTools.genkeys()
```  
The following output will be observed, follow the instructions written in the output. 
```
[ Info: add the public key below to https://github.com/$USER/$REPO/settings/keys with read/write access:

[SSH PUBLIC KEY HERE]

[ Info: add a secure environment variable named 'DOCUMENTER_KEY' to https://travis-ci.com/$USER/$REPO/settings (if you deploy using Travis CI) or https://github.com/$USER/$REPO/settings/secrets (if you deploy using GitHub Actions) with value:

[LONG BASE64 ENCODED PRIVATE KEY]
```
The top instruction can be completed by navigating to the **Settings** tab in the Github repository, then clicking on **Deploy keys** on the left-menu. Click on **Add deploy key** and copy-paste the generated SSH public key.

The bottom instruction can be completed by navigating to **Secrets** on the left-menu in the **Settings** tab. Click on **New repository secret**, set the name as DOCUMENTER_KEY and copy-paste the private key into the value field.

#### **Set up Github Pages**
Last but not least, navigate to **Pages** on the left-menu in the repository **Settings** tab. Set the source branch to be "gh-pages". This means that all the outputs from `docs/make.jl` will be stored in this branch, and what users see in the documentation webpages is powered from this branch.

The set-up of the package's documentation webpages is now complete. As with the configuration in `Documenter.yml`, the documentation workflow will only be triggered when there is a new commit pushed into the master branch.

## 6. Version Tagging and Package Maintainance <a name="tags"></a>
Like any other softwares and operating systems, your Julia package needs to be maintained and/or improved constantly. For a Julia package, making new releases mean that you need to:  
1. Update the version number in your `Project.toml` file. Julia follows a [semantic versioning](https://semver.org/) format and it is strongly advised that your package follows that format.
2. Make a new git and Github tag that points to the new release.
3. Re-register your package in JuliaHub or the Julia Registries as in [Step 4](#registration).

Doing all 3 steps above for every update may be a bit of a hassle, and mistakes can be made between the first and second step. This issue can be resolved by having `TagBot.yml` in your Github workflow. To do so, first create a file called `TagBot.yml` in your `.github/workflows/` directory and copy-paste the following code:
```yaml
name: TagBot
on:
  issue_comment:
    types:
      - created
  workflow_dispatch:
jobs:
  TagBot:
    if: github.event_name == 'workflow_dispatch' || github.actor == 'JuliaTagBot'
    runs-on: ubuntu-latest
    steps:
      - uses: JuliaRegistries/TagBot@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          ssh: ${{ secrets.DOCUMENTER_KEY }}
```
This should help cut out part of your work where you do not need to create git or Github tags manually for each release. Your new package update workflow should go as follows:  
1. Update the version number in your `Project.toml` file.
2. Re-register your package in JuliaHub or the Julia Registries as in [Step 4](#registration).
3. If all test cases are passed in the Julia Registries' pull request, your new version will be merged into [this repository](https://github.com/JuliaRegistries/General). Once your pull request of the new release is merged, you'll receive an email notification and can therefore move on to the next step.
4. Once the pull-request is merged into Julia Registries' General repository, you are done. `TagBot.yml` will automatically be triggered and create a tag for your newest release. Just remember that you'll need to do a `git pull` on your local machine the next time you want to work on your package so that your remote changes can be reflected there.

## 7. Compatibility Settings and Updates with CompatHelper.yml <a name="compathelper"></a>
If you're adding to the `[compat]` section in your `Project.toml` file for the first time and do not have `CompatHelper.yml` set up in your Github workflow, the most direct approach is to do so manually. Essentially, you'd want to do this:
```toml
[compat]
Plots = "1.11.2"
julia = "1.5, 1.6"
```
Note that on top of the dependencies compatible versions, the compatible Julia version that your package works with also has to be added as shown above.

However, for future convenience, it is advised to add `CompatHelper.yml` into your workflow. `CompatHelper.yml` will be able to help detect if there are updates with some of your dependencies and if those updates will result in compatibility issues with your package. To add `CompatHelper.yml` to your workflow, create the `CompatHelper.yml` file in the `.github/workflows/` directory and copy-paste the following:
```yaml
name: CompatHelper
on:
  schedule:
    - cron: 0 0 * * *
  workflow_dispatch:
jobs:
  CompatHelper:
    runs-on: ubuntu-latest
    steps:
      - name: "Install CompatHelper"
        run: |
          import Pkg
          name = "CompatHelper"
          uuid = "aa819f21-2bde-4658-8897-bab36330d9b7"
          version = "2"
          Pkg.add(; name, uuid, version)
        shell: julia --color=yes {0}
      - name: "Run CompatHelper"
        run: |
          import CompatHelper
          CompatHelper.main()
        shell: julia --color=yes {0}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          COMPATHELPER_PRIV: ${{ secrets.DOCUMENTER_KEY }}
          # COMPATHELPER_PRIV: ${{ secrets.COMPATHELPER_PRIV }}
```
You are now essentially done. Everytime one of your dependencies has an update, `CompatHelper.yml` will submit a PR to your package repository suggesting some changes to the `Project.toml` file. If you use Github Actions for you CI, a CI workflow will then be triggered and if this CI passes, it means that the dependency update is compatible with your current package environment and you can safely merge this PR without any negative consequences.