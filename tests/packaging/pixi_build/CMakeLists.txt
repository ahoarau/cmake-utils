cmake_minimum_required(VERSION 3.22...4.1)

project(myproj VERSION 1.0.0 LANGUAGES NONE)

# Find the cmake-utils package
find_package(cmake-utils 0.1.0 CONFIG REQUIRED)

# Example finding an external package
xxx_find_package(cmake-utils 0.1.0 CONFIG REQUIRED)
xxx_require_variable(cmake-utils_VERSION)

# Testing one of the functions provided by cmake-utils
xxx_include_ctest()
