# gersemi: off
cmake_minimum_required(VERSION 3.22..4.1)

# Usage: xxx_require_variable(<var> [<message>])
# Example: xxx_require_variable(MY_VAR "MY_VAR must be set to build this project")
# Example: xxx_require_variable(MY_VAR) # Will print "MY_VAR is not defined."
function(xxx_require_variable var)
    if(NOT DEFINED ${var})
        if(ARGC EQUAL 1)
            set(msg "Required variable '${ARGV0}' is not defined.")
        else()
            set(msg "${ARGV1}.")
        endif()
        message(FATAL_ERROR "${msg}")
    endif()
endfunction()

# Check if a target exists, otherwise raise a fatal error
function(xxx_require_target target_name)
    if(NOT TARGET ${target_name})
        message(FATAL_ERROR "Target '${target_name}' does not exist.")
    endif()
endfunction()

function(xxx_require_visibility visibility)
    set(vs PRIVATE PUBLIC INTERFACE)
    if(NOT ${visibility} IN_LIST vs)
        message(FATAL_ERROR "visibility (${visibility}) must be one of PRIVATE, PUBLIC or INTERFACE")
    endif()
endfunction()

# Include CTest but simply prevent adding a lot of useless targets. Useful for IDEs.
function(xxx_include_ctest)
    set_property(GLOBAL PROPERTY CTEST_TARGETS_ADDED 1)
    include(CTest)
    # Adding the boosttest_discover_tests function for Boost Unit Testing
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/BoostTestDiscoverTests.cmake)
endfunction()


# Usage: xxx_configure_default_build_type(<default_build_type>)
# Valid values for <default_build_type> are: Debug, Release, MinSizeRel, RelWithDebInfo
# Example: xxx_configure_default_build_type(RelWithDebInfo)
function(xxx_configure_default_build_type default_build_type)
    set(allowed_build_types
        Debug
        Release
        MinSizeRel
        RelWithDebInfo
    )
    if(NOT default_build_type IN_LIST allowed_build_types)
        message(FATAL_ERROR "Invalid build type: ${default_build_type}, valid values are: ${allowed_build_types}")
    endif()

    if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
        message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
        set(CMAKE_BUILD_TYPE ${default_build_type} CACHE STRING "Choose the type of build." FORCE)
        # set the possible values of build type for cmake-gui
        set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS ${allowed_build_types})
    endif()
endfunction()

function(xxx_configure_default_binary_dirs)
    # doc: https://cmake.org/cmake/help/v3.22/manual/cmake-buildsystem.7.html#id47

    if(WIN32)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE PATH "" INTERNAL) # For .exe and .dll add_library(SHARED ...) .dll
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE PATH "" INTERNAL) # for add_library(MODULE ...) .dll
        set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "" INTERNAL) # add_library(STATIC ...) .lib
    else()
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE PATH "" INTERNAL) # For .exe and .dll
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "" INTERNAL) # for shared libraries .so/.dylib and add_library(MODULE ...) .so/.dylib
        set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "" INTERNAL) # add_library(STATIC ...) .a
    endif()

    set(config Debug Release RelWithDebInfo MinSizeRel)
    foreach(conf ${config})
        string(TOUPPER ${conf} conf_upper)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${conf_upper} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY} CACHE PATH "" INTERNAL)
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${conf_upper} ${CMAKE_LIBRARY_OUTPUT_DIRECTORY} CACHE PATH "" INTERNAL)
        set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${conf_upper} ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY} CACHE PATH "" INTERNAL)
    endforeach()
endfunction()

function(xxx_configure_default_install_dirs)
    include(GNUInstallDirs)
    # # On Windows, in order to avoid touching the env vars, the dll needs to be installed in the same directory as executables
    # # TODO: Find out if this is still needed on Windows. 
    # if(WIN32)
    #     set(CMAKE_INSTALL_LIBDIR ${CMAKE_INSTALL_BINDIR} CACHE PATH "Installation directory for dlls" FORCE)
    # endif()
endfunction()

# If not provided by the user, set a default CMAKE_INSTALL_PREFIX. Useful for IDEs.
function(xxx_configure_default_install_prefix default_install_prefix)
    if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        message(STATUS "Setting default install prefix to '${default_install_prefix}'")
        set(CMAKE_INSTALL_PREFIX ${default_install_prefix} CACHE PATH "Install path prefix, prepended onto install directories." FORCE)
        mark_as_advanced(CMAKE_INSTALL_PREFIX)
    endif()
endfunction()

# Enable the most common warnings for MSVC, GCC and Clang
# Adding some extra warning on msvc to mimic gcc/clang behavior
# Usage: xxx_target_set_default_compile_options(<target_name> <visibility>)
# visibility is either PRIVATE, PUBLIC or INTERFACE
# Example: xxx_target_set_default_compile_options(my_target INTERFACE)
function(xxx_target_set_default_compile_options target_name visibility)
    xxx_require_target(${target_name})
    xxx_require_visibility(${visibility})

    # In CMake >= 3.26, use CMAKE_CXX_COMPILER_FRONTEND_VARIANT¶
    # ref: https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_COMPILER_FRONTEND_VARIANT.html
    # ref: https://gitlab.kitware.com/cmake/cmake/-/issues/19724
    if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
        set(CMAKE_CXX_COMPILER_ID "MSVC")
    endif()

    if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${target_name} ${visibility}
            /W4     # Enable most warnings
            /wd4250 # "Inherits via dominance" - happens with diamond inheritance, not really an issue
            /wd4706 # assignment within conditional expression
            /wd5030 # pointer or reference to potentially throwing function used in noexcept context
            /wd4996 # function may be unsafe
            /we4834 # discarding return value of function with 'nodiscard' attribute
            /we4062 # enumerator 'xyz' in switch of enum 'abc' is not handled
        )
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        target_compile_options(${target_name} ${visibility}
            -Wall           # Enable most warnings
            -Wextra         # Enable extra warnings
            -Wconversion    # Warn on type conversions that may lose information
            -Wpedantic      # Warn on non-standard C++ usage
        )
    else()
        message(WARNING "Unknown compiler '${CMAKE_CXX_COMPILER_ID}'. No default compile options set.")
    endif()
