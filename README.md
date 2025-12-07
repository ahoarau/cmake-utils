# cmake-utils

`cmake-utils` is a collection of CMake functions and macros designed to drastically reduce the boilerplate required to set up modern, production-ready C++ libraries.
It is particularly focued on simplifying the *exports* of c++ libraries, and improve debuggability.

## Goals

Modern CMake is powerful but often requires verbose configuration to achieve standard tasks. The goals of this project are to:

1.  **Reduce Boilerplate**: Replace dozens of lines of configuration with single function calls for common tasks (e.g., setting output directories, configuring install paths).
2.  **Enforce Best Practices**: Make it trivial to enable high warning levels, treat warnings as errors, and enforce compiler conformance (especially for MSVC).
3.  **Simplify Packaging**: Exporting a C++ library so it can be used via `find_package()` is notoriously difficult. `cmake-utils` automates the generation of config files, version files, and transitive dependency management.
4.  **Python Bindings**: Provide first-class support for building and packaging Python bindings (using `nanobind` or `Boost.Python`), including `__init__.py` generation and installation layout.
5.  **Improve Introspection**: Provide summary tables for configuration options and dependencies at the end of the CMake run.

## Design Principles

* Try not to hide CMake concepts. The functions should be thin wrappers that make common tasks easier, not black boxes that obscure what is happening.
* Stay close to standard CMake idioms. Avoid inventing new paradigms or abstractions.
* Be explicit about what is being done. Functions should have clear names and parameters that reflect their purpose.
* Support common use cases, but allow for customization. Users should be able to override defaults when necessary (some work still needs to be done here).

We try to avoid monolithic functions that do everything at once (e.g., a single `add_library_with_all_the_things()` function). Instead, we provide small, focused functions that can be composed together. For example, instead of:
```cmake
jrl_add_library(
    NAME mylib
    SOURCES mylib.cpp
    HEADERS include/mylib/mylib.hpp
    BASE_DIRS include
    LINK_LIBRARIES
        PUBLIC fmt::fmt
        PRIVATE OpenMP::OpenMP_CXX
    COMPILE_OPTIONS
        MSVC
            PRIVATE /W4
            PUBLIC /permissive- /Zc:__cplusplus, /EHsc, /bigobj
        GCC_Clang
            PRIVATE -Wall -Wextra -Wpedantic -Wconversion
    GENERATE_CONFIG_HEADER
    COMPONENT Core
)
```

We prefer:
```cmake
# Standard CMake
add_library(mylib mylib.cpp)
target_include_directories(mylib PUBLIC include)
target_link_libraries(mylib PUBLIC fmt::fmt PRIVATE OpenMP::OpenMP_CXX)

# Utility functions to make life easier. Everything is opt-in:
xxx_target_set_default_compile_options(mylib PRIVATE)
xxx_target_enforce_msvc_conformance(mylib PUBLIC)
xxx_target_generate_config_header(mylib PUBLIC)
xxx_target_headers(mylib PUBLIC HEADERS include/mylib/mylib.hpp BASE_DIRS include)
xxx_add_export_component(NAME Core TARGETS mylib)
```

## Installation

### Method 0: Manual Installation
You can manually install `cmake-utils` by cloning the repository and running the following commands:

```bash
git clone https://github.com/ahoarau/cmake-utils.git
cmake -S cmake-utils -B cmake-utils-build
cmake --build cmake-utils-build --target install
cmake --install cmake-utils-build --prefix /where/to/install/cmake-utils-install
```

To use it in your project, specify the installation path in your `CMAKE_PREFIX_PATH` when configuring your project:

```
cd myproject
cmake -B build -DCMAKE_PREFIX_PATH=/where/to/install/cmake-utils-install
```
Then, in your `CMakeLists.txt`, you can find the package as usual:
```cmake
find_package(cmake-utils CONFIG REQUIRED)

xxx_print_dependencies_summary()
```


### Method 1: FetchContent

You can include `cmake-utils` directly in your project using CMake's `FetchContent` module. This is convenient because it requires no external installation steps.

```cmake
include(FetchContent)
FetchContent_Declare(
    cmake-utils
    GIT_REPOSITORY https://github.com/ahoarau/cmake-utils.git
    GIT_TAG        main # Replace with a specific tag or commit hash
)
FetchContent_MakeAvailable(cmake-utils)
```

### Method 2: `find_package`

If `cmake-utils` is already installed on your system (e.g., via a package manager like Pixi/Conda, or manually via `cmake --install`), you can use `find_package`.

```cmake
find_package(cmake-utils CONFIG REQUIRED)
```

## Usage Example

To use `cmake-utils`, ensure it is available (via `FetchContent` or `find_package`).

