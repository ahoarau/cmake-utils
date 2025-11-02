cmake_minimum_required(VERSION 3.22...4.1)
project(cmake-utils)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake-utils.cmake)

set(BUILD_TESTS ${PROJECT_IS_TOP_LEVEL} CACHE BOOL "Build the test suite")

if(BUILD_TESTS)
    add_subdirectory(test_project)
endif()