endfunction()


# Description: Enforce MSVC c++ conformance mode so msvc behaves more like gcc and clang
# Usage: xxx_target_enforce_msvc_conformance(<target_name> <visibility>)
# visibility is either PRIVATE, PUBLIC or INTERFACE
# Example: xxx_target_enforce_msvc_conformance(my_target INTERFACE)
function(xxx_target_enforce_msvc_conformance target_name visibility)
    xxx_require_visibility(${visibility})

    if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
        set(CMAKE_CXX_COMPILER_ID "MSVC")
    endif()

    if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        return()
    endif()

    target_compile_options(${target_name} ${visibility}
        /permissive-    # Standards conformance
        /Zc:__cplusplus # Needed to have __cplusplus set correctly
        /EHsc           # Enable C++ exceptions standard conformance
        /bigobj         # To avoid "fatal error C1128: number of sections exceeded object file format limit"
    )
endfunction()

# Description: Treat all warnings as errors for a targets (/WX for MSVC, -Werror for GCC/Clang)
# Can be disabled by on the cmake cli with --compile-no-warning-as-error
# ref: https://cmake.org/cmake/help/latest/manual/cmake.1.html#cmdoption-cmake-compile-no-warning-as-error
# Usage: xxx_target_treat_all_warnings_as_errors(<target_name> <visibility>)
# visibility is either PRIVATE, PUBLIC or INTERFACE
# Example: xxx_target_treat_all_warnings_as_errors(my_target PRIVATE)
# NOTE: in CMake 3.24, we have the new CMAKE_COMPILE_WARNING_AS_ERROR option, but for the whole project and subprojects
function(xxx_target_treat_all_warnings_as_errors target_name visibility)
    xxx_require_visibility(${visibility})

    if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
        set(CMAKE_CXX_COMPILER_ID "MSVC")
    endif()

    if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${target_name} ${visibility}
            /WX
        )
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        target_compile_options(${target_name} ${visibility}
            -Werror
        )
    else()
        message(WARNING "Unknown compiler '${CMAKE_CXX_COMPILER_ID}'. No warning as error flag set.")
    endif()
endfunction()

#[[[
# @brief Generates a configuration header for a given target.
#
# This function creates a `config.hpp` file within the build directory for the
# specified target. This header can be used to propagate preprocessor definitions
# and other configuration details to the source code.
#
# @param target_name The name of the target for which the configuration header
#                    is being generated.
# @param visibility  Specifies the visibility of the include directory for the
#                    generated header (e.g., PUBLIC, PRIVATE, INTERFACE).
#]]
# function(xxx_target_generate_config_header target_name visibility)
#     set(options SKIP_INSTALL)
#     set(oneValueArgs OUTPUT INSTALL_DESTINATION)
#     set(multiValueArgs)
#     cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

#     xxx_require_variable(PROJECT_NAME)
#     xxx_require_variable(PROJECT_VERSION)
#     xxx_require_variable(PROJECT_VERSION_MAJOR)
#     xxx_require_variable(PROJECT_VERSION_MINOR)
#     xxx_require_variable(PROJECT_VERSION_PATCH)
#     xxx_require_variable(CMAKE_CURRENT_BINARY_DIR)
#     xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)
#     xxx_require_target(${target_name})
#     xxx_require_visibility(${visibility})

#     set(default_output_file ${CMAKE_CURRENT_BINARY_DIR}/generated/include/${PROJECT_NAME}/config.hpp)
#     set(default_install_destination ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME})

#     # We need PROJECT_NAME in uppercase to match the maestro convention for macro names
#     string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UPPERCASE)

#     # ref: https://cmake.org/cmake/help/latest/variable/CMAKE_CURRENT_FUNCTION_LIST_DIR.html
#     set(input_file ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/config.hpp.in)

#     if(NOT EXISTS ${input_file})
#         message(FATAL_ERROR "Input file ${input_file} does not exist.")
#     endif()

#     if(arg_OUTPUT)
#         set(output_file ${arg_OUTPUT})
#     else()
#         set(output_file ${default_output_file})
#     endif()

#     configure_file(${input_file} ${output_file} @ONLY)

#     target_include_directories(${target_name} ${visibility} 
#         $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/generated/include>
#     )

#     if(arg_SKIP_INSTALL)
#         return()
#     endif()

#     if(${arg_INSTALL_DESTINATION})
#         set(install_destination ${arg_INSTALL_DESTINATION})
#     else()
#         set(install_destination ${default_install_destination})
#     endif()
#     install(FILES ${output_file} DESTINATION ${install_destination})
# endfunction()

# function(xxx_target_generate_warning_header target_name visibility)
#     set(options SKIP_INSTALL)
#     set(oneValueArgs FILENAME HEADER_DIR TEMPLATE_FILE INSTALL_DESTINATION)
#     set(multiValueArgs)
#     cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

#     xxx_require_variable(PROJECT_NAME)
#     xxx_require_variable(CMAKE_CURRENT_BINARY_DIR)
#     xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)
#     xxx_require_target(${target_name})
#     xxx_require_visibility(${visibility})

#     set(filename ${PROJECT_NAME}/warning.hpp)
#     if(arg_FILENAME)
#         set(filename ${arg_FILENAME})
#     endif()

#     set(header_dir ${CMAKE_CURRENT_BINARY_DIR}/generated/include)
#     if(arg_HEADER_DIR)
#         set(header_dir ${arg_HEADER_DIR})
#     endif()

#     set(template_file ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/warning.hpp.in)
#     if(arg_TEMPLATE_FILE)
#         set(template_file ${arg_TEMPLATE_FILE})
#     endif()

#     set(install_destination ${CMAKE_INSTALL_INCLUDEDIR})
#     if(arg_INSTALL_DESTINATION)
#         set(install_destination ${arg_INSTALL_DESTINATION})
#     endif()

#     if(NOT EXISTS ${template_file})
#         message(FATAL_ERROR "Input file ${template_file} does not exist.")
#     endif()

#     set(output_file ${header_dir}/${filename})