```cmake
cmake_minimum_required(VERSION 3.22)

# ┌──────────────────────────────────────────────────────────────────────────────
# │ Project Declaration
# └──────────────────────────────────────────────────────────────────────────────
find_package(cmake-utils CONFIG REQUIRED)  # Find cmake-utils before project()
project(MyProject VERSION 1.0.0 LANGUAGES CXX)

# ┌──────────────────────────────────────────────────────────────────────────────
# │ Default Configurations
# └──────────────────────────────────────────────────────────────────────────────

xxx_configure_defaults()

# ┌──────────────────────────────────────────────────────────────────────────────
# │ Options
# └──────────────────────────────────────────────────────────────────────────────
xxx_option(MYPROJECT_BUILD_TESTS "Build tests" ON)

# ┌──────────────────────────────────────────────────────────────────────────────
# │ Dependencies
# └──────────────────────────────────────────────────────────────────────────────
xxx_find_package(fmt CONFIG REQUIRED)

# ┌──────────────────────────────────────────────────────────────────────────────
# │ Library Definition
# └──────────────────────────────────────────────────────────────────────────────
add_library(mylib src/mylib.cpp)
target_include_directories(mylib PUBLIC include)
target_link_libraries(mylib PUBLIC fmt::fmt)

xxx_target_set_default_compile_options(mylib PRIVATE)
xxx_target_generate_config_header(mylib PUBLIC)
xxx_target_headers(mylib PUBLIC HEADERS include/mylib/mylib.hpp BASE_DIRS include)

# ┌──────────────────────────────────────────────────────────────────────────────
# │ Export Configuration
# └──────────────────────────────────────────────────────────────────────────────
xxx_add_export_component(NAME mylib TARGETS mylib)
xxx_export_package()

# ┌──────────────────────────────────────────────────────────────────────────────
# │ Summary
# └──────────────────────────────────────────────────────────────────────────────
xxx_print_dependencies_summary()
xxx_print_options_summary()
```

## Function Reference

### Project Setup & Configuration

#### `xxx_configure_defaults()`

Sets up sensible defaults for a C++ project in one call. It calls the following functions internally:
*   `xxx_configure_default_build_type(Release)`
*   `xxx_configure_default_binary_dirs()`
*   `xxx_configure_default_install_dirs()`
*   `xxx_configure_default_install_prefix(${CMAKE_BINARY_DIR}/install)`
*   `xxx_configure_copy_compile_commands_in_source_dir()`

Each of these can be called individually if you need more control.

#### `xxx_configure_default_build_type(<build_type>)`

Sets `CMAKE_BUILD_TYPE` to the specified value (e.g., `Release`, `Debug`, `RelWithDebInfo`, `MinSizeRel`) if the user hasn't already specified one. This prevents undefined behavior from an unset build type in single-config generators.

#### `xxx_configure_default_binary_dirs()`

Configures where compiled binaries are placed:
*   `CMAKE_RUNTIME_OUTPUT_DIRECTORY` → `${CMAKE_BINARY_DIR}/bin` (executables, `.dll`, `.pyd`)
*   `CMAKE_LIBRARY_OUTPUT_DIRECTORY` → `${CMAKE_BINARY_DIR}/lib` (shared libraries `.so`/`.dylib`)
*   `CMAKE_ARCHIVE_OUTPUT_DIRECTORY` → `${CMAKE_BINARY_DIR}/lib` (static libraries `.a`/`.lib`)

Also sets per-configuration variants (`_DEBUG`, `_RELEASE`, etc.) for multi-config generators.

#### `xxx_configure_default_install_dirs()`

Includes CMake's `GNUInstallDirs` module to define standard installation directories (`CMAKE_INSTALL_BINDIR`, `CMAKE_INSTALL_LIBDIR`, `CMAKE_INSTALL_INCLUDEDIR`, etc.) in a cross-platform way.

#### `xxx_configure_default_install_prefix(<path>)`

Sets `CMAKE_INSTALL_PREFIX` to the specified path if the user hasn't overridden it. Defaults to `${CMAKE_BINARY_DIR}/install`, which is useful for local development and IDE workflows.

#### `xxx_configure_copy_compile_commands_in_source_dir()`

Automatically copies `compile_commands.json` from the build directory to the source root at the end of the CMake configuration step. This enables IDE features like code completion and navigation without manual setup.

#### `xxx_option(<name> <description> <default> [COMPATIBILITY_OPTION <old_name>])`

A wrapper around `option()` that records the option for the summary table. Supports a `COMPATIBILITY_OPTION` to handle renamed options gracefully with a deprecation warning.

#### `xxx_print_options_summary()`

Prints a formatted table of all options defined via `xxx_option`, showing their current values, types, and descriptions.

#### `xxx_cmake_dependent_option(<name> <description> <default> <condition> <else_value>)`

