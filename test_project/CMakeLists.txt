cmake_minimum_required(VERSION 3.22)
project(test_project VERSION 1.0.0 LANGUAGES CXX)

# Include the cmake-utils.cmake from parent directory
include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake-utils.cmake)

# Configure defaults
xxx_configure_default_build_type(Release)
xxx_configure_default_binary_dirs()
xxx_configure_default_install_dirs()
xxx_configure_default_install_prefix(${CMAKE_CURRENT_BINARY_DIR}/install)

# Find dependencies
xxx_find_python(3.8 REQUIRED COMPONENTS Interpreter Development.Module)
xxx_find_nanobind(CONFIG)

# Enable testing
xxx_include_ctest()

# Declare options
xxx_option(BUILD_PYTHON_BINDINGS "Build Python bindings" ON)

if(BUILD_PYTHON_BINDINGS AND NOT nanobind_FOUND)
    message(WARNING "nanobind not found, disabling Python bindings")
    set(BUILD_PYTHON_BINDINGS OFF)
endif()

# Create libraries
add_library(math_lib STATIC)
target_sources(math_lib PRIVATE
    src/Math.cpp
)
target_include_directories(math_lib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
target_compile_features(math_lib PUBLIC cxx_std_17)

add_library(string_lib SHARED)
target_sources(string_lib PRIVATE
    src/StringUtils.cpp
)
target_include_directories(string_lib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
target_compile_features(string_lib PUBLIC cxx_std_17)

# Set compile options
xxx_target_set_default_compile_options(math_lib PUBLIC)
xxx_target_set_default_compile_options(string_lib PUBLIC)

# Generate config headers
xxx_target_generate_config_header(math_lib PUBLIC)
xxx_target_generate_config_header(string_lib PUBLIC)

# Declare components
xxx_declare_component(COMPONENT core TARGETS math_lib string_lib)

# Python bindings
if(BUILD_PYTHON_BINDINGS)
    add_subdirectory(python_bindings)
endif()

# Install headers
xxx_target_headers(math_lib PUBLIC HEADERS include/test_project/Math.hpp BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include)
xxx_target_headers(string_lib PUBLIC HEADERS include/test_project/StringUtils.hpp BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include)

# Generate package files
xxx_generate_package_module_files()

# Print summaries
xxx_print_dependency_summary()
xxx_print_option_summary()