#     string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UPPERCASE)
#     configure_file(${template_file} ${output_file} @ONLY)

#     target_include_directories(${target_name} ${visibility} 
#         $<BUILD_INTERFACE:${header_dir}>
#     )

#     if(arg_SKIP_INSTALL)
#         return()
#     endif()

#     install(FILES ${output_file} DESTINATION ${install_destination})
# endfunction()


# function(xxx_target_generate_deprecated_header target_name visibility)
#     set(options SKIP_INSTALL)
#     set(oneValueArgs FILENAME HEADER_DIR TEMPLATE_FILE INSTALL_DESTINATION)
#     set(multiValueArgs)
#     cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

#     xxx_require_variable(PROJECT_NAME)
#     xxx_require_variable(CMAKE_CURRENT_BINARY_DIR)
#     xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)
#     xxx_require_target(${target_name})
#     xxx_require_visibility(${visibility})

#     set(filename ${PROJECT_NAME}/deprecated.hpp)
#     if(arg_FILENAME)
#         set(filename ${arg_FILENAME})
#     endif()

#     set(header_dir ${CMAKE_CURRENT_BINARY_DIR}/generated/include)
#     if(arg_HEADER_DIR)
#         set(header_dir ${arg_HEADER_DIR})
#     endif()

#     set(template_file ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/deprecated.hpp.in)
#     if(arg_TEMPLATE_FILE)
#         set(template_file ${arg_TEMPLATE_FILE})
#     endif()

#     set(install_destination ${CMAKE_INSTALL_INCLUDEDIR})
#     if(arg_INSTALL_DESTINATION)
#         set(install_destination ${arg_INSTALL_DESTINATION})
#     endif()

#     if(NOT EXISTS ${template_file})
#         message(FATAL_ERROR "Input file ${template_file} does not exist.")
#     endif()

#     set(output_file ${header_dir}/${filename})

#     string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UPPERCASE)
#     configure_file(${template_file} ${output_file} @ONLY)

#     target_include_directories(${target_name} ${visibility} 
#         $<BUILD_INTERFACE:${header_dir}>
#     )

#     if(arg_SKIP_INSTALL)
#         return()
#     endif()

#     install(FILES ${output_file} DESTINATION ${install_destination})
# endfunction()

function(xxx_make_valid_c_identifier INPUT OUTPUT_VAR)
    # 1. Replace all non-alphanumeric and non-underscore characters with underscores
    # 2. If it starts with a digit, prefix with underscore
    # 3. Optionally collapse multiple consecutive underscores
    # 4. Remove trailing underscores (optional cosmetic cleanup)
    # 5. Return result to caller

    string(REGEX REPLACE "[^A-Za-z0-9_]" "_" CLEAN "${INPUT}")

    string(REGEX MATCH "^[0-9]" STARTS_WITH_DIGIT "${CLEAN}")
    if(STARTS_WITH_DIGIT)
        set(CLEAN "_${CLEAN}")
    endif()
    string(REGEX REPLACE "_+" "_" CLEAN "${CLEAN}")
    string(REGEX REPLACE "_$" "" CLEAN "${CLEAN}")
    set(${OUTPUT_VAR} "${CLEAN}" PARENT_SCOPE)
endfunction()

