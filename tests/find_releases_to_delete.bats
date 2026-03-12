#!/usr/bin/env bats

setup() {
  source "$(dirname "$BATS_TEST_FILENAME")/../presets/prepare_ruby_stable_releases"

  export TMPDIR
  TMPDIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TMPDIR"
}

# Creates fake package files for a given pkg, version, debian_ver, and distro list.
# Usage: make_pkg_files ruby3.2 3.2.10 ticketsolve jammy noble
function make_pkg_files {
  local pkg=$1 ver=$2 deb_ver=$3
  shift 3
  for distro in "$@"; do
    touch "$TMPDIR/${pkg}_${ver}-${deb_ver}~${distro}1.dsc"
    touch "$TMPDIR/${pkg}_${ver}-${deb_ver}~${distro}1_source.build"
    touch "$TMPDIR/${pkg}_${ver}-${deb_ver}~${distro}1_source.buildinfo"
    touch "$TMPDIR/${pkg}_${ver}-${deb_ver}~${distro}1_source.changes"
    touch "$TMPDIR/${pkg}_${ver}-${deb_ver}~${distro}1_source.ppa.upload"
    touch "$TMPDIR/${pkg}_${ver}-${deb_ver}~${distro}1.tar.gz"
  done
}

function make_source_dir {
  mkdir -p "$TMPDIR/ruby-$1"
}

function sorted_output {
  find_releases_to_delete "$TMPDIR" "$1" | sort
}

# ──────────────────────────────────────────────────────────────────────────────
# Basic cases
# ──────────────────────────────────────────────────────────────────────────────

@test "empty dir: outputs nothing" {
  run sorted_output 3
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exactly keep_releases versions: outputs nothing" {
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy

  run sorted_output 3
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "one version over limit: deletes oldest files" {
  make_pkg_files ruby3.2 3.2.0 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy

  run sorted_output 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" != *"ruby3.2_3.2.1"* ]]
  [[ "$output" != *"ruby3.2_3.2.2"* ]]
  [[ "$output" != *"ruby3.2_3.2.3"* ]]
}

@test "one version over limit: deletes all file suffixes for that version" {
  make_pkg_files ruby3.2 3.2.0 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy

  run sorted_output 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1_source.build"* ]]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1_source.buildinfo"* ]]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1_source.changes"* ]]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1_source.ppa.upload"* ]]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1.tar.gz"* ]]
}

@test "two versions over limit: deletes two oldest" {
  make_pkg_files ruby3.2 3.2.0 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.4 ticketsolve jammy

  run sorted_output 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" == *"ruby3.2_3.2.1-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" != *"ruby3.2_3.2.2"* ]]
  [[ "$output" != *"ruby3.2_3.2.3"* ]]
  [[ "$output" != *"ruby3.2_3.2.4"* ]]
}

@test "keep_releases=1: keeps only the newest" {
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy

  run sorted_output 1
  [ "$status" -eq 0 ]
  [[ "$output" == *"ruby3.2_3.2.1-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" == *"ruby3.2_3.2.2-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" != *"ruby3.2_3.2.3"* ]]
}

# ──────────────────────────────────────────────────────────────────────────────
# Multiple distros
#
# The same version on two distros counts as ONE release per distro group, not
# two. E.g. 3.0.2-distro1 and 3.0.2-distro2 together still count as one
# release towards distro1's keep limit (and one towards distro2's).
# ──────────────────────────────────────────────────────────────────────────────

@test "same version on two distros counts as one release per distro, not two" {
  # distro1 has 4 versions (prunes 3.0.0), distro2 only has 3.0.2.
  # 3.0.2 appearing on both distros must not double-count towards distro1's limit.
  make_pkg_files ruby3.0 3.0.0 ticketsolve distro1
  make_pkg_files ruby3.0 3.0.1 ticketsolve distro1
  make_pkg_files ruby3.0 3.0.2 ticketsolve distro1
  make_pkg_files ruby3.0 3.0.2 ticketsolve distro2
  make_pkg_files ruby3.0 3.0.3 ticketsolve distro1

  run sorted_output 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"ruby3.0_3.0.0-ticketsolve~distro11.dsc"* ]]
  [[ "$output" != *"ruby3.0_3.0.1"* ]]
  [[ "$output" != *"ruby3.0_3.0.2"* ]]
  [[ "$output" != *"ruby3.0_3.0.3"* ]]
}

@test "multiple distros: each group is pruned independently" {
  make_pkg_files ruby3.2 3.2.0 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy noble

  run sorted_output 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~noble1.dsc"* ]]
  [[ "$output" != *"ruby3.2_3.2.1"* ]]
  [[ "$output" != *"ruby3.2_3.2.2"* ]]
  [[ "$output" != *"ruby3.2_3.2.3"* ]]
}

@test "multiple distros: deletes the right distro files only" {
  # jammy has 4 versions (needs pruning), noble has only 2 (no pruning needed)
  make_pkg_files ruby3.2 3.2.0 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.2 ticketsolve noble
  make_pkg_files ruby3.2 3.2.3 ticketsolve noble

  run sorted_output 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" != *"ruby3.2_3.2.0-ticketsolve~noble1.dsc"* ]]
  [[ "$output" != *"ruby3.2_3.2.2-ticketsolve~noble1.dsc"* ]]
}

