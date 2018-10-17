# bazel-cra-example

This is an example of getting [Bazel](https://github.com/bazelbuild/rules_nodejs) working with [create-react-app](https://github.com/facebook/create-react-app)

### Start the app

* Install docker-compose
* Clone this repo
* Run `docker-compose up start` from the repo root
* Browse to `http://localhost:3000`

### Build the app for production

* Install docker-compose
* Clone this repo
* Run `docker-compose up build` from the repo root

### Problems trying to get cra apps working with rules_nodejs

nodejs_binary uses a different working directory than npm when launching the
build/start/test scripts. I worked around this by injecting code into the top
of these scripts that changes the directory based on `__dirname`

cra resolves symlinks when executing webpack, but uses working directory when
building the webpack config. This results in name mismatches. I worked around
this by adding the resolved paths to some of the webpack config 'includes'
entries

bazel monkey-patches require, but babel uses the `resolve` npm package to load
packages which bypasses the require patches. I got around this by adding the
bazel sandbox npm folder to the resolve/modules section of the webpack config.

cra uses a `babel` section in the package.json, but this also has problems (I
believe due to the `resolve` issue above). To get around this, I explicitly
added a `require('babel-preset-react-app')` to the babel-loader section of the
webpack config that handles the cra app code.

### Notes

The templates folder and scripts/setup file are only used to create this repo.
You should ignore it when looking at how to get bazel working with cra

Some stuff in bazel requires a reference to the "workspace name". It seems
like its intentionally difficult to place the workspace name in a DRY location
so we're using the template files to keep the workspace name in sync while
creating this repo.

The scripts/setup file creates a cra application on the fly and tries to patch
everything, but modifying the webpack config files is difficult to automate. In
order to get this repo out there, I modified the webpack config manually. You
shouldn't need to run setup yourself. It's only for setting up this repo.

The scripts/merge file handles merging dependencies from packages/* folders into
the /pacakges/package.json file. I had to do this because I was unable to get
rules_nodejs to load multiple package.json files correctly. But even if I get
that resolved, I like the idea of a unified package.json so that you're forced
to use identical vendor library versions.

This is just a bare minimum effort to get bazel + cra working. I have not
performed exhaustive testing of complex cra-based applications. Heck, I haven't
even tried using the built app. Use this at your own risk and please read the
TODOs below.

### Internal notes

To clean this repo (wipes *everything* including .git):

* Run `docker-compose up bazel`
* Open another terminal and run `docker-compose exec bazel /src/scripts/setup -cx`

To rebuild this repo (wipes a lot but not .git):

* Run `docker-compose up bazel`
* Open another terminal and run `docker-compose exec bazel /src/scripts/setup -cr`

### TODO

* Get tests working

* Automate patching of webpack config instead of overwriting it with templates

* Research and resolve any potential issues with cra-example/config/paths referring to working dir based paths. This is currently causing an exception at the end of the build process when the build.js script is trying to get the bundle stats info.