function(xxx_target_generate_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR TEMPLATE_FILE INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(PROJECT_NAME)
    xxx_require_variable(CMAKE_CURRENT_BINARY_DIR)
    xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)
    xxx_require_target(${target_name})
    xxx_require_visibility(${visibility})
    
    xxx_require_variable(arg_FILENAME)
    xxx_require_variable(arg_HEADER_DIR)
    xxx_require_variable(arg_TEMPLATE_FILE)
    xxx_require_variable(arg_INSTALL_DESTINATION)

    if(NOT EXISTS ${arg_TEMPLATE_FILE})
        message(FATAL_ERROR "Input file ${arg_TEMPLATE_FILE} does not exist.")
    endif()

    set(output_file ${arg_HEADER_DIR}/${arg_FILENAME})

    xxx_make_valid_c_identifier(${target_name} LIBRARY_NAME)

    # We need to define LIBRARY_NAME_UPPERCASE, TARGET_NAME, TARGET_VERSION, TARGET_VERSION_MAJOR, TARGET_VERSION_MINOR, TARGET_VERSION_PATCH
    string(TOUPPER ${LIBRARY_NAME} LIBRARY_NAME_UPPERCASE)

    # Retrieve version from target
    get_property(library_version TARGET ${target_name} PROPERTY VERSION)
    if(NOT library_version)
        message(WARNING "Target ${target_name} does not have a VERSION property set, using the project version instead (PROJECT_VERSION=${PROJECT_VERSION}).
        To remove this warning, set the VERSION property on the target using:

            set_target_properties(${target_name} PROPERTIES VERSION \${PROJECT_VERSION})
        ")
    endif()
    set(LIBRARY_VERSION ${library_version})
    string(REPLACE "." ";" version_parts ${LIBRARY_VERSION})
    list(GET version_parts 0 LIBRARY_VERSION_MAJOR)
    list(GET version_parts 1 LIBRARY_VERSION_MINOR)
    list(GET version_parts 2 LIBRARY_VERSION_PATCH)

    configure_file(${arg_TEMPLATE_FILE} ${output_file} @ONLY)

    target_include_directories(${target_name} ${visibility} 
        $<BUILD_INTERFACE:${arg_HEADER_DIR}>
    )

    if(arg_SKIP_INSTALL)
        return()
    endif()

    install(FILES ${output_file} DESTINATION ${arg_INSTALL_DESTINATION})
endfunction()

function(xxx_target_generate_warning_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")
    
    xxx_require_variable(PROJECT_NAME)
    xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)

    set(filename ${PROJECT_NAME}/warning.hpp)
    if(arg_FILENAME)
        set(filename ${arg_FILENAME})
    endif()

    set(header_dir ${CMAKE_CURRENT_BINARY_DIR}/generated/include)
    if(arg_HEADER_DIR)
        set(header_dir ${arg_HEADER_DIR})
    endif()

    set(install_destination ${CMAKE_INSTALL_INCLUDEDIR})
    if(arg_INSTALL_DESTINATION)
        set(install_destination ${arg_INSTALL_DESTINATION})
    endif()

    xxx_target_generate_header(${target_name} ${visibility} 
        FILENAME ${filename}
        HEADER_DIR ${header_dir}
        TEMPLATE_FILE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/warning.hpp.in
        INSTALL_DESTINATION ${install_destination}
        SKIP_INSTALL ${arg_SKIP_INSTALL}
    )
endfunction()

function(xxx_target_generate_deprecated_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")
    
    xxx_require_variable(PROJECT_NAME)
    xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)

    set(filename ${PROJECT_NAME}/deprecated.hpp)
    if(arg_FILENAME)
        set(filename ${arg_FILENAME})
    endif()

    set(header_dir ${CMAKE_CURRENT_BINARY_DIR}/generated/include)
    if(arg_HEADER_DIR)
        set(header_dir ${arg_HEADER_DIR})
    endif()

    set(install_destination ${CMAKE_INSTALL_INCLUDEDIR})
    if(arg_INSTALL_DESTINATION)
        set(install_destination ${arg_INSTALL_DESTINATION})
    endif()

    xxx_target_generate_header(${target_name} ${visibility} 
        FILENAME ${filename}
        HEADER_DIR ${header_dir}
        TEMPLATE_FILE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/deprecated.hpp.in
        INSTALL_DESTINATION ${install_destination}
        SKIP_INSTALL ${arg_SKIP_INSTALL}
    )
endfunction()

function(xxx_target_generate_config_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")
    
    xxx_require_variable(PROJECT_NAME)
    xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)
    xxx_require_variable(PROJECT_VERSION)
    xxx_require_variable(PROJECT_VERSION_MAJOR)
    xxx_require_variable(PROJECT_VERSION_MINOR)
    xxx_require_variable(PROJECT_VERSION_PATCH)

    set(filename ${PROJECT_NAME}/config.hpp)
    if(arg_FILENAME)
        set(filename ${arg_FILENAME})
    endif()

    set(header_dir ${CMAKE_CURRENT_BINARY_DIR}/generated/include)
    if(arg_HEADER_DIR)
        set(header_dir ${arg_HEADER_DIR})
    endif()

    set(install_destination ${CMAKE_INSTALL_INCLUDEDIR})
    if(arg_INSTALL_DESTINATION)
        set(install_destination ${arg_INSTALL_DESTINATION})
    endif()

    xxx_target_generate_header(${target_name} ${visibility} 
        FILENAME ${filename}
        HEADER_DIR ${header_dir}
        TEMPLATE_FILE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/config.hpp.in
        INSTALL_DESTINATION ${install_destination}
        SKIP_INSTALL ${arg_SKIP_INSTALL}
    )
endfunction()

function(xxx_target_generate_tracy_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")
    
    xxx_require_variable(PROJECT_NAME)
    xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)
    xxx_require_variable(PROJECT_VERSION)
    xxx_require_variable(PROJECT_VERSION_MAJOR)
    xxx_require_variable(PROJECT_VERSION_MINOR)
    xxx_require_variable(PROJECT_VERSION_PATCH)

    set(filename ${PROJECT_NAME}/tracy.hpp)
    if(arg_FILENAME)
        set(filename ${arg_FILENAME})
    endif()

    set(header_dir ${CMAKE_CURRENT_BINARY_DIR}/generated/include)
    if(arg_HEADER_DIR)
        set(header_dir ${arg_HEADER_DIR})
    endif()

    set(install_destination ${CMAKE_INSTALL_INCLUDEDIR})
    if(arg_INSTALL_DESTINATION)
        set(install_destination ${arg_INSTALL_DESTINATION})
    endif()

    xxx_target_generate_header(${target_name} ${visibility} 
        FILENAME ${filename}
        HEADER_DIR ${header_dir}
        TEMPLATE_FILE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/tracy.hpp.in
        INSTALL_DESTINATION ${install_destination}
        SKIP_INSTALL ${arg_SKIP_INSTALL}
    )
endfunction()

# Usage: xxx_find_package(<package> [version] [REQUIRED] [COMPONENTS ...] MODULE_PATH <path_to_find_module>)
# ref: https://cmake.org/cmake/help/latest/command/find_package.html
# This function allows to automatically retrieve the imported targets provided by the package
# and store info in global properties for later use (e.g. when exporting dependencies)
# Note: this needs to be a macro so find_package can leak variables (like Python_SITELIB)
macro(xxx_find_package)
    string(ASCII 27 Esc)
    message("${Esc}[1;34m" "[${ARGV0}]" "${Esc}[m")
    message(DEBUG "Executing xxx_find_package with args ${ARGV}")

    set(options)
    set(oneValueArgs MODULE_PATH)
    set(multiValueArgs)
    cmake_parse_arguments(arg "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Pkg name is the first argument of find_package(<pkg_name> ...)
    set(package_name ${ARGV0})

    # Handle custom module file
    if(arg_MODULE_PATH)
        set(module_file "${arg_MODULE_PATH}/Find${package_name}.cmake")
        # check if file exists
        if(NOT EXISTS ${module_file})
            message(FATAL_ERROR "Custom module file ${module_file} does not exist.")
        endif()

        # Copy the module file to the generated cmake directory in the build dir
        file(COPY ${module_file} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME}/modules/${package_name})

        # Add the parent path to the CMAKE_MODULE_PATH
        list(APPEND CMAKE_MODULE_PATH ${arg_MODULE_PATH})
        message("   Using custom module file: ${module_file}")
    endif()

    # Call find_package with the provided arguments
    string(REPLACE ";" " " fp_pp "${arg_UNPARSED_ARGUMENTS}")
    message("   Executing find_package(${fp_pp})")

    # Saving the list of imported targets and variables BEFORE the call to find_package
    get_property(imported_targets_before DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY IMPORTED_TARGETS)
    get_property(variables_before DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VARIABLES)

    find_package(${arg_UNPARSED_ARGUMENTS}) # TODO: handle QUIET properly

    # Getting the list of imported targets and variables AFTER the call to find_package
    get_property(new_variables DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VARIABLES)
    get_property(imported_targets DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY IMPORTED_TARGETS)

    list(REMOVE_ITEM new_variables ${variables_before} variables_before)
    list(REMOVE_ITEM imported_targets ${imported_targets_before})

    string(REPLACE ";" ", " new_variables_pp "${new_variables}")
    message(DEBUG "   New variables detected: ${new_variables_pp}")

    string(REPLACE ";" ", " imported_targets_pp "${imported_targets}")
    message("   Imported targets detected: ${imported_targets_pp}")

    set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_packages_found "${package_name}" APPEND)
    set_property(GLOBAL PROPERTY _xxx_${package_name}_imported_targets "${imported_targets}")
    set_property(GLOBAL PROPERTY _xxx_${package_name}_find_package_args "${arg_UNPARSED_ARGUMENTS}")
    set_property(GLOBAL PROPERTY _xxx_${package_name}_module_path "${arg_MODULE_PATH}")

    # Save the reverse link between the imported targets and the original package name
    foreach(target ${imported_targets})
        set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_${target}_package_name "${package_name}")
    endforeach()

    unset(package_name)
    unset(module_file)
    unset(imported_targets_before)
    unset(variables_before)
    unset(new_variables)
    unset(imported_targets)
    unset(new_variables_pp)
    unset(imported_targets_pp)
