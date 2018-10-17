load("@build_bazel_rules_nodejs//:defs.bzl", "nodejs_binary")

filegroup(
    name = "package_json",
    srcs = glob(["package.json"]),
)

filegroup(
    name = "config_files",
    srcs = glob(["config/**/*.js"])
)

filegroup(
    name = "source_files",
    srcs = glob(["src/**/*.js"])
)

filegroup(
    name = "script_files",
    srcs = glob(["scripts/*.js"])
)

filegroup(
    name = "public_files",
    srcs = glob(["public/**/*"])
)

nodejs_binary(
    name = "~~PACKAGE_NAME~~",
    visibility = ["//visibility:public"],
    entry_point = "~~WORKSPACE_NAME~~/~~PACKAGE_NAME~~/scripts/start.js",
    data = [
        ":package_json",
        ":config_files",
        ":source_files",
        ":script_files",
        ":public_files",
~~DEPENDENCIES~~~~DEV_DEPENDENCIES~~    ],
)

nodejs_binary(
    name = "bundle",
    visibility = ["//visibility:public"],
    entry_point = "~~WORKSPACE_NAME~~/~~PACKAGE_NAME~~/scripts/build.js",
    data = [
        ":package_json",
        ":config_files",
        ":source_files",
        ":script_files",
        ":public_files",
~~DEPENDENCIES~~~~DEV_DEPENDENCIES~~    ],
)

nodejs_binary(
    name = "test",
    visibility = ["//visibility:public"],
    entry_point = "~~WORKSPACE_NAME~~/~~PACKAGE_NAME~~/scripts/test.js",
    data = [
        ":package_json",
        ":config_files",
        ":source_files",
        ":script_files",
        ":public_files",
~~DEPENDENCIES~~~~DEV_DEPENDENCIES~~    ],
)
