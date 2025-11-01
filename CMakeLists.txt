cmake_minimum_required(VERSION 3.22...4.1)
project(cmake-utils)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake-utils.cmake)

include(CTest)

if(BUILD_TESTING)
    enable_testing()
    add_subdirectory(test_project)
endif()