endmacro()

function(xxx_print_dependency_summary)
    include(CMakePrintHelpers)

    get_property(packages GLOBAL PROPERTY _xxx_${PROJECT_NAME}_packages_found)
    if(NOT packages)
        message(STATUS "No dependencies found via xxx_find_package.")
        return()
    endif()

    message(STATUS "Dependencies found via xxx_find_package:")
    foreach(package_name ${packages})
        # Try to find the _xxx_<package_name>_expected_targets property
        get_property(imported_targets GLOBAL PROPERTY _xxx_${package_name}_imported_targets)
        if(NOT imported_targets)
            set(imported_targets "None")
        endif()

        # Replace ; by , for better readability
        string(REPLACE ";" " " imported_targets_pp "${imported_targets}")
        message(STATUS "    package [${package_name}] ==> targets [${imported_targets_pp}]")

        # Print target properties
        if(imported_targets STREQUAL "None")
            continue()
        endif()
        cmake_print_properties(TARGETS ${imported_targets} PROPERTIES
            LOCATION
            INCLUDE_DIRECTORIES
            COMPILE_DEFINITIONS
            COMPILE_OPTIONS
            COMPILE_FEATURES
            COMPILE_FLAGS
            COMPILE_OPTIONS
            LINK_LIBRARIES
            LINK_OPTIONS
            INTERFACE_INCLUDE_DIRECTORIES
            INTERFACE_COMPILE_DEFINITIONS
            INTERFACE_COMPILE_OPTIONS
            INTERFACE_LINK_LIBRARIES
            INTERFACE_LINK_OPTIONS
        )
    endforeach()
endfunction()