A wrapper around CMake's `cmake_dependent_option()` that also records the option for the summary table. The option is only available when `<condition>` is true; otherwise it defaults to `<else_value>`.

---

### Dependency Management

#### `xxx_find_package(<package> ...)`

Wraps the standard `find_package()`. **Crucially**, it records the found package and its imported targets. This information is used by `xxx_export_package` to automatically handle transitive dependencies in the generated CMake config files.

#### `xxx_print_dependencies_summary()`

Prints a list of all packages found via `xxx_find_package`, including the imported targets and their properties (useful for debugging include paths and link libraries).

---

### Target Configuration

#### `xxx_target_set_default_compile_options(<target> <visibility>)`

Enables high warning levels:
*   **MSVC**: `/W4` and disables some noisy/useless warnings.
*   **GCC/Clang**: `-Wall -Wextra -Wconversion -Wpedantic`.

#### `xxx_target_enforce_msvc_conformance(<target> <visibility>)`

For MSVC, adds `/permissive-`, `/Zc:__cplusplus`, `/EHsc`, and `/bigobj`. This ensures MSVC behaves more like a standard C++ compiler.

#### `xxx_target_treat_all_warnings_as_errors(<target> <visibility>)`

Adds `/WX` (MSVC) or `-Werror` (GCC/Clang).

---

### Code Generation

These functions generate C++ header files with useful macros and version information.

#### `xxx_target_generate_config_header(<target> <visibility>)`

Generates a `config.hpp` containing version macros and DLL export macros. For a target named `mylib`, the generated macros use the uppercase target name as prefix: `MYLIB_MAJOR_VERSION`, `MYLIB_MINOR_VERSION`, `MYLIB_PATCH_VERSION`, `MYLIB_VERSION`, and `MYLIB_DLLAPI` for symbol visibility.

#### `xxx_target_generate_warning_header(<target> <visibility>)`

Generates a `warning.hpp` with macros to easily suppress warnings for specific blocks of code (useful when including third-party headers).

#### `xxx_target_generate_deprecated_header(<target> <visibility>)`

Generates a `deprecated.hpp` with macros to mark functions or classes as deprecated in a cross-platform way.

#### `xxx_target_generate_tracy_header(<target> <visibility>)`

Generates a `tracy.hpp` helper for integrating the Tracy profiler.

---

### Packaging & Exporting

#### `xxx_target_headers(<target> <visibility> HEADERS <list> BASE_DIRS <list>)`

Declares which headers belong to a target and should be installed. `BASE_DIRS` helps preserve the directory structure relative to the include path.

#### `xxx_add_export_component(NAME <name> TARGETS <targets>)`

Groups one or more targets into a named "component" (e.g., `Core`, `IO`). Downstream users can then find specific components: `find_package(MyLib COMPONENTS Core)`.

#### `xxx_export_package()`

The main packaging function:
*   Generates `<Package>Config.cmake` and `<Package>ConfigVersion.cmake`.
*   Generates target export files for each component.
*   Generates dependency files that automatically `find_dependency` any dependencies recorded by `xxx_find_package`.

---

### Python Bindings

#### `xxx_find_python(...)`

A robust wrapper to find Python Interpreter and Development components. Prints useful diagnostic information about the found Python installation.

#### `xxx_find_nanobind(...)`

Finds the `nanobind` library and its dependencies (like `tsl-robin-map`).

#### `xxx_python_generate_init_py(<target> OUTPUT_PATH <path>)`

Generates an `__init__.py` file for a native extension module. On Windows, it automatically handles adding DLL directories to the search path.

#### `xxx_python_compile_all(DIRECTORY <dir> [VERBOSE])`

Compiles installed Python `.py` files into bytecode (`.pyc`) to speed up import times. Use `VERBOSE` to print the files being compiled.

#### `xxx_python_compute_install_dir(<output_var>)`

Computes the relative Python site-packages path (e.g., `Lib/site-packages` on Windows, `lib/pythonX.Y/site-packages` on Linux). Stores the result in `<output_var>`. Can be overridden via `${PROJECT_NAME}_PYTHON_INSTALL_DIR`.

#### `xxx_check_python_module(<module_name> [REQUIRED] [QUIET])`

Checks if a Python module is importable. Sets `<module_name>_FOUND` accordingly.

#### `xxx_check_python_module_name(<target>)`

Adds a post-build check to verify the compiled Python extension module has the expected name.

---

### Testing

#### `xxx_include_ctest()`

A wrapper around `include(CTest)` that prevents adding extraneous CTest targets (like `Experimental`, `Nightly`, etc.) to keep the IDE clean.

#### `pytest_discover_tests(...)`

Integrates `pytest` with CTest, allowing individual Python tests to be run and reported by CTest.

#### `boosttest_discover_tests(...)`

