Working version changelog, used as a base for the changelog and the release
note.
Prefixes used to help generate release notes, changes, and blog posts:
* ✘ Possibly scripts breaking changes
* ◈ New option/command/subcommand
* [BUG] for bug fixes
* [NEW] for new features (not a command itself)
* [API] api updates 🕮
If there is changes in the API (new non optional argument, function renamed or
moved, etc.), please update the _API updates_ part (it helps opam library
users)

## Version

## Global CLI

## Plugins

## Init

## Config report

## Actions

## Install
  * Fix a performance regression where opam project trees were scanned for nothing, when pinning them [#7101 @kit-ty-kate - fix #7098]

## Build (package)

## Remove

## UI

## Switch

## Config

## Pin

## List

## Show

## Var/Option

## Update / Upgrade

## Tree

## Exec

## Source

## Lint

## Repository

## Lock

## Clean

## Env

## Opamfile

## External dependencies

## Format upgrade

## Sandbox

## VCS

## Build

## Infrastructure

## Release scripts
  * Harden the release script against known `sshpass` instability [#7096 @kit-ty-kate]
  * Make the Windows binary reproducible [#7097 @kit-ty-kate - fix #6752]
  * Add a reproducibility check step and define reproducibility of release binaries [#7097 @kit-ty-kate]

## Install script
  * Add `2.6.0~beta1` [#7099 @kit-ty-kate]

## Admin

## Opam installer

## State

## Opam file format

## Solver

## Client

## Shell

## Internal

## Internal: Unix

## Internal: Windows

## Test

## Benchmarks

## Reftests
### Tests
  * Add a new test showing opam's package format upgrade behaviours [#7101 @kit-ty-kate]
  * Test the behaviour of `extra-files` when pinned from a local directory [#7101 @kit-ty-kate]

### Engine

## Github Actions

## Doc

## Security fixes

# API updates
## opam-client

## opam-repository

## opam-state

## opam-solver

## opam-format

## opam-core
  * `OpamSystem.{rec_,}{files,dirs}`: add some log in debug mode [#7101 @kit-ty-kate]