# Usage: xxx_export_dependencies(EXPORT <export_name> FILE <output_file> DESTINATION <install_destination> TARGETS <target1> <target2> ...)
# This function analyzes the link libraries of the provided targets,
# determines which packages are needed and generates a <export_name>-dependencies.cmake file
function(xxx_export_dependencies)
    set(options)
    set(oneValueArgs EXPORT FILE DESTINATION MATO)
    set(multiValueArgs TARGETS)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(arg_EXPORT)
    xxx_require_variable(arg_FILE)
    xxx_require_variable(arg_TARGETS)
    xxx_require_variable(arg_DESTINATION)

    # Get all BUILDSYSTEM_TARGETS of the current project (i.e. added via add_library/add_executable)
    # We need this to filter out internal targets when analyzing link libraries
    get_property(buildsystem_targets DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY BUILDSYSTEM_TARGETS)

    set(all_link_libraries_only_targets "")
    foreach(target ${arg_TARGETS})
        # Note: On CMake 3.23, we have LINK_LIBRARIES_ONLY_TARGETS that might be useful
        set(ll "")
        get_target_property(interface_link_libraries ${target} INTERFACE_LINK_LIBRARIES)
        list(APPEND ll ${interface_link_libraries})

        get_target_property(link_libraries ${target} LINK_LIBRARIES)
        list(APPEND ll ${link_libraries})

        message("Linked libraries of target '${target}':
            LINK_LIBRARIES          : ${link_libraries}
            INTERFACE_LINK_LIBRARIES: ${interface_link_libraries}
        ")

        # Filter only targets
        set(link_libraries_only_targets "")
        foreach(l ${ll})
            if(TARGET ${l})
                get_target_property(original_target ${l} ALIASED_TARGET)
                if(original_target)
                    list(APPEND link_libraries_only_targets ${original_target})
                else()
                    list(APPEND link_libraries_only_targets ${l})
                endif()
            endif()
        endforeach()

        list(APPEND all_link_libraries_only_targets ${link_libraries_only_targets})
    endforeach()

    # filter buildsystem targets and imported targets
    set(link_imported_libraries "")
    set(link_buildsystem_libraries "")
    foreach(l ${all_link_libraries_only_targets})
        if(l IN_LIST buildsystem_targets)
            list(APPEND link_buildsystem_libraries ${l})
        else()
            list(APPEND link_imported_libraries ${l})
        endif()
    endforeach()

    message("All link libraries of targets '${arg_TARGETS}': 
        Imported Libraries              : ${link_imported_libraries}
        BuildSystem(Internal) Libraries : ${link_buildsystem_libraries}
    ")

    # At this point, we have the list of imported libraries
    # We now retrieve the original package name for each imported library
    set(packages_to_export "")
    foreach(target ${link_imported_libraries})
        get_property(package_name GLOBAL PROPERTY _xxx_${PROJECT_NAME}_${target}_package_name)

        if(NOT package_name)
            message(WARNING "Could not find the package name for target '${target}'. Cannot automatically export dependency. Did you forget to use xxx_find_package() ?")
            continue()
        endif()

        message("Library '${target}' comes from package '${package_name}'")
        list(APPEND packages_to_export ${package_name})
    endforeach()

    message("Packages to export for EXPORT ${arg_EXPORT}: ${packages_to_export}")

    # Now we generate the <target>-dependencies.cmake file with the list of packages, imported targets and custom modules
    set(modules "")
    set(fd "")
    foreach(package_name ${packages_to_export})
        get_property(expected_targets GLOBAL PROPERTY _xxx_${package_name}_imported_targets)
        get_property(find_package_args GLOBAL PROPERTY _xxx_${package_name}_find_package_args)
        get_property(module_path GLOBAL PROPERTY _xxx_${package_name}_module_path)

        xxx_require_variable(find_package_args "find_package_args must be defined for package ${package_name}")
        xxx_require_variable(expected_targets "expected_targets must be defined for package ${package_name}")

        string(REPLACE ";" " " find_package_args "${find_package_args}")

        # Custom Modules
        if(module_path)
            string(APPEND modules "list(APPEND CMAKE_MODULE_PATH \${CMAKE_CURRENT_LIST_DIR}/modules/${package_name})\n")
            install(
                FILES ${module_path}/Find${package_name}.cmake
                DESTINATION ${arg_DESTINATION}/modules/${package_name}
            )
        endif()

        # Find Dependencies
        if(NOT expected_targets)
            string(APPEND fd "find_dependency(${find_package_args})\n")
        else()
            set(cond "")
            foreach(target IN LISTS expected_targets)
                if(cond STREQUAL "")
                    set(cond "NOT TARGET ${target}")
                else()
                    set(cond "${cond} OR NOT TARGET ${target}")
                endif()
            endforeach()

            string(APPEND fd "if(${cond})\n")
            string(APPEND fd "    find_dependency(${find_package_args})\n")
            string(APPEND fd "endif()\n\n")
        endif()
    endforeach()

    set(xxx_modules ${modules})
    set(xxx_find_dependencies ${fd})

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/dependencies.cmake.in ${arg_FILE} @ONLY)

    install(
        FILES ${arg_FILE}
        DESTINATION ${arg_DESTINATION}
    )
endfunction()

# Declare a component for the current project.
# Each component declared and associated to a set of targets will have its own <package>-<component>-targets.cmake 
# and  <target>-<component>-dependencies.cmake generated.
# Components are used as follow: find_package(<package> CONFIG REQUIRED COMPONENTS <component1> <component2> ...)
function(xxx_declare_component)
    set(options)
    set(oneValueArgs COMPONENT)
    set(multiValueArgs TARGETS)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(PROJECT_NAME)
    xxx_require_variable(arg_TARGETS)
    xxx_require_variable(arg_COMPONENT)

    # Check component is not already declared
    get_property(existing_components GLOBAL PROPERTY _xxx_${PROJECT_NAME}_components)
    if(${arg_COMPONENT} IN_LIST existing_components)
        message(FATAL_ERROR "Component '${arg_COMPONENT}' is already declared for project '${PROJECT_NAME}'.")
    endif()

    # Check if target is already in a component
    foreach(component ${existing_components})
        get_property(component_targets GLOBAL PROPERTY _xxx_${PROJECT_NAME}_${component}_targets)
        foreach(target ${arg_TARGETS})
            if(${target} IN_LIST component_targets)
                message(FATAL_ERROR "Target '${target}' is already part of component '${component}'. Cannot add it to component '${arg_COMPONENT}'.")
            endif()
        endforeach()
    endforeach()

    message("Declaring component '${arg_COMPONENT}' with targets: ${arg_TARGETS}")
    set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_components ${arg_COMPONENT} APPEND)
    set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_${arg_COMPONENT}_targets ${arg_TARGETS})
endfunction()

# Declare headers for target (to be installed later)
# xxx_target_headers(<target>
#   HEADERS <list_of_headers>
#   BASE_DIRS <list_of_base_dirs> # Optional, default is empty
# )
function(xxx_target_headers target visibility)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs HEADERS BASE_DIRS)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(arg_HEADERS)
    xxx_require_target(${target})
    xxx_require_visibility(${visibility})

    if(NOT arg_BASE_DIRS)
        set(arg_BASE_DIRS "")
    endif()

    # Add the header to the target sources (for IDEs)
    foreach(header ${arg_HEADERS})
        cmake_path(IS_ABSOLUTE header is_abs)
        if(is_abs)
            message(FATAL_ERROR "Header '${header}' is an absolute path. It should be a relative path to the current source directory.")
        endif()
        target_sources(${target} ${visibility}
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${header}>
            $<INSTALL_INTERFACE:${header}>)
    endforeach()

    # Save the headers in a property of the target
    # NOTE: The PUBLIC_HEADER technically works, but does not support base_dirs
    # cf: https://cmake.org/cmake/help/latest/command/install.html#install
    set_target_properties(${target} PROPERTIES _xxx_${visibility}_headers "${arg_HEADERS}")
    set_target_properties(${target} PROPERTIES _xxx_${visibility}_header_base_dirs "${arg_BASE_DIRS}")
endfunction()

