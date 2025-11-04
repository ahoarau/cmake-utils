cmake_minimum_required(VERSION 3.22...4.1)

include(${CMAKE_CURRENT_SOURCE_DIR}/../../modules/cmake-utils.cmake)

project(test_project 
    VERSION 1.0.0
    DESCRIPTION "A test project for cmake-utils"
    HOMEPAGE_URL "https://example.com/test_project"
    LANGUAGES CXX
)

# Enable testing
xxx_include_ctest()

# Configure defaults
xxx_configure_default_build_type(Release)
xxx_configure_default_binary_dirs()
xxx_configure_default_install_dirs()
xxx_configure_default_install_prefix(${CMAKE_CURRENT_BINARY_DIR}/install)
xxx_configure_apple_rpath()

# Declare options
xxx_option(BUILD_PYTHON_BINDINGS "Build Python bindings" ON)
xxx_option(BUILD_TESTS "Build tests" ON)

# Find dependencies
if(BUILD_PYTHON_BINDINGS)
    xxx_find_nanobind()
endif()

if(BUILD_TESTS)
    xxx_find_package(Catch2 3.4.0 CONFIG REQUIRED)
    include(Catch)
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
xxx_target_enforce_msvc_conformance(test_project PRIVATE)
xxx_target_treat_all_warnings_as_errors(test_project PRIVATE)

# Generate utility headers
set_target_properties(test_project PROPERTIES VERSION ${PROJECT_VERSION})
xxx_target_generate_config_header(test_project PUBLIC)
xxx_target_generate_warning_header(test_project PUBLIC)
xxx_target_generate_deprecated_header(test_project PUBLIC)

# Python bindings
if(BUILD_PYTHON_BINDINGS)
    message(STATUS "[${PROJECT_NAME}] Building Python bindings")
    add_subdirectory(python_bindings)
endif()

# Tests
if(BUILD_TESTS)
    message(STATUS "[${PROJECT_NAME}] Building tests")
    enable_testing()
    add_subdirectory(tests)
endif()

# Declare components
xxx_declare_component(COMPONENT test_project TARGETS test_project)

# Install headers
xxx_target_headers(test_project PUBLIC 
    HEADERS 
        include/test_project/Math.hpp 
    BASE_DIRS 
        include
)
xxx_install_headers()

# Generate package files
xxx_generate_package_module_files()

# Print summaries
xxx_print_dependency_summary()
xxx_print_option_summary()