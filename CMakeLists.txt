cmake_minimum_required(VERSION 3.22...4.1)
project(cmake-utils VERSION 0.1.0)

include(${CMAKE_CURRENT_SOURCE_DIR}/modules/cmake-utils.cmake)

set(CMAKE_UTILS_BUILD_TESTS ${PROJECT_IS_TOP_LEVEL} CACHE BOOL "Build the test suite")
set(CMAKE_UTILS_BUILD_PYTHON_BINDINGS
    ${PROJECT_IS_TOP_LEVEL}
    CACHE BOOL
    "Build the Python bindings for the test suite"
)

if(CMAKE_UTILS_BUILD_TESTS)
    enable_testing()
    set(TEST_PROJECT_BUILD_TESTS ${CMAKE_UTILS_BUILD_TESTS})
    set(TEST_PROJECT_BUILD_PYTHON_BINDINGS ${CMAKE_UTILS_BUILD_PYTHON_BINDINGS})
    add_subdirectory(tests EXCLUDE_FROM_ALL)
endif()

if(NOT PROJECT_IS_TOP_LEVEL)
    return()
endif()

include(GNUInstallDirs)

install(
    DIRECTORY external-modules find-modules modules templates
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

xxx_export_package(PACKAGE_CONFIG_TEMPLATE config.cmake.in)