# Install declared header for a given target
# For a whole project, use xxx_install_headers() instead
function(xxx_target_install_headers target)
    set(options)
    set(oneValueArgs DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_target(${target})

    if(NOT arg_DESTINATION)
        set(install_destination ${CMAKE_INSTALL_INCLUDEDIR})
    else()
        set(install_destination ${arg_DESTINATION})
    endif()

    # Retrieve PUBLIC and INTERFACE headers and base directories from target properties
    set(vs PUBLIC INTERFACE)
    set(headers "")
    set(base_dirs "")
    foreach(visibility ${vs})
        get_property(h TARGET ${target} PROPERTY _xxx_${visibility}_headers)
        get_property(bd TARGET ${target} PROPERTY _xxx_${visibility}_header_base_dirs)

        if(h)
            list(APPEND headers ${h})
        endif()
        if(bd)
            list(APPEND base_dirs ${bd})
        endif()
    endforeach()

    if(NOT headers)
        return()
    endif()

    # Install headers, preserving directory structure
    foreach(header ${headers})
        cmake_path(IS_ABSOLUTE header is_abs)
        if(is_abs)
            message(FATAL_ERROR "Header '${header}' is an absolute path. It should be a relative path to the source directory.")
        endif()

        # Determine the relative path from base_dirs
        set(relative_path "")
        foreach(base_dir ${base_dirs})
            string(FIND ${header} ${base_dir} pos)
            if(pos EQUAL 0)
                # base_dir is a prefix of header
                string(REPLACE ${base_dir} "" relative_path ${header})
                # Remove leading '/' or '\' if present
                string(REGEX REPLACE "^[\\/]" "" relative_path ${relative_path})
                break()
            endif()
        endforeach()

        if(relative_path)
            cmake_path(GET relative_path PARENT_PATH header_dir)
            install(FILES ${header} DESTINATION ${install_destination}/${header_dir})
        else()
            # No base directory matched, install without subdirectory
            install(FILES ${header} DESTINATION ${install_destination})
        endif()
    endforeach()
endfunction()

# For each component, install declared headers for all targets.
# See xxx_target_headers() to declare headers for a target.
function(xxx_install_headers)
    set(options)
    set(oneValueArgs DESTINATION)
    set(multiValueArgs COMPONENTS)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(PROJECT_NAME)

    if(arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unrecognized arguments: ${arg_UNPARSED_ARGUMENTS}")
    endif()

    if(NOT arg_DESTINATION)
        set(install_destination ${CMAKE_INSTALL_INCLUDEDIR})
    else()
        set(install_destination ${arg_DESTINATION})
    endif()

    get_property(declared_components GLOBAL PROPERTY _xxx_${PROJECT_NAME}_components)

    set(components "")
    if(arg_COMPONENTS)
        set(components ${arg_COMPONENTS})
    else()
        if(NOT declared_components)
            message(FATAL_ERROR "No components declared for project '${PROJECT_NAME}'. Cannot install headers. Use xxx_declare_component() first.")
        endif()
        set(components ${declared_components})
        message("No components specified, installing headers for all declared components. Declared components: ${declared_components}")
    endif()

    foreach(component ${components})
        if(NOT component IN_LIST declared_components)
            message(FATAL_ERROR "Component '${component}' is not declared for project '${PROJECT_NAME}'.")
        endif()

        get_property(targets GLOBAL PROPERTY _xxx_${PROJECT_NAME}_${component}_targets)
        if(NOT targets)
            message(WARNING "No targets found for component '${component}'. Skipping.")
            continue()
        endif()

        foreach(target ${targets})
            message("Installing headers for target '${target}' of component '${component}' to '${install_destination}'")
            xxx_target_install_headers(${target} DESTINATION ${install_destination})
        endforeach()
    endforeach()
endfunction()

# Generate the package modules files:
#  - <package>-config.cmake
#  - <package>-version.cmake
#  - <package>-<componentA>-targets.cmake
#  - <package>-<componentA>-dependencies.cmake
#  - <package>-<componentB>-targets.cmake
#  - <package>-<componentB>-dependencies.cmake
function(xxx_generate_package_module_files)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    include(CMakePackageConfigHelpers)
    xxx_require_variable(PROJECT_NAME)
    xxx_require_variable(PROJECT_VERSION)
    xxx_require_variable(CMAKE_INSTALL_BINDIR)
    xxx_require_variable(CMAKE_INSTALL_LIBDIR)
    xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)

    get_property(declared_components GLOBAL PROPERTY _xxx_${PROJECT_NAME}_components)
    if(NOT declared_components)
        message(FATAL_ERROR "No components declared for project '${PROJECT_NAME}'.")
    endif()

    # NOTE: Expose as options if needed
    set(PACKAGE_CONFIG_INPUT ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/config.cmake.in)
    set(PACKAGE_CONFIG_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME}/${PROJECT_NAME}-config.cmake)
    set(PACKAGE_VERSION ${PROJECT_VERSION})
    set(PACKAGE_VERSION_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME}/${PROJECT_NAME}-version.cmake)
    set(PACKAGE_VERSION_COMPATIBILITY AnyNewerVersion)
    set(PACKAGE_VERSION_ARCH_INDEPENDENT "")
    set(DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})
    set(NO_SET_AND_CHECK_MACRO "NO_SET_AND_CHECK_MACRO")
    set(NO_CHECK_REQUIRED_COMPONENTS_MACRO "NO_CHECK_REQUIRED_COMPONENTS_MACRO")
    set(NAMESPACE "${PROJECT_NAME}::")

    string(REPLACE ";" " " xxx_project_components "${declared_components}")

    # <package>-config.cmake
    configure_package_config_file(
      ${PACKAGE_CONFIG_INPUT}
      ${PACKAGE_CONFIG_OUTPUT}
      INSTALL_DESTINATION ${DESTINATION}
      ${NO_SET_AND_CHECK_MACRO}
      ${NO_CHECK_REQUIRED_COMPONENTS_MACRO}
    )
    install(
        FILES ${PACKAGE_CONFIG_OUTPUT}
        DESTINATION ${DESTINATION}
    )

    # <package>-version.cmake
    write_basic_package_version_file(
      ${PACKAGE_VERSION_OUTPUT}
      VERSION ${PACKAGE_VERSION}
      COMPATIBILITY ${PACKAGE_VERSION_COMPATIBILITY}
      ${PACKAGE_VERSION_ARCH_INDEPENDENT}
    )
    install(
        FILES ${OUTPUT}
        DESTINATION ${DESTINATION}
    )

    foreach(component ${declared_components})
        message("Generating cmake module files for component '${component}'")

        get_property(targets GLOBAL PROPERTY _xxx_${PROJECT_NAME}_${component}_targets)

        # <package>-<component>-dependencies.cmake
        xxx_export_dependencies(
            TARGETS ${targets}
            EXPORT ${PROJECT_NAME}-${component}
            FILE ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME}/${PROJECT_NAME}-${component}-dependencies.cmake
            DESTINATION ${DESTINATION}
        )
        # Create the export for the component targets
        install(TARGETS ${targets}
            EXPORT ${PROJECT_NAME}-${component}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        )
        # <package>-<component>-targets.cmake
        install(EXPORT ${PROJECT_NAME}-${component}
            FILE ${PROJECT_NAME}-${component}-targets.cmake
            NAMESPACE ${NAMESPACE}
            DESTINATION ${DESTINATION}
        )

        # HACK: Copy the generated targets file to the generated cmake directory, so that we can install all cmake files in one go
        # ref: https://github.com/Kitware/CMake/blob/master/Source/cmInstallExportGenerator.cxx#L50-L58
        # string(MD5 destdir_hash ${DESTINATION})
        # set(generated_target_file ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/Export/${destdir_hash}/${PROJECT_NAME}-${component}-targets.cmake)
        # set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_generated_target_file ${generated_target_file} APPEND)
        # cmake_language(DEFER DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} CALL _xxx_copy_generated_target_files())
    endforeach()
