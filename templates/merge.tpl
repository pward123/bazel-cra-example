#!/usr/bin/env node

/**
 * Merges dependencies for a package into the bazel monorepo config
 *
 * Usage:
 *   merge <package_path>
 */

const fs = require('fs')
const Path = require('path')
const {promisify} = require('util')

const WORKSPACE_NAME = '##WORKSPACE_NAME##'

// Promisified fs methods
const readFile = promisify(fs.readFile)
const writeFile = promisify(fs.writeFile)
const exists = promisify(fs.exists)

// Error classes
class BaseError extends Error {}
class ArgumentError extends BaseError {}
class DependencyError extends BaseError {}

// Filesystem locations
const repoRootFolder = Path.join(__dirname, '..')
const packagesFolder = Path.join(repoRootFolder, 'packages')
const workspaceJsonFilename = Path.join(packagesFolder, 'package.json')

// Create the contents of the BUILD.bazel file
const interpolateBazelBuild = async (packageName, depNames, devDepNames) => {
    const template = await readFile(Path.join(repoRootFolder, 'templates', 'BUILD.bazel.tpl'), 'utf8')

    let dependencies = ''
    if (depNames && (depNames.length > 0)) {
        dependencies = '        # dependencies\n'
        depNames.forEach(d => {
            dependencies += `        "@npm//${d}",\n`
        })
    }

    let devDependencies = ''
    if (devDepNames && (devDepNames.length > 0)) {
        devDependencies = '        # devDependencies\n'
        devDepNames.forEach(d => {
            devDependencies += `        "@npm//${d}",\n`
        })
    }

    return template
        .replace(/~~WORKSPACE_NAME~~/g, WORKSPACE_NAME)
        .replace(/~~PACKAGE_NAME~~/g, packageName)
        .replace(/~~DEPENDENCIES~~/g, dependencies)
        .replace(/~~DEV_DEPENDENCIES~~/g, devDependencies)
}

// Main entrypoint
const main = async () => {
    // Make sure the package name argument has been provided
    if (process.argv.length !== 3) {
        throw new ArgumentError(`Usage: ${Path.basename(process.argv[1])} <package_name>`)
    }
    const packageName = process.argv[2]

    // Make sure the package.json exists in the package
    const packageJsonFilename = Path.join(packagesFolder, packageName, 'package.json')
    if (!await exists(packageJsonFilename)) {
        throw new ArgumentError(`File(${packageJsonFilename}) must exist`)
    }

    // Read the package's package.json file
    console.log(`Reading package.json for ${packageName}`)
    const packageJson = JSON.parse(await readFile(packageJsonFilename, 'utf8'))
    const packageDeps = packageJson.dependencies || {}
    const packageDevDeps = packageJson.devDependencies || {}
    delete packageJson.dependencies
    delete packageJson.devDependencies

    // Read the workspace package.json file
    console.log('Reading workspace package.json')
    const workspaceJson = JSON.parse(await readFile(workspaceJsonFilename, 'utf8'))
    const workspaceDeps = workspaceJson.dependencies || {}
    const workspaceDevDeps = workspaceJson.devDependencies || {}

    // Make sure the BUILD.bazel for the package doesn't already exist
    const bazelBuildFilename = Path.join(packagesFolder, packageName, 'BUILD.bazel')
    if (await exists(bazelBuildFilename)) {
        throw new ArgumentError(`Build file(${bazelBuildFilename}) must not exist`)
    }

    // Create the BUILD.bazel contents
    const bazelBuild = await interpolateBazelBuild(
        packageName,
        Object.keys(packageDeps),
        Object.keys(packageDevDeps),
    )

    let everythingOk = true
    let depsChanged = false
    let devDepsChanged = false

    if (packageJson.peerDependencies && (Object.keys(packageJson.peerDependencies).length > 0)) {
        everythingOk = false
        console.error(`Package has peerDependencies -- unsupported by this tool`)
    }

    // Resolve package dependencies
    for (key in packageDeps) {
        const value = packageDeps[key]

        // If workspace already has this dependency
        if (workspaceDeps[key]) {
            // If it doesn't satisfy, we have a problem
            if (workspaceDeps[key] !== value) {
                everythingOk = false
                console.error(`Dependency(${key}) conflicts with current workspace dependencies`)
            }
            continue
        }

        // If workspace already has this dependency as a devDependency
        if (workspaceDevDeps[key]) {
            // If it doesn't satisfy, we have a problem
            if (workspaceDevDeps[key] !== value) {
                everythingOk = false
                console.error(`Dependency(${key}) conflicts with current workspace devDependencies`)
                continue
            }

            // Move this from workspace devDependencies to dependencies
            workspaceDeps[key] = workspaceDevDeps[key]
            delete workspaceDevDeps[key]
            depsChanged = true
            devDepsChanged = true
            continue
        }

        depsChanged = true
        workspaceDeps[key] = value
    }

    // resolve package devDependencies
    for (key in packageDevDeps) {
        const value = packageDevDeps[key]

        // If workspace already has this dependency
        if (workspaceDeps[key]) {
            // If it doesn't satisfy, we have a problem
            if (workspaceDeps[key] !== value) {
                everythingOk = false
                console.error(`Dependency(${key}) conflicts with current workspace dependencies`)
            }
            continue
        }

        // If workspace already has this dependency as a devDependency
        if (workspaceDevDeps[key]) {
            // If it doesn't satisfy, we have a problem
            if (workspaceDevDeps[key] !== value) {
                everythingOk = false
                console.error(`Dependency(${key}) conflicts with current workspace devDependencies`)
            }
            continue
        }

        devDepsChanged = true
        workspaceDevDeps[key] = value
    }

    if (!everythingOk) {
        throw new DependencyError('Dependency problems exist. Please resolve and retry.')
    }

    if (depsChanged) {
        if (Object.keys(workspaceDeps).length === 0) {
            delete workspaceJson.dependencies
        } else {
            workspaceJson.dependencies = workspaceDeps
        }
    }

    if (devDepsChanged) {
        if (Object.keys(workspaceDevDeps).length === 0) {
            delete workspaceJson.devDependencies
        } else {
            workspaceJson.devDependencies = workspaceDevDeps
        }
    }

    // Write any workspace package.json changes
    if (depsChanged || devDepsChanged) {
        await writeFile(workspaceJsonFilename, JSON.stringify(workspaceJson, null, 2))
    }

    // Remove dependencies and devDependencies from packageJson
    await writeFile(packageJsonFilename, JSON.stringify(packageJson, null, 2))

    // Write the bazel build file for the package
    await writeFile(bazelBuildFilename, bazelBuild)
}

main()
    .then(() => {
        process.exit(0)
    })
    .catch(e => {
        if (e instanceof BaseError) {
            console.error(e.message)
        } else {
            console.error(e.stack)
        }

        process.exit(1)
    })
