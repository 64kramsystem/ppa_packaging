# PPA Packaging

Script for preparing PPA packages. No need to handle all the messy Debian tools 😬

The purpose and working has been described in [an article](https://saveriomiroddi.github.io/Learn-to-prepare-PPA-packages-by-setting-up-a-Ruby-PPA/) in my blog.

## Usage

Set the related enviroment variables, and execute the script; example usage:

```sh
# Details of the env variables is provided by the script help (`prepare_ppa_package --help`)

export PPA_PAK_PACKAGE_NAME='ruby3.1'
export PPA_PAK_VERSION='3.1.2'
export PPA_PAK_PPA_ADDRESS='ppa:myuser/myrepo'
export PPA_PAK_DISTROS='focal,jammy'
export PPA_PAK_EMAIL='myuser@gmail.com'
export PPA_PAK_COPYRIGHT='gpl2'
export PPA_PAK_DESCRIPTION='Interpreter of object-oriented scripting language Ruby'
export PPA_PAK_HOMEPAGE='https://www.ruby-lang.org/'
export PPA_PAK_SECTION='interpreters'

export PPA_PAK_BUILD_DEPS='autoconf,automake,bison,ca-certificates,curl,libc6-dev,libffi-dev,libgdbm-dev,libncurses5-dev,libsqlite3-dev,libtool,libyaml-dev,make,openssl,patch,pkg-config,sqlite3,zlib1g,zlib1g-dev,libreadline-dev,libssl-dev,libgmp-dev'

# `--cowbuild` will perform a test build locally, before uploading to Launchpad.
#
prepare_ppa_package --cowbuild /path/to/ruby_source
```

The above will prepare the deb source package and upload it to Launchpad, which will build the binary packages and make them available in the specified PPA 😁

## Licenses

Due to limitations of the `dh_make` tool, only a few preset licenses are available (see script help), and multiple licenses are not possible; as of v2.202102 (Oct/2022), the MIT license is not included.

In order to specify any other license(s), create a license file, and set it as `PPA_PAK_COPYRIGHT` value.

## Presets

See the [`presets`](presets) directory for some preset configurations.