# ──────────────────────────────────────────────────────────────────────────────
# Multiple packages
# ──────────────────────────────────────────────────────────────────────────────

@test "multiple packages: each package group is pruned independently" {
  make_pkg_files ruby3.2 3.2.0 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy
  make_pkg_files ruby4.0 4.0.0 ticketsolve jammy
  make_pkg_files ruby4.0 4.0.1 ticketsolve jammy
  make_pkg_files ruby4.0 4.0.2 ticketsolve jammy
  make_pkg_files ruby4.0 4.0.3 ticketsolve jammy

  run sorted_output 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" == *"ruby4.0_4.0.0-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" != *"ruby3.2_3.2.1"* ]]
  [[ "$output" != *"ruby4.0_4.0.1"* ]]
}

@test "multiple packages and distros: all groups pruned correctly" {
  make_pkg_files ruby3.2 3.2.0 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy noble
  make_pkg_files ruby4.0 4.0.0 ticketsolve jammy noble
  make_pkg_files ruby4.0 4.0.1 ticketsolve jammy noble
  make_pkg_files ruby4.0 4.0.2 ticketsolve jammy noble
  make_pkg_files ruby4.0 4.0.3 ticketsolve jammy noble

  run sorted_output 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~noble1.dsc"* ]]
  [[ "$output" == *"ruby4.0_4.0.0-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" == *"ruby4.0_4.0.0-ticketsolve~noble1.dsc"* ]]
  [[ "$output" != *"ruby3.2_3.2.1"* ]]
  [[ "$output" != *"ruby4.0_4.0.1"* ]]
}

# ──────────────────────────────────────────────────────────────────────────────
# Multiple debian versions for the same Ruby version
# ──────────────────────────────────────────────────────────────────────────────

@test "multiple debian versions for same ruby version are treated as one release" {
  make_pkg_files ruby3.2 3.2.0 ticketsolve  jammy
  make_pkg_files ruby3.2 3.2.0 ticketsolve2 jammy
  make_pkg_files ruby3.2 3.2.1 ticketsolve  jammy
  make_pkg_files ruby3.2 3.2.1 ticketsolve2 jammy
  make_pkg_files ruby3.2 3.2.2 ticketsolve  jammy
  make_pkg_files ruby3.2 3.2.2 ticketsolve2 jammy
  make_pkg_files ruby3.2 3.2.3 ticketsolve  jammy
  make_pkg_files ruby3.2 3.2.3 ticketsolve2 jammy

  run sorted_output 3
  [ "$status" -eq 0 ]
  # Both debian variants of 3.2.0 should be deleted
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve2~jammy1.dsc"* ]]
  [[ "$output" != *"ruby3.2_3.2.1"* ]]
}

# ──────────────────────────────────────────────────────────────────────────────
# Source directory cleanup
# ──────────────────────────────────────────────────────────────────────────────

@test "source dir is included when all distros drop that version" {
  make_pkg_files ruby3.2 3.2.0 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy noble
  make_source_dir 3.2.0

  run sorted_output 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"$TMPDIR/ruby-3.2.0"* ]]
}

@test "source dir is NOT included when at least one distro still keeps the version" {
  # jammy has 4 (prunes 3.2.0), noble has only 2 (keeps 3.2.0)
  make_pkg_files ruby3.2 3.2.0 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.0 ticketsolve noble
  make_pkg_files ruby3.2 3.2.1 ticketsolve noble
  make_source_dir 3.2.0

  run sorted_output 3
  [ "$status" -eq 0 ]
  [[ "$output" != *"ruby-3.2.0"* ]]
}

@test "source dir is NOT included when it does not exist on disk" {
  make_pkg_files ruby3.2 3.2.0 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy noble
  # no make_source_dir 3.2.0

  run sorted_output 3
  [ "$status" -eq 0 ]
  [[ "$output" != *"ruby-3.2.0"* ]]
  [[ "$output" == *"ruby3.2_3.2.0-ticketsolve~jammy1.dsc"* ]]
}

@test "source dir for kept version is not included" {
  make_pkg_files ruby3.2 3.2.1 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.2 ticketsolve jammy noble
  make_pkg_files ruby3.2 3.2.3 ticketsolve jammy noble
  make_source_dir 3.2.1
  make_source_dir 3.2.2
  make_source_dir 3.2.3

  run sorted_output 3
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Version ordering
# ──────────────────────────────────────────────────────────────────────────────

@test "version ordering is numeric not lexicographic" {
  # Lexicographic order would put 3.2.9 after 3.2.10; numeric order is correct
  make_pkg_files ruby3.2 3.2.8  ticketsolve jammy
  make_pkg_files ruby3.2 3.2.9  ticketsolve jammy
  make_pkg_files ruby3.2 3.2.10 ticketsolve jammy
  make_pkg_files ruby3.2 3.2.11 ticketsolve jammy

  run sorted_output 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"ruby3.2_3.2.8-ticketsolve~jammy1.dsc"* ]]
  [[ "$output" != *"ruby3.2_3.2.9"* ]]
  [[ "$output" != *"ruby3.2_3.2.10"* ]]
  [[ "$output" != *"ruby3.2_3.2.11"* ]]
}
