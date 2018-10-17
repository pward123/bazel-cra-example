workspace(name = "##WORKSPACE_NAME##")

git_repository(
    name = "build_bazel_rules_nodejs",
    remote = "https://github.com/bazelbuild/rules_nodejs.git",
    tag = "0.15.1",
)

# Setup dependencies for the nodejs bazel package
load("@build_bazel_rules_nodejs//:package.bzl", "rules_nodejs_dependencies")
rules_nodejs_dependencies()

# Setup the basic nodejs bazel package
load("@build_bazel_rules_nodejs//:defs.bzl", "node_repositories")

node_repositories(
    node_version = "8.11.4",
    yarn_version = "1.10.1",
    node_repositories = {
        "8.11.4-darwin_amd64": ("node-v8.11.4-darwin-x64.tar.gz", "node-v8.11.4-darwin-x64", "aa1de83b388581d0d9ec3276f4526ee67e17e0f1bc0deb5133f960ce5dc9f1ef"),
        "8.11.4-linux_amd64": ("node-v8.11.4-linux-x64.tar.xz", "node-v8.11.4-linux-x64", "85ea7cbb5bf624e130585bfe3946e99c85ce5cb84c2aee474038bdbe912f908c"),
        "8.11.4-windows_amd64": ("node-v8.11.4-win-x64.zip", "node-v8.11.4-win-x64", "72a21e2fcd3703994f57cf707b92e7f939df99c3e0298102e7436849e4948536"),
    },
    yarn_repositories = {
        "1.10.1": ("yarn-v1.10.1.tar.gz", "yarn-v1.10.1", "97bf147cb28229e66e4e3c5733a93c851bbcb0f10fbc72696ed011774f4c6f1b"),
    },
    node_urls = ["https://nodejs.org/dist/v{version}/{filename}"],
    yarn_urls = ["https://github.com/yarnpkg/yarn/releases/download/v{version}/{filename}"],
    package_json = ["//:package.json"]
)

# Install npm packages
load("@build_bazel_rules_nodejs//:defs.bzl", "yarn_install")
yarn_install(
    name = "npm",
    package_json = "//:package.json",
    yarn_lock = "//:yarn.lock",
)
