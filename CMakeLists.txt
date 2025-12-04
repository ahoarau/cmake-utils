cmake_minimum_required(VERSION 3.22...4.1)
project(cmake-utils VERSION 0.1.0)

include(${CMAKE_CURRENT_SOURCE_DIR}/modules/cmake-utils.cmake)

if(NOT PROJECT_IS_TOP_LEVEL)
    return()
endif()

include(GNUInstallDirs)

install(
    DIRECTORY external-modules find-modules modules templates
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

xxx_export_package(PACKAGE_CONFIG_TEMPLATE config.cmake.in)
