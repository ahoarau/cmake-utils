# cmake-utils

A collection of CMake utility functions to simplify C++ and Python project configuration.
No magic, only opt-in functions.

On the library/project side:

```cmake
project(myproj)

xxx_configure_defaults()

add_library(mylib mylib.cpp)

xxx_add_export_component(
    NAME mycomponent
    TARGETS mylib
)

xxx_export_package()
```

On the client side:


```cmake
find_package(myproj 1.0.0 CONFIG REQUIRED COMPONENT mycomponent)
```



## Features

- **Project Defaults**: Standardized build types, output directories, and install paths.
- **Target Configuration**: Easy setup for compiler warnings (MSVC, GCC, Clang) and conformance.
- **Python Bindings**: Helpers for `nanobind` and `Boost.Python`.
- **Dependency Management**: Enhanced `find_package` and dependency tracking.
- **Header Generation**: Automatic generation of config, version, and warning headers.

## Dependencies

* CMake >= 3.22.
* (**optional**) Python >= 3.8: only for python related functions

## Installation

### Using CMake FetchContent

```cmake
include(FetchContent)
FetchContent_Declare(
    cmake-utils
    GIT_REPOSITORY https://github.com/ahoarau/cmake-utils.git
    GIT_TAG 1.0.0
)
FetchContent_MakeAvailable(cmake-utils)
```

## Complete example

Include the module in your `CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.22)

include(FetchContent)
FetchContent_Declare(
    cmake-utils
    GIT_REPOSITORY https://github.com/ahoarau/cmake-utils.git
    GIT_TAG 1.0.0
)
FetchContent_MakeAvailable(cmake-utils)

project(myproj)

# (recommended) Configure defaults (output dirs, install prefix, etc.)
xxx_configure_defaults()

# Create your libraries as usual
add_library(mylib src/mylib.cpp)
xxx_target_enforce_msvc_conformance(mylib PRIVATE) # recommded to enhance uniformity accross compilers

# Declare the headers
# They will be automatically installed with xxx_export_package()
xxx_target_headers(mylib PUBLIC
    HEADERS
        include/myproj/myproj.hpp
    BASE_DIRS
        include
)

# Declare the components
xxx_add_export_component(
    NAME mycomponent
    TARGETS mylib
)

# Export the package configuration (create <pkg>-config.cmake, install targets etc)
xxx_export_package()
```

## License

BSD 3-Clause License. See [LICENSE](LICENSE) for details.
