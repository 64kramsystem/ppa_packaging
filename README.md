# PPA Packaging

Script for preparing PPA packages. No need to handle all the messy Debian tools 😬

The purpose and working has been described in [an article](https://saveriomiroddi.github.io/Learn-to-prepare-PPA-packages-by-setting-up-a-Ruby-PPA/) in my blog.

## Usages

The program is driven by enviroment variables, which need to be set:

```sh
# Details of the env variables are described in the script help (`prepare_ppa_package --help`).

export PPA_PAK_LAUNCHPAD_ID='myuser'
export PPA_PAK_EMAIL='myuser@gmail.com'

export PPA_PAK_COPYRIGHT='gpl2'
export PPA_PAK_DESCRIPTION='Interpreter of object-oriented scripting language Ruby'
export PPA_PAK_HOMEPAGE='https://www.ruby-lang.org/'
export PPA_PAK_DISTROS='focal,jammy'
export PPA_PAK_SECTION='interpreters'
export PPA_PAK_BUILD_DEPS='autoconf,automake,bison,ca-certificates,curl,libc6-dev,libffi-dev,libgdbm-dev,libncurses5-dev,libsqlite3-dev,libtool,libyaml-dev,make,openssl,patch,pkg-config,sqlite3,zlib1g,zlib1g-dev,libreadline-dev,libssl-dev,libgmp-dev'

# These activate one of the two different modes, based on the format; see sections below.
#
export PPA_PAK_PACKAGE_NAME='foo'
export PPA_PAK_VERSION='bar'

# This will launch the procedure.
#
# `--cowbuild` will perform a test build locally, before uploading to Launchpad.
#
prepare_ppa_package --cowbuild /path/to/ruby
```

The above command will prepare the deb source package and upload it to Launchpad, which will build the binary packages and make them available in the specified PPA 😁

### Tarball-based workflow

When publishing a package from a (unpacked) tarball, one specifies the exact package name and version:

```sh
export PPA_PAK_VERSION='3.1.2'
export PPA_PAK_PACKAGE_NAME='ruby3.1'
```

The disadvantage, in this mode, is that one needs to manually find and unpack the tarball, and set the variables above.

### Repository-based workflow

In this mode, one provides the repository, and specifies a regex that describes the version tag and package name:

```sh
# Note that this variable has a leading and trailing slash, and captures the version numbers in round brackets (capturing groups).
#
export PPA_PAK_VERSION='/v(3)_(1)_([0-9]+)/'
export PPA_PAK_PACKAGE_NAME='ruby$1.$2'
```

The program will:

- fetch the latest tags,
- find the latest one (based on `$PPA_PAK_VERSION`),
- check it out,
- then prepare the package version and name using the capturing groups matched by `$PPA_PAK_VERSION`,
- and follow up with the same procedure as the tarball mode.

With the example variables above, the resulting metadata is:

- latest tag: `v3_1_2`
- package version: `3.1.2`
- package name: `ruby3.1`

If the package name is fixed, it's not necessary to specify matching variables.

## Licenses

Due to limitations of the `dh_make` tool, only a few preset licenses are available (see script help), and multiple licenses are not possible; as of v2.202102 (Oct/2022), the MIT license is not included.

In order to specify any other license(s), create a license file, and set it as `PPA_PAK_COPYRIGHT` value.

## Presets

See the [`presets`](presets) directory for some preset configurations.
