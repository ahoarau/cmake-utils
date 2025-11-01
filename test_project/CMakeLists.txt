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
add_library(test_project SHARED)
target_sources(test_project PRIVATE
    src/Math.cpp
    src/StringUtils.cpp
)
target_include_directories(test_project PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
target_compile_features(test_project PUBLIC cxx_std_17)

# Set compile options
xxx_target_set_default_compile_options(test_project PUBLIC)
xxx_target_generate_config_header(test_project PUBLIC)

include(GenerateExportHeader)
generate_export_header(test_project
    EXPORT_FILE_NAME ${CMAKE_CURRENT_BINARY_DIR}/generated/include/test_project/export.hpp
)

# Declare components
xxx_declare_component(COMPONENT test_project TARGETS test_project)

# Python bindings
if(BUILD_PYTHON_BINDINGS)
    add_subdirectory(python_bindings)
endif()

# Install headers
xxx_target_headers(test_project PUBLIC HEADERS include/test_project/Math.hpp BASE_DIRS include)

# Generate package files
xxx_generate_package_module_files()

# Print summaries
xxx_print_dependency_summary()
xxx_print_option_summary()