Integrates Boost.Test executables with CTest.

## Design: Automatic Dependency Extraction

One of the most complex aspects of exporting a CMake package is ensuring that downstream consumers can automatically find all transitive dependencies. For example, if `MyLib` links against `fmt`, then a project using `find_package(MyLib)` must also find `fmt`.

Manually writing `find_dependency()` calls is tedious and error-prone. `cmake-utils` automates this with a two-phase approach that tracks dependencies at configure time and generates the correct `find_dependency()` calls at install time.

---

### Phase 1: Recording Dependencies (`xxx_find_package`)

When you call `xxx_find_package(fmt CONFIG REQUIRED)`, the function does the following:

1.  **Snapshots Imported Targets**: It queries the `IMPORTED_TARGETS` directory property *before* calling `find_package`.
2.  **Calls `find_package`**: The standard CMake `find_package(fmt CONFIG REQUIRED)` is executed.
3.  **Detects New Targets**: It queries `IMPORTED_TARGETS` again *after* the call and computes the difference to find which new targets were created (e.g., `fmt::fmt`).
4.  **Stores Metadata as JSON**: It saves this information into a global CMake property (`_xxx_<PROJECT_NAME>_package_dependencies`) as a JSON structure.

The stored JSON for each package looks like this:

```json
{
  "package_name": "fmt",
  "find_package_args": "fmt CONFIG REQUIRED",
  "package_targets": "fmt::fmt;fmt::fmt-header-only",
  "module_file": ""
}
```

This metadata captures:
*   The **package name**.
*   The **exact arguments** passed to `find_package`, so they can be replayed.
*   The **imported targets** the package provides.
*   The **module file path** (if a `Find<Package>.cmake` module was used instead of a config file).

---

### Phase 2: Exporting Dependencies (`xxx_export_package`)

When you call `xxx_export_package()`, the function performs dependency analysis at *install time* using a generated CMake script:

1.  **Writes Metadata to Files**: During configuration, it writes the recorded JSON and the list of `INTERFACE_LINK_LIBRARIES` for each exported target to:
    *   `<build_dir>/generated/cmake/<project>/<component>/imported-libraries.cmake`
    *   `<build_dir>/generated/cmake/<project>/<project>-package-dependencies.json` (for debugging)

2.  **Generates an Install Script**: It configures a `generate-dependencies.cmake` script from a template. This script runs at `cmake --install` time.

3.  **Analyzes Link Libraries at Install Time**: The install script iterates over the `INTERFACE_LINK_LIBRARIES` and, for each imported target (like `fmt::fmt`), looks it up in the recorded JSON to find the original `find_package` arguments.

4.  **Generates `dependencies.cmake`**: It writes a `<component>/dependencies.cmake` file containing:

    ```cmake
    include(CMakeFindDependencyMacro)

    if(NOT TARGET fmt::fmt)
        find_dependency(fmt CONFIG REQUIRED)
    endif()
    ```

    The `if(NOT TARGET ...)` guard prevents errors if the dependency was already found by another package.

5.  **Handles Find Modules**: If the original package used a `Find<Package>.cmake` module (not a config file), the install script copies the module file to the install destination and prepends `CMAKE_MODULE_PATH` in the generated `dependencies.cmake`.

---

### Example Flow

```cmake
# In your CMakeLists.txt
xxx_find_package(fmt CONFIG REQUIRED)    # Records: fmt -> fmt::fmt
xxx_find_package(spdlog CONFIG REQUIRED) # Records: spdlog -> spdlog::spdlog

add_library(mylib src/mylib.cpp)
target_link_libraries(mylib PUBLIC fmt::fmt spdlog::spdlog)

xxx_add_export_component(NAME mylib TARGETS mylib)
xxx_export_package()
```

**At configure time**, the JSON structure is populated:
```json
{
  "package_dependencies": [
    { "package_name": "fmt", "find_package_args": "fmt CONFIG REQUIRED", "package_targets": "fmt::fmt", ... },
    { "package_name": "spdlog", "find_package_args": "spdlog CONFIG REQUIRED", "package_targets": "spdlog::spdlog", ... }
  ]
}
```

**At install time**, the `generate-dependencies.cmake` script runs and produces:

```cmake
# <install_prefix>/lib/cmake/MyLib/mylib/dependencies.cmake
include(CMakeFindDependencyMacro)

if(NOT TARGET fmt::fmt)
    find_dependency(fmt CONFIG REQUIRED)
endif()

if(NOT TARGET spdlog::spdlog)
    find_dependency(spdlog CONFIG REQUIRED)
endif()
```

**When a downstream project** does `find_package(MyLib CONFIG REQUIRED)`, the generated `MyLibConfig.cmake` includes the component's `dependencies.cmake`, ensuring `fmt` and `spdlog` are found automatically.