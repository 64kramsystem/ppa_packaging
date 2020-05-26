# PPA Packaging

Scripts for preparing PPA packages.

Their purpose and working has been described in [an article](https://saveriomiroddi.github.io/Learn-to-prepare-PPA-packages-by-setting-up-a-Ruby-PPA/) in my blog.

The core script is `prepare_ppa_package`:

```
$ prepare_ppa_package --help

Usage: prepare_ppa_package [options] <project_directory>

Requires the following packages to be installed: dh-make,cowbuilder,devscripts.

Parameters:

-c|--cowbuild:              Build with cowbuilder before uploading
-u|--no-upload:             Don't upload the package
-t|--no-test:               Don't execute the test target (overrides the `dh_auto_test` rule)

Environment-variable parameters (mandatory):

- $PPA_PAK_PACKAGE_NAME
- $PPA_PAK_VERSION
- $PPA_PAK_COPYRIGHT         : Filename of the copyright file, or (supported) copyright name (see below)
- $PPA_PAK_PPA_ADDRESS
- $PPA_PAK_EMAIL
- $PPA_PAK_DESCRIPTION
- $PPA_PAK_HOMEPAGE

Environment-variable parameters (optional):

- $PPA_PAK_BUILD_DEPS        : Comma-separed list of build dependencies
- $PPA_PAK_DEPS              : Comma-separed list of dependencies
- $PPA_PAK_DISTROS:          : Comma-separed list of distros to build; defaults to all the supported ones (see below)
- $PPA_PAK_LONG_DESCRIPTION  : Long package description; defaults to the value of $PPA_PAK_DESCRIPTION
- $PPA_PAK_SECTION           : Package section; defaults to `utils`
- $PPA_PAK_VCS_BROWSER       : Source project homepage
- $PPA_PAK_VCS_GIT           : Source project git address

The supported standard copyrights are: apache,artistic,bsd,gpl,gpl2,gpl3,isc,lgpl,lgpl2,lgl3,mit.
The supported distributions are: focal,bionic,xenial.

Example (mandatory -> optional -> command):

    export PPA_PAK_PACKAGE_NAME='ruby2.5'
    export PPA_PAK_VERSION='2.5.8-sav1'
    export PPA_PAK_COPYRIGHT=~/build/ruby-2.7.1/BSDL
    export PPA_PAK_PPA_ADDRESS='ppa:saverio/ruby-test-4'
    export PPA_PAK_EMAIL='saverio.notexists@gmail.com'
    export PPA_PAK_DESCRIPTION='Interpreter of object-oriented scripting language Ruby'
    export PPA_PAK_HOMEPAGE='https://www.ruby-lang.org/'

    export PPA_PAK_BUILD_DEPS='autoconf,automake,bison,ca-certificates' # incomplete
    export PPA_PAK_DEPS='libgmp-dev'
    export PPA_PAK_DISTROS='bionic,focal'
    export PPA_PAK_LONG_DESCRIPTION=$'Ruby is the\ninterpreted scripting language\nfor quick and easy'
    export PPA_PAK_SECTION='interpreters'
    export PPA_PAK_VCS_BROWSER='https://github.com/ruby/ruby/'
    export PPA_PAK_VCS_GIT='https://github.com/ruby/ruby.git'

    prepare_ppa_package ~/build/ruby-2.7.1
```

`prepare_ruby_packages` is a wrapper that prepares Ruby packages:

```
$ prepare_ruby_packages --help

Usage: prepare_ruby_packages [-c|--cowbuild] [-u|--upload] [(-d|--distros) $distros] [-l|--latest] <ppa_address> <debian_version> <email>

Downloads the latest stable Ruby versions, packages them, and uploads them.

Requires `prepare_ppa_package` to be in the same directory as this file.

Example: prepare_ruby_packages --cowbuild --upload --distros bionic ppa:saverio/ruby-test-4 sav1 saverio.notexists@gmail.com
```
