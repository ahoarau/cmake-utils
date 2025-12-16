# CMake Documentation

Generated from `jrl.cmake`.

## Index

- [copy_compile_commands_in_source_dir](#copy-compile-commands-in-source-dir) — `function` — [jrl.cmake#L25](jrl.cmake#L25)
- [jrl_configure_copy_compile_commands_in_source_dir](#jrl-configure-copy-compile-commands-in-source-dir) — `function` — [jrl.cmake#L37](jrl.cmake#L37)
- [jrl_check_var_defined](#jrl-check-var-defined) — `function` — [jrl.cmake#L56](jrl.cmake#L56)
- [jrl_check_target_exists](#jrl-check-target-exists) — `function` — [jrl.cmake#L68](jrl.cmake#L68)
- [jrl_check_valid_visibility](#jrl-check-valid-visibility) — `function` — [jrl.cmake#L74](jrl.cmake#L74)
- [jrl_check_file_exists](#jrl-check-file-exists) — `function` — [jrl.cmake#L84](jrl.cmake#L84)
- [jrl_include_ctest](#jrl-include-ctest) — `macro` — [jrl.cmake#L91](jrl.cmake#L91)
- [jrl_configure_default_build_type](#jrl-configure-default-build-type) — `function` — [jrl.cmake#L99](jrl.cmake#L99)
- [jrl_configure_default_binary_dirs](#jrl-configure-default-binary-dirs) — `function` — [jrl.cmake#L117](jrl.cmake#L117)
- [jrl_target_set_output_directory](#jrl-target-set-output-directory) — `function` — [jrl.cmake#L133](jrl.cmake#L133)
- [jrl_configure_default_install_dirs](#jrl-configure-default-install-dirs) — `function` — [jrl.cmake#L165](jrl.cmake#L165)
- [jrl_configure_default_install_prefix](#jrl-configure-default-install-prefix) — `function` — [jrl.cmake#L170](jrl.cmake#L170)
- [jrl_configure_defaults](#jrl-configure-defaults) — `function` — [jrl.cmake#L185](jrl.cmake#L185)
- [jrl_target_set_default_compile_options](#jrl-target-set-default-compile-options) — `function` — [jrl.cmake#L198](jrl.cmake#L198)
- [jrl_target_enforce_msvc_conformance](#jrl-target-enforce-msvc-conformance) — `function` — [jrl.cmake#L246](jrl.cmake#L246)
- [jrl_target_treat_all_warnings_as_errors](#jrl-target-treat-all-warnings-as-errors) — `function` — [jrl.cmake#L274](jrl.cmake#L274)
- [jrl_make_valid_c_identifier](#jrl-make-valid-c-identifier) — `function` — [jrl.cmake#L297](jrl.cmake#L297)
- [jrl_target_generate_header](#jrl-target-generate-header) — `function` — [jrl.cmake#L315](jrl.cmake#L315)
- [jrl_target_generate_warning_header](#jrl-target-generate-warning-header) — `function` — [jrl.cmake#L383](jrl.cmake#L383)
- [jrl_target_generate_deprecated_header](#jrl-target-generate-deprecated-header) — `function` — [jrl.cmake#L421](jrl.cmake#L421)
- [jrl_target_generate_config_header](#jrl-target-generate-config-header) — `function` — [jrl.cmake#L459](jrl.cmake#L459)
- [jrl_target_generate_tracy_header](#jrl-target-generate-tracy-header) — `function` — [jrl.cmake#L501](jrl.cmake#L501)
- [jrl_search_package_module_file](#jrl-search-package-module-file) — `function` — [jrl.cmake#L545](jrl.cmake#L545)
- [jrl_find_package](#jrl-find-package) — `macro` — [jrl.cmake#L570](jrl.cmake#L570)
- [jrl_print_dependencies_summary](#jrl-print-dependencies-summary) — `function` — [jrl.cmake#L688](jrl.cmake#L688)
- [jrl_cmake_print_properties](#jrl-cmake-print-properties) — `function` — [jrl.cmake#L756](jrl.cmake#L756)
- [jrl_export_dependencies](#jrl-export-dependencies) — `function` — [jrl.cmake#L898](jrl.cmake#L898)
- [jrl_add_export_component](#jrl-add-export-component) — `function` — [jrl.cmake#L1006](jrl.cmake#L1006)
- [jrl_contains_generator_expressions](#jrl-contains-generator-expressions) — `function` — [jrl.cmake#L1054](jrl.cmake#L1054)
- [jrl_target_headers](#jrl-target-headers) — `function` — [jrl.cmake#L1071](jrl.cmake#L1071)
- [jrl_target_install_headers](#jrl-target-install-headers) — `function` — [jrl.cmake#L1098](jrl.cmake#L1098)
- [jrl_install_headers](#jrl-install-headers) — `function` — [jrl.cmake#L1167](jrl.cmake#L1167)
- [jrl_export_package](#jrl-export-package) — `function` — [jrl.cmake#L1238](jrl.cmake#L1238)
- [jrl_dump_package_dependencies_json](#jrl-dump-package-dependencies-json) — `function` — [jrl.cmake#L1356](jrl.cmake#L1356)
- [jrl_option](#jrl-option) — `function` — [jrl.cmake#L1373](jrl.cmake#L1373)
- [jrl_cmake_dependent_option](#jrl-cmake-dependent-option) — `function` — [jrl.cmake#L1403](jrl.cmake#L1403)
- [jrl_print_options_summary](#jrl-print-options-summary) — `function` — [jrl.cmake#L1442](jrl.cmake#L1442)
- [jrl_find_python](#jrl-find-python) — `macro` — [jrl.cmake#L1502](jrl.cmake#L1502)
- [jrl_find_nanobind](#jrl-find-nanobind) — `macro` — [jrl.cmake#L1522](jrl.cmake#L1522)
- [jrl_python_compile_all](#jrl-python-compile-all) — `function` — [jrl.cmake#L1576](jrl.cmake#L1576)
- [jrl_python_generate_init_py](#jrl-python-generate-init-py) — `function` — [jrl.cmake#L1614](jrl.cmake#L1614)
- [jrl_check_python_module](#jrl-check-python-module) — `function` — [jrl.cmake#L1694](jrl.cmake#L1694)
- [jrl_python_compute_install_dir](#jrl-python-compute-install-dir) — `function` — [jrl.cmake#L1728](jrl.cmake#L1728)
- [jrl_check_python_module_name](#jrl-check-python-module-name) — `function` — [jrl.cmake#L1776](jrl.cmake#L1776)

<a id="copy-compile-commands-in-source-dir"></a>
# copy_compile_commands_in_source_dir

```cpp
copy_compile_commands_in_source_dir()
```

**Type**: `function`

### Parameters

- _none_

Copy compile_commands.json from the binary dir to the upper source directory for clangd support

<a id="jrl-configure-copy-compile-commands-in-source-dir"></a>
# jrl_configure_copy_compile_commands_in_source_dir

```cpp
jrl_configure_copy_compile_commands_in_source_dir()
```

**Type**: `function`

### Parameters

- _none_

Launch the copy at the end of the configuration step

<a id="jrl-check-var-defined"></a>
# jrl_check_var_defined

```cpp
jrl_check_var_defined(<var>)
```

**Type**: `function`

### Parameters

- `var`: _Describe this parameter._

Usage: jrl_check_var_defined(<var> [<message>])
Example: jrl_check_var_defined(MY_VAR "MY_VAR must be set to build this project")
Example: jrl_check_var_defined(MY_VAR) # Will print "MY_VAR is not defined."

<a id="jrl-check-target-exists"></a>
# jrl_check_target_exists

```cpp
jrl_check_target_exists(<target_name>)
```

**Type**: `function`

### Parameters

- `target_name`: _Describe this parameter._

Check if a target exists, otherwise raise a fatal error

<a id="jrl-check-valid-visibility"></a>
# jrl_check_valid_visibility

```cpp
jrl_check_valid_visibility(<PRIVATE|PUBLIC|INTERFACE>)
```

**Type**: `function`

### Parameters

- `visibility`: _Describe this parameter._

_No documentation available._

<a id="jrl-check-file-exists"></a>
# jrl_check_file_exists

```cpp
jrl_check_file_exists(<filepath>)
```

**Type**: `function`

### Parameters

- `filepath`: _Describe this parameter._

_No documentation available._

<a id="jrl-include-ctest"></a>
# jrl_include_ctest

```cpp
jrl_include_ctest()
```

**Type**: `macro`

### Parameters

- _none_

Include CTest but simply prevent adding a lot of useless targets. Useful for IDEs.

<a id="jrl-configure-default-build-type"></a>
# jrl_configure_default_build_type

```cpp
jrl_configure_default_build_type(<build_type>)
```

**Type**: `function`

### Parameters

- `build_type`: _Describe this parameter._

Usage: jrl_configure_default_build_type(<build_type>)
Usual values for <build_type> are: Debug, Release, MinSizeRel, RelWithDebInfo
Example: jrl_configure_default_build_type(RelWithDebInfo)

<a id="jrl-configure-default-binary-dirs"></a>
# jrl_configure_default_binary_dirs

```cpp
jrl_configure_default_binary_dirs()
```

**Type**: `function`

### Parameters

- _none_

Configures the default output directory for binaries and libraries

<a id="jrl-target-set-output-directory"></a>
# jrl_target_set_output_directory

```cpp
jrl_target_set_output_directory(<target_name>
  [OUTPUT_DIRECTORY <value>]
)
```

**Type**: `function`

### Parameters

- `target_name`: _Describe this parameter._

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `OUTPUT_DIRECTORY` (one-value): _Describe this keyword._

_No documentation available._

<a id="jrl-configure-default-install-dirs"></a>
# jrl_configure_default_install_dirs

```cpp
jrl_configure_default_install_dirs()
```

**Type**: `function`

### Parameters

- _none_

Configures the default install directories using GNUInstallDirs (bin, lib, include, etc.)
Works on all platforms

<a id="jrl-configure-default-install-prefix"></a>
# jrl_configure_default_install_prefix

```cpp
jrl_configure_default_install_prefix(<default_install_prefix>)
```

**Type**: `function`

### Parameters

- `default_install_prefix`: _Describe this parameter._

If not provided by the user, set a default CMAKE_INSTALL_PREFIX. Useful for IDEs.

<a id="jrl-configure-defaults"></a>
# jrl_configure_defaults

```cpp
jrl_configure_defaults()
```

**Type**: `function`

### Parameters

- _none_

Setup the default options for a project (opinionated defaults)
Usage : jrl_configure_defaults()

<a id="jrl-target-set-default-compile-options"></a>
# jrl_target_set_default_compile_options

```cpp
jrl_target_set_default_compile_options(<target_name> <PRIVATE|PUBLIC|INTERFACE>)
```

**Type**: `function`

### Parameters

- `target_name`: _Describe this parameter._
- `visibility`: _Describe this parameter._

Enable the most common warnings for MSVC, GCC and Clang
Adding some extra warning on msvc to mimic gcc/clang behavior
Usage: jrl_target_set_default_compile_options(<target_name> <visibility>)
visibility is either PRIVATE, PUBLIC or INTERFACE
Example: jrl_target_set_default_compile_options(my_target INTERFACE)

<a id="jrl-target-enforce-msvc-conformance"></a>
# jrl_target_enforce_msvc_conformance

```cpp
jrl_target_enforce_msvc_conformance(<target_name> <PRIVATE|PUBLIC|INTERFACE>)
```

**Type**: `function`

### Parameters

- `target_name`: _Describe this parameter._
- `visibility`: _Describe this parameter._

Description: Enforce MSVC c++ conformance mode so msvc behaves more like gcc and clang
Usage: jrl_target_enforce_msvc_conformance(<target_name> <visibility>)
visibility is either PRIVATE, PUBLIC or INTERFACE
Example: jrl_target_enforce_msvc_conformance(my_target INTERFACE)

<a id="jrl-target-treat-all-warnings-as-errors"></a>
# jrl_target_treat_all_warnings_as_errors

```cpp
jrl_target_treat_all_warnings_as_errors(<target_name> <PRIVATE|PUBLIC|INTERFACE>)
```

**Type**: `function`

### Parameters

- `target_name`: _Describe this parameter._
- `visibility`: _Describe this parameter._

Description: Treat all warnings as errors for a targets (/WX for MSVC, -Werror for GCC/Clang)
Can be disabled by on the cmake cli with --compile-no-warning-as-error
ref: https://cmake.org/cmake/help/latest/manual/cmake.1.html#cmdoption-cmake-compile-no-warning-as-error
Usage: jrl_target_treat_all_warnings_as_errors(<target_name> <visibility>)
visibility is either PRIVATE, PUBLIC or INTERFACE
Example: jrl_target_treat_all_warnings_as_errors(my_target PRIVATE)
NOTE: in CMake 3.24, we have the new CMAKE_COMPILE_WARNING_AS_ERROR option, but for the whole project and subprojects

<a id="jrl-make-valid-c-identifier"></a>
# jrl_make_valid_c_identifier

```cpp
jrl_make_valid_c_identifier(<INPUT> <OUTPUT_VAR>)
```

**Type**: `function`

### Parameters

- `INPUT`: _Describe this parameter._
- `OUTPUT_VAR`: _Describe this parameter._

_No documentation available._

<a id="jrl-target-generate-header"></a>
# jrl_target_generate_header

```cpp
jrl_target_generate_header(<target_name> <PRIVATE|PUBLIC|INTERFACE>
  [SKIP_INSTALL]
  [FILENAME <value>]
  [HEADER_DIR <value>]
  [INSTALL_DESTINATION <value>]
  [TEMPLATE_FILE <value>]
  [VERSION <value>]
)
```

**Type**: `function`

### Parameters

- `target_name`: _Describe this parameter._
- `visibility`: _Describe this parameter._

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `SKIP_INSTALL` (option): _Describe this keyword._
- `FILENAME` (one-value): _Describe this keyword._
- `HEADER_DIR` (one-value): _Describe this keyword._
- `TEMPLATE_FILE` (one-value): _Describe this keyword._
- `INSTALL_DESTINATION` (one-value): _Describe this keyword._
- `VERSION` (one-value): _Describe this keyword._

_No documentation available._

<a id="jrl-target-generate-warning-header"></a>
# jrl_target_generate_warning_header

```cpp
jrl_target_generate_warning_header(<target_name> <PRIVATE|PUBLIC|INTERFACE>
  [SKIP_INSTALL]
  [FILENAME <value>]
  [HEADER_DIR <value>]
  [INSTALL_DESTINATION <value>]
)
```

**Type**: `function`

### Parameters

- `target_name`: _Describe this parameter._
- `visibility`: _Describe this parameter._

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `SKIP_INSTALL` (option): _Describe this keyword._
- `FILENAME` (one-value): _Describe this keyword._
- `HEADER_DIR` (one-value): _Describe this keyword._
- `INSTALL_DESTINATION` (one-value): _Describe this keyword._

_No documentation available._

<a id="jrl-target-generate-deprecated-header"></a>
# jrl_target_generate_deprecated_header

```cpp
jrl_target_generate_deprecated_header(<target_name> <PRIVATE|PUBLIC|INTERFACE>
  [SKIP_INSTALL]
  [FILENAME <value>]
  [HEADER_DIR <value>]
  [INSTALL_DESTINATION <value>]
)
```

**Type**: `function`

### Parameters

- `target_name`: _Describe this parameter._
- `visibility`: _Describe this parameter._

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `SKIP_INSTALL` (option): _Describe this keyword._
- `FILENAME` (one-value): _Describe this keyword._
- `HEADER_DIR` (one-value): _Describe this keyword._
- `INSTALL_DESTINATION` (one-value): _Describe this keyword._

_No documentation available._

<a id="jrl-target-generate-config-header"></a>
# jrl_target_generate_config_header

```cpp
jrl_target_generate_config_header(<target_name> <PRIVATE|PUBLIC|INTERFACE>
  [SKIP_INSTALL]
  [FILENAME <value>]
  [HEADER_DIR <value>]
  [INSTALL_DESTINATION <value>]
  [VERSION <value>]
)
```

**Type**: `function`

### Parameters

- `target_name`: _Describe this parameter._
- `visibility`: _Describe this parameter._

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `SKIP_INSTALL` (option): _Describe this keyword._
- `FILENAME` (one-value): _Describe this keyword._
- `HEADER_DIR` (one-value): _Describe this keyword._
- `INSTALL_DESTINATION` (one-value): _Describe this keyword._
- `VERSION` (one-value): _Describe this keyword._

_No documentation available._

<a id="jrl-target-generate-tracy-header"></a>
# jrl_target_generate_tracy_header

```cpp
jrl_target_generate_tracy_header(<target_name> <PRIVATE|PUBLIC|INTERFACE>
  [SKIP_INSTALL]
  [FILENAME <value>]
  [HEADER_DIR <value>]
  [INSTALL_DESTINATION <value>]
)
```

**Type**: `function`

### Parameters

- `target_name`: _Describe this parameter._
- `visibility`: _Describe this parameter._

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `SKIP_INSTALL` (option): _Describe this keyword._
- `FILENAME` (one-value): _Describe this keyword._
- `HEADER_DIR` (one-value): _Describe this keyword._
- `INSTALL_DESTINATION` (one-value): _Describe this keyword._

_No documentation available._

<a id="jrl-search-package-module-file"></a>
# jrl_search_package_module_file

```cpp
jrl_search_package_module_file(<package_name> <output_filepath>)
```

**Type**: `function`

### Parameters

- `package_name`: _Describe this parameter._
- `output_filepath`: _Describe this parameter._

This function searches for a find module named Find<package>.cmake).
It iterates over the CMAKE_MODULE_PATH and cmake builtin modules.

<a id="jrl-find-package"></a>
# jrl_find_package

```cpp
jrl_find_package(
  [MODULE_PATH <value>]
)
```

**Type**: `macro`

### Parameters

- _none_

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `MODULE_PATH` (one-value): _Describe this keyword._

Usage: jrl_find_package(<package> [version] [REQUIRED] [COMPONENTS ...] MODULE_PATH <path_to_find_module>)
ref: https://cmake.org/cmake/help/latest/command/find_package.html
This function allows to automatically retrieve the imported targets provided by the package
and store info in global properties for later use (e.g. when exporting dependencies)
Note: this needs to be a macro so find_package can leak variables (like Python_SITELIB)

<a id="jrl-print-dependencies-summary"></a>
# jrl_print_dependencies_summary

```cpp
jrl_print_dependencies_summary()
```

**Type**: `function`

### Parameters

- _none_

jrl_print_dependencies_summary()
Print a summary of all dependencies found via jrl_find_package, and some properties of their imported targets.

<a id="jrl-cmake-print-properties"></a>
# jrl_cmake_print_properties

```cpp
jrl_cmake_print_properties(
  [OUTPUT_VARIABLE <value>]
  [VERBOSITY <value>]
  [CACHE_ENTRIES <item>...]
  [DIRECTORIES <item>...]
  [PROPERTIES <item>...]
  [SOURCES <item>...]
  [TARGETS <item>...]
  [TESTS <item>...]
)
```

**Type**: `function`

### Parameters

- _none_

### Keyword arguments

Parsed from `cmake_parse_arguments(CPP ...)`:

- `VERBOSITY` (one-value): _Describe this keyword._
- `OUTPUT_VARIABLE` (one-value): _Describe this keyword._
- `PROPERTIES` (multi-value): _Describe this keyword._

Parsed from `cmake_parse_arguments(CPPMODE ...)`:

- `VERBOSITY` (one-value): _Describe this keyword._
- `OUTPUT_VARIABLE` (one-value): _Describe this keyword._
- `TARGETS` (multi-value): _Describe this keyword._
- `SOURCES` (multi-value): _Describe this keyword._
- `TESTS` (multi-value): _Describe this keyword._
- `DIRECTORIES` (multi-value): _Describe this keyword._
- `CACHE_ENTRIES` (multi-value): _Describe this keyword._

jrl_cmake_print_properties
Usage: jrl_cmake_print_properties(<mode> <items> PROPERTIES <property1> <property2> ... [VERBOSITY <verbosity_level>] [OUTPUT_VARIABLE <var_name>])
This is taken and adapted from cmake's own cmake_print_properties function to add verbosity control and print only found properties.
If OUTPUT_VARIABLE is provided, the output will be stored in the variable instead of printed to the console.

<a id="jrl-export-dependencies"></a>
# jrl_export_dependencies

```cpp
jrl_export_dependencies(
  [GEN_DIR <value>]
  [INSTALL_DESTINATION <value>]
  [TARGETS <item>...]
)
```

**Type**: `function`

### Parameters

- _none_

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `INSTALL_DESTINATION` (one-value): _Describe this keyword._
- `GEN_DIR` (one-value): _Describe this keyword._
- `TARGETS` (multi-value): _Describe this keyword._

Usage: jrl_export_dependencies(TARGETS [target1...] GEN_DIR <gen_dir> INSTALL_DESTINATION <destination>)
This function analyzes the link libraries of the provided targets,
determines which packages are needed and generates a <export_name>-dependencies.cmake file

<a id="jrl-add-export-component"></a>
# jrl_add_export_component

```cpp
jrl_add_export_component(
  [NAME <value>]
  [TARGETS <item>...]
)
```

**Type**: `function`

### Parameters

- _none_

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `NAME` (one-value): _Describe this keyword._
- `TARGETS` (multi-value): _Describe this keyword._

jrl_add_export_component(NAME <component_name> TARGETS <target1> <target2> ...)
Add an export component with associated targets that will be exported as a CMake package component.
Each export component will have its own <package>-component-<name>-targets.cmake
and <package>-component-<name>-dependencies.cmake generated.
Components are used with: find_package(<package> CONFIG REQUIRED COMPONENTS <component1> <component2> ...)

<a id="jrl-contains-generator-expressions"></a>
# jrl_contains_generator_expressions

```cpp
jrl_contains_generator_expressions(<input_string> <output_var>)
```

**Type**: `function`

### Parameters

- `input_string`: _Describe this parameter._
- `output_var`: _Describe this parameter._

jrl_contains_generator_expressions(<input_string> <output_var>)
Check if the provided string contains generator expressions.
Sets output_var to True or False.

<a id="jrl-target-headers"></a>
# jrl_target_headers

```cpp
jrl_target_headers(<target> <PRIVATE|PUBLIC|INTERFACE>
  [GENERATED_DIR <value>]
  [BASE_DIRS <item>...]
  [HEADERS <item>...]
)
```

**Type**: `function`

### Parameters

- `target`: _Describe this parameter._
- `visibility`: _Describe this parameter._

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `GENERATED_DIR` (one-value): _Describe this keyword._
- `HEADERS` (multi-value): _Describe this keyword._
- `BASE_DIRS` (multi-value): _Describe this keyword._

jrl_target_headers(<target>
  HEADERS <list_of_headers>
  BASE_DIRS <list_of_base_dirs> # Optional, default is empty
)
Declare headers for target (to be installed later)
This will populate the _jrl_install_headers and _jrl_install_headers_base_dirs properties of the target.
In CMake 3.23, we will use FILE_SETS instead of this trick.
cf: https://cmake.org/cmake/help/latest/command/target_sources.html#file-sets

<a id="jrl-target-install-headers"></a>
# jrl_target_install_headers

```cpp
jrl_target_install_headers(<target>
  [DESTINATION <value>]
)
```

**Type**: `function`

### Parameters

- `target`: _Describe this parameter._

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `DESTINATION` (one-value): _Describe this keyword._

jrl_target_install_headers(<target>
  DESTINATION <destination> # Optional, default is CMAKE_INSTALL_INCLUDEDIR
)
Install declared header for a given target and solve the relative path using the provided base dirs.
It is using the _jrl_install_headers and _jrl_install_headers_base_dirs properties set via jrl_target_headers().
For a whole project, use jrl_install_headers() instead (which calls this function for each component, that contains targets).

<a id="jrl-install-headers"></a>
# jrl_install_headers

```cpp
jrl_install_headers(
  [DESTINATION <value>]
  [COMPONENTS <item>...]
)
```

**Type**: `function`

### Parameters

- _none_

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `DESTINATION` (one-value): _Describe this keyword._
- `COMPONENTS` (multi-value): _Describe this keyword._

jrl_install_headers(
  DESTINATION <destination> # Optional, default is CMAKE_INSTALL_INCLUDEDIR
  COMPONENTS <component1> <component2> ... # Optional, default is all declared components
)
For each component, install declared headers for all targets.
See jrl_target_headers() to declare headers for a target.

<a id="jrl-export-package"></a>
# jrl_export_package

```cpp
jrl_export_package(
  [CMAKE_FILES_INSTALL_DIR <value>]
  [PACKAGE_CONFIG_EXTRA_CONTENT <value>]
  [PACKAGE_CONFIG_TEMPLATE <value>]
)
```

**Type**: `function`

### Parameters

- _none_

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `PACKAGE_CONFIG_TEMPLATE` (one-value): _Describe this keyword._
- `CMAKE_FILES_INSTALL_DIR` (one-value): _Describe this keyword._
- `PACKAGE_CONFIG_EXTRA_CONTENT` (one-value): _Describe this keyword._

jrl_export_package()
Export the CMake package with all its components (targets, headers, package modules, etc.)
Generates and installs CMake package configuration files:
 - <INSTALL_DIR>/<package>/<package>-config.cmake
 - <INSTALL_DIR>/<package>/<package>-config-version.cmake
 - <INSTALL_DIR>/<package>/<package>/<componentA>/targets.cmake
 - <INSTALL_DIR>/<package>/<package>/<componentA>/dependencies.cmake
 - <INSTALL_DIR>/<package>/<package>/<componentB>/targets.cmake
 - <INSTALL_DIR>/<package>/<package>/<componentB>/dependencies.cmake
NOTE: This is for CMake package export only. Python bindings are handled separately.

<a id="jrl-dump-package-dependencies-json"></a>
# jrl_dump_package_dependencies_json

```cpp
jrl_dump_package_dependencies_json(<output>)
```

**Type**: `function`

### Parameters

- `output`: _Describe this parameter._

jrl_dump_package_dependencies_json()
Internal function to dump the package dependencies recorded with jrl_find_package()
It is called at the end of the configuration step via cmake_language(DEFER CALL ...)
In the function jrl_export_package().

<a id="jrl-option"></a>
# jrl_option

```cpp
jrl_option(<option_name> <description> <default_value>
  [COMPATIBILITY_OPTION <value>]
)
```

**Type**: `function`

### Parameters

- `option_name`: _Describe this parameter._
- `description`: _Describe this parameter._
- `default_value`: _Describe this parameter._

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `COMPATIBILITY_OPTION` (one-value): _Describe this keyword._

jrl_option(<option_name> <description> <default_value>)
Example: jrl_option(BUILD_TESTING "Build the tests" ON)
Override cmake option() to get a nice summary at the end of the configuration step

<a id="jrl-cmake-dependent-option"></a>
# jrl_cmake_dependent_option

```cpp
jrl_cmake_dependent_option(<option_name> <description> <default_value> <condition> <else_value>)
```

**Type**: `function`

### Parameters

- `option_name`: _Describe this parameter._
- `description`: _Describe this parameter._
- `default_value`: _Describe this parameter._
- `condition`: _Describe this parameter._
- `else_value`: _Describe this parameter._

_No documentation available._

<a id="jrl-print-options-summary"></a>
# jrl_print_options_summary

```cpp
jrl_print_options_summary()
```

**Type**: `function`

### Parameters

- _none_

Print all options defined via jrl_option() in a nice table
Usage: jrl_print_options_summary()

<a id="jrl-find-python"></a>
# jrl_find_python

```cpp
jrl_find_python()
```

**Type**: `macro`

### Parameters

- _none_

Shortcut to find Python package and check main variables
Usage: jrl_find_python([version] [REQUIRED] [COMPONENTS ...])
Example: jrl_find_python(3.8 REQUIRED COMPONENTS Interpreter Development.Module)

<a id="jrl-find-nanobind"></a>
# jrl_find_nanobind

```cpp
jrl_find_nanobind()
```

**Type**: `macro`

### Parameters

- _none_

Shortcut to find the nanobind package
Usage: jrl_find_nanobind()

<a id="jrl-python-compile-all"></a>
# jrl_python_compile_all

```cpp
jrl_python_compile_all(
  [VERBOSE]
  [DIRECTORY <value>]
)
```

**Type**: `function`

### Parameters

- _none_

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `VERBOSE` (option): _Describe this keyword._
- `DIRECTORY` (one-value): _Describe this keyword._

_No documentation available._

<a id="jrl-python-generate-init-py"></a>
# jrl_python_generate_init_py

```cpp
jrl_python_generate_init_py(<name>
  [OUTPUT_PATH <value>]
)
```

**Type**: `function`

### Parameters

- `name`: _Describe this parameter._

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `OUTPUT_PATH` (one-value): _Describe this keyword._

_No documentation available._

<a id="jrl-check-python-module"></a>
# jrl_check_python_module

```cpp
jrl_check_python_module(<module_name>
  [QUIET]
  [REQUIRED]
)
```

**Type**: `function`

### Parameters

- `module_name`: _Describe this parameter._

### Keyword arguments

Parsed from `cmake_parse_arguments(arg ...)`:

- `REQUIRED` (option): _Describe this keyword._
- `QUIET` (option): _Describe this keyword._

Find if a python module is available, fills <module_name>_FOUND variable
Displays messages based on REQUIRED and QUIET options
Usage: jrl_check_python_module(<module_name> [REQUIRED] [QUIET])
Example: jrl_check_python_module(numpy REQUIRED)

<a id="jrl-python-compute-install-dir"></a>
# jrl_python_compute_install_dir

```cpp
jrl_python_compute_install_dir(<output>)
```

**Type**: `function`

### Parameters

- `output`: _Describe this parameter._

_No documentation available._

<a id="jrl-check-python-module-name"></a>
# jrl_check_python_module_name

```cpp
jrl_check_python_module_name(<target>)
```

**Type**: `function`

### Parameters

- `target`: _Describe this parameter._

Check that the python module defined with NB_MODULE(<module_name>)
or BOOST_PYTHON_MODULE(<module_name>) has the same name as the target: <module_name>.cpython-XY.so
Usage: jrl_check_python_module_name(<module_target>)
