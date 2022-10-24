# PPA Packaging

Scripts for preparing PPA packages.

Their purpose and working has been described in [an article](https://saveriomiroddi.github.io/Learn-to-prepare-PPA-packages-by-setting-up-a-Ruby-PPA/) in my blog.

## Usage

The core script is `prepare_ppa_package`; run with the `--help` for a detailed help.

Example usage:

```sh
export PPA_PAK_PACKAGE_NAME='ruby2.7'
export PPA_PAK_VERSION='2.7.1-sav1'
export PPA_PAK_COPYRIGHT=~/build/ruby-2.7.1/BSDL
export PPA_PAK_PPA_ADDRESS='ppa:myusers/ruby-test-4'
export PPA_PAK_EMAIL='myuser.notexists@gmail.com'
export PPA_PAK_DESCRIPTION='Interpreter of object-oriented scripting language Ruby'
export PPA_PAK_HOMEPAGE='https://www.ruby-lang.org/'

prepare_ppa_package --cowbuild /path/to/ruby-2.7.1
```

## Licenses

Due to limitations of the `dh_make` tool, only a few preset licenses are available (see script help), and multiple licenses are not possible; as of v2.202102 (Oct/2022), the MIT license is not included.

In order to specify any other license(s), create a license file, and set it as `PPA_PAK_COPYRIGHT` value.

## Presets

The [`presets`](presets/) directory includes preset scripts for some programs, e.g. `prepare_ruby_packages`:

```
$ prepare_ruby_packages --help

Usage: prepare_ruby_packages [-c|--cowbuild] [-u|--upload] [(-d|--distros) $distros] [-l|--latest] <ppa_address> <debian_version> <email>

Downloads the latest stable Ruby versions, packages them, and uploads them.

Requires `prepare_ppa_package` to be in the same directory as this file.

Example: prepare_ruby_packages --cowbuild --upload --distros bionic ppa:saverio/ruby-test-4 sav1 saverio.notexists@gmail.com
```