endfunction()

# Copy all generated target files accumulated in the _xxx_<project>_generated_target_file property
# cf: function xxx_generate_package_module_files()
# note: this function is called via cmake_language(DEFER ...)
# /!\ DO NOT CALL THIS FUNCTION DIRECTLY /!\
function(_xxx_copy_generated_target_files)
    get_property(generated_files GLOBAL PROPERTY _xxx_${PROJECT_NAME}_generated_target_file)
    set(destination ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME})
    foreach(f ${generated_files})
        message(DEBUG "Copying generated targets file '${f}' to '${destination}'")
        file(COPY ${f} DESTINATION ${destination})
    endforeach()
endfunction()


# xxx_option(<option_name> <description> <default_value>)
# Example: xxx_option(BUILD_TESTING "Build the tests" ON)
# Override cmake option() to get a nice summary at the end of the configuration step
function(xxx_option option_name description default_value)
    xxx_require_variable(option_name)
    xxx_require_variable(description)
    xxx_require_variable(default_value)

    # The call to the original option()
    option(${ARGV})

    # Save the default value in a property
    set_property(GLOBAL PROPERTY _xxx_option_${option_name}_default_value ${default_value})

    # Save the option name in the list
    set_property(GLOBAL PROPERTY _xxx_project_option_names ${option_name} APPEND)
endfunction()

# Helper function: pad or truncate a string to a fixed width
function(pad_string input width output_var)
    string(LENGTH "${input}" _len)
    if(_len GREATER width)
        # Truncate if too long
        string(SUBSTRING "${input}" 0 ${width} _padded)
    else()
        # Pad with spaces until desired width
        math(EXPR _pad "${width} - ${_len}")
        set(_spaces "")
        while(_pad GREATER 0)
            string(APPEND _spaces " ")
            math(EXPR _pad "${_pad} - 1")
        endwhile()
        set(_padded "${input}${_spaces}")
    endif()
    set(${output_var} "${_padded}" PARENT_SCOPE)
endfunction()


# Print all options defined via xxx_option() in a nice table
# Usage: xxx_print_option_summary()
function(xxx_print_option_summary)
    get_property(option_names GLOBAL PROPERTY _xxx_project_option_names)
    if(NOT option_names)
        message(STATUS "No options defined via xxx_option.")
        return()
    endif()

    message( "")
    message( "================= Configuration Summary ======================================")
    message( "")
    pad_string("Option"      40 _menu_option)
    pad_string("Type"        5  _menu_type)
    pad_string("Value"       8  _menu_value)
    pad_string("Default"     5  _menu_default)
    pad_string("Description (default)" 25 _menu_description)
    message( "${_menu_option} | ${_menu_type} | ${_menu_value} | ${_menu_description}")
    message( "------------------------------------------------------------------------------")

    foreach(option_name ${option_names})
        get_property(_type CACHE ${option_name} PROPERTY TYPE)
        get_property(_val CACHE ${option_name} PROPERTY VALUE)
        get_property(_default GLOBAL PROPERTY _xxx_option_${option_name}_default_value)
        get_property(_help CACHE ${option_name} PROPERTY HELPSTRING)

        pad_string("${option_name}"      40 _name)
        pad_string("${_type}"     5 _type)
        pad_string("${_val}"      8 _val)
        pad_string("${_default}"  5 _default)
        pad_string("${_help}"     25 _help)

        message( "${_name} | ${_type} | ${_val} | ${_help} (${_default})")
    endforeach()

    message( "----------------------------------------------------------")
    message( "")
endfunction()

# Shortcut to find Python package and check main variables
# Usage: xxx_find_python([version] [REQUIRED] [COMPONENTS ...])
# Example: xxx_find_python(3.8 REQUIRED COMPONENTS Interpreter Development.Module)
macro(xxx_find_python)
    xxx_find_package(Python ${ARGN})
    xxx_require_variable(Python_EXECUTABLE)
    xxx_require_variable(Python_INCLUDE_DIRS)
    xxx_require_variable(Python_LIBRARIES)
    xxx_require_variable(Python_SITELIB)

    message(DEBUG "[${PROJECT_NAME}]
        Python executable           : ${Python_EXECUTABLE}
        Python include directories  : ${Python_INCLUDE_DIRS}
        Python libraries            : ${Python_LIBRARIES}
        Python sitelib              : ${Python_SITELIB}
    ")
endmacro()

# Shortcut to find the nanobind package
# Usage: xxx_find_nanobind()
macro(xxx_find_nanobind)
    xxx_find_python(3.8 REQUIRED COMPONENTS Interpreter Development.Module)

    # Detect the installed nanobind package and import it into CMake
    # ref: https://nanobind.readthedocs.io/en/latest/building.html#finding-nanobind
    execute_process(
      COMMAND ${Python_EXECUTABLE} -m nanobind --cmake_dir
      OUTPUT_STRIP_TRAILING_WHITESPACE
      OUTPUT_VARIABLE nanobind_ROOT
    )
    message(DEBUG "[${PROJECT_NAME}] nanobind cmake directory: ${nanobind_ROOT}")
    xxx_find_package(nanobind CONFIG REQUIRED)
endmacro()

# gersemi: on
