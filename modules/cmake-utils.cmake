cmake_minimum_required(VERSION 3.22...4.1)

function(_xxx_integrate_modules)
    set(utils_ROOT ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/..)
    cmake_path(CONVERT "${utils_ROOT}" TO_CMAKE_PATH_LIST utils_ROOT NORMALIZE)

    # Adding the pytest_discover_tests function for pytest
    # repo: https://github.com/python-cmake/pytest-cmake
    include(${utils_ROOT}/external-modules/pytest-cmake/PytestAddTests.cmake)
    include(${utils_ROOT}/external-modules/pytest-cmake/PytestDiscoverTests.cmake)

    # Adding the boosttest_discover_tests function for Boost Unit Testing
    # repo: https://github.com/DenizThatMenace/cmake-modules
    include(${utils_ROOT}/external-modules/boost-test/BoostTestDiscoverTests.cmake)

    # boostpy_add_module and boostpy_add_stubs
    include(${utils_ROOT}/modules/BoostPython.cmake)

    include(${utils_ROOT}/modules/PrintSystemInfo.cmake)
    include(${utils_ROOT}/modules/CheckPythonModuleName.cmake)
endfunction()

_xxx_integrate_modules()

# Copy compile_commands.json from the binary dir to the upper source directory for clangd support
function(copy_compile_commands_in_source_dir)
    set(source ${CMAKE_BINARY_DIR}/compile_commands.json)
    set(destination ${CMAKE_SOURCE_DIR}/compile_commands.json)

    if(CMAKE_EXPORT_COMPILE_COMMANDS AND EXISTS ${source})
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E copy_if_different ${source} ${destination}
        )
    endif()
endfunction()

# Launch the copy at the end of the configuration step
function(xxx_configure_copy_compile_commands_in_source_dir)
    cmake_language(DEFER DIRECTORY ${CMAKE_SOURCE_DIR} GET_CALL_IDS _ids)
    set(call_id 03e6a81d-6918-4da7-a4f4-a3dd74f61cef)
    if(NOT _ids OR NOT ${call_id} IN_LIST _ids)
        message(
            DEBUG
            "Configuring copy of compile_commands.json to source directory (CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR}) at end of configuration step."
        )
        cmake_language(
            DEFER ID ${call_id} DIRECTORY ${CMAKE_SOURCE_DIR}
            CALL copy_compile_commands_in_source_dir
            ()
        )
    endif()
endfunction()

# Usage: xxx_require_variable(<var> [<message>])
# Example: xxx_require_variable(MY_VAR "MY_VAR must be set to build this project")
# Example: xxx_require_variable(MY_VAR) # Will print "MY_VAR is not defined."
function(xxx_require_variable var)
    if(NOT DEFINED ${var})
        if(ARGC EQUAL 1)
            set(msg "Required variable '${ARGV0}' is not defined.")
        else()
            set(msg "${ARGV1}")
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
        message(
            FATAL_ERROR
            "visibility (${visibility}) must be one of PRIVATE, PUBLIC or INTERFACE"
        )
    endif()
endfunction()

function(xxx_check_file_exists filepath)
    if(NOT EXISTS ${filepath})
        message(FATAL_ERROR "File '${filepath}' does not exist.")
    endif()
endfunction()

# Include CTest but simply prevent adding a lot of useless targets. Useful for IDEs.
macro(xxx_include_ctest)
    set_property(GLOBAL PROPERTY CTEST_TARGETS_ADDED 1)
    include(CTest)
endmacro()

# TODO: See if the following rpath configuration is still needed with modern cmake versions
# macro(xxx_configure_apple_rpath)
#   if(APPLE) # Ensure that the policy if is only applied on OSX systems
#     xxx_require_variable(CMAKE_INSTALL_LIBDIR)

#     set(CMAKE_MACOSX_RPATH True CACHE BOOL "")
#     set(CMAKE_SKIP_BUILD_RPATH False CACHE BOOL "")
#     set(CMAKE_BUILD_WITH_INSTALL_RPATH False CACHE BOOL "")
#     set(CMAKE_INSTALL_RPATH_USE_LINK_PATH True CACHE BOOL "")
#     set(CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_LIBDIR} CACHE PATH "")
#   endif()
# endmacro()

# Usage: xxx_configure_default_build_type(<build_type>)
# Usual values for <build_type> are: Debug, Release, MinSizeRel, RelWithDebInfo
# Example: xxx_configure_default_build_type(RelWithDebInfo)
function(xxx_configure_default_build_type build_type)
    set(standard_build_types Debug Release MinSizeRel RelWithDebInfo)
    if(NOT build_type IN_LIST standard_build_types)
        message(
            AUTHOR_WARNING
            "Unusual build type provided: ${build_type}, standard values are: ${standard_build_types}"
        )
    endif()

    if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
        message(STATUS "Setting build type to '${build_type}' as none was specified.")
        set(CMAKE_BUILD_TYPE ${build_type} CACHE STRING "Choose the type of build." FORCE)
        # set the possible values of build type for cmake-gui
        set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS ${allowed_build_types})
    endif()
endfunction()

# Configures the default output directory for binaries and libraries
function(xxx_configure_default_binary_dirs)
    # doc: https://cmake.org/cmake/help/v3.22/manual/cmake-buildsystem.7.html#id47
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE PATH "") # For Unix/MacOS executables, Windows: .exe, .dll, .pyd
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "") # for Unix/MacOS shared libraries .so/.dylib and Windows: .lib (import libraries for shared libraries)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "") # For static libraries add_library(STATIC ...) .a and Windows: .lib

    # /!\ MODULE libraries are dynamic libraries. On Windows, python modules are MODULE libraries, with pyd extension.
    #     They should be placed explicitely in lib/site-packages when building python extensions.
    xxx_configure_default_binary_dirs_for_config(Debug)
    xxx_configure_default_binary_dirs_for_config(Release)
    xxx_configure_default_binary_dirs_for_config(MinSizeRel)
    xxx_configure_default_binary_dirs_for_config(RelWithDebInfo)
endfunction()

# Same as xxx_configure_default_binary_dirs but for a specific config
function(xxx_configure_default_binary_dirs_for_config config)
    string(TOUPPER ${config} config)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${config} ${CMAKE_BINARY_DIR}/bin CACHE PATH "")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${config} ${CMAKE_BINARY_DIR}/lib CACHE PATH "")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${config} ${CMAKE_BINARY_DIR}/lib CACHE PATH "")
endfunction()

function(xxx_target_set_output_directory target_name dir)
    xxx_require_target(${target_name})

    set_target_properties(
        ${target_name}
        PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY ${dir}
            LIBRARY_OUTPUT_DIRECTORY ${dir}
            ARCHIVE_OUTPUT_DIRECTORY ${dir}
    )

    set_target_properties(
        ${target_name}
        PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY_DEBUG ${dir}
            LIBRARY_OUTPUT_DIRECTORY_DEBUG ${dir}
            ARCHIVE_OUTPUT_DIRECTORY_DEBUG ${dir}
            RUNTIME_OUTPUT_DIRECTORY_RELEASE ${dir}
            LIBRARY_OUTPUT_DIRECTORY_RELEASE ${dir}
            ARCHIVE_OUTPUT_DIRECTORY_RELEASE ${dir}
            RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL ${dir}
            LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL ${dir}
            ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL ${dir}
            RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${dir}
            LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO ${dir}
            ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO ${dir}
    )
endfunction()

# Configures the default install directories using GNUInstallDirs (bin, lib, include, etc.)
# Works on all platforms
function(xxx_configure_default_install_dirs)
    include(GNUInstallDirs)
endfunction()

# If not provided by the user, set a default CMAKE_INSTALL_PREFIX. Useful for IDEs.
function(xxx_configure_default_install_prefix default_install_prefix)
    if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        message(STATUS "Setting default install prefix to '${default_install_prefix}'")
        set(CMAKE_INSTALL_PREFIX
            ${default_install_prefix}
            CACHE PATH
            "Install path prefix, prepended onto install directories."
            FORCE
        )
        mark_as_advanced(CMAKE_INSTALL_PREFIX)
    endif()
endfunction()

# Setup the default options for a project (opinionated defaults)
# Usage : xxx_configure_defaults()
function(xxx_configure_defaults)
    xxx_configure_default_build_type(Release)
    xxx_configure_default_binary_dirs()
    xxx_configure_default_install_dirs()
    xxx_configure_default_install_prefix(${CMAKE_BINARY_DIR}/install)
    xxx_configure_copy_compile_commands_in_source_dir()
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

    if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        set(CMAKE_CXX_COMPILER_ID "Clang")
    endif()

    if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(
            ${target_name}
            ${visibility}
            /W4 # Enable most warnings
            /wd4250 # "Inherits via dominance" - happens with diamond inheritance, not really an issue
            /wd4706 # assignment within conditional expression
            /wd5030 # pointer or reference to potentially throwing function used in noexcept context
            /wd4996 # function may be unsafe
            /we4834 # discarding return value of function with 'nodiscard' attribute
            /we4062 # enumerator 'xyz' in switch of enum 'abc' is not handled
        )
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        target_compile_options(
            ${target_name}
            ${visibility}
            -Wall # Enable most warnings
            -Wextra # Enable extra warnings
            -Wconversion # Warn on type conversions that may lose information
            -Wpedantic # Warn on non-standard C++ usage
        )
    else()
        message(
            WARNING
            "Unknown compiler '${CMAKE_CXX_COMPILER_ID}'. No default compile options set."
        )
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

    target_compile_options(
        ${target_name}
        ${visibility}
        /permissive- # Standards conformance
        /Zc:__cplusplus # Needed to have __cplusplus set correctly
        /EHsc # Enable C++ exceptions standard conformance
        /bigobj # To avoid "fatal error C1128: number of sections exceeded object file format limit"
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

    if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        set(CMAKE_CXX_COMPILER_ID "Clang")
    endif()

    if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${target_name} ${visibility} /WX)
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        target_compile_options(${target_name} ${visibility} -Werror)
    else()
        message(
            WARNING
            "Unknown compiler '${CMAKE_CXX_COMPILER_ID}'. No warning as error flag set."
        )
    endif()
endfunction()

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
    set(oneValueArgs
        FILENAME
        HEADER_DIR
        TEMPLATE_FILE
        INSTALL_DESTINATION
        VERSION
    )
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 2 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

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

    if(arg_VERSION)
        set(LIBRARY_VERSION ${arg_VERSION})
    else()
        # Retrieve version from target
        get_property(LIBRARY_VERSION TARGET ${target_name} PROPERTY VERSION)
        if(NOT LIBRARY_VERSION)
            message(
                WARNING
                "Target ${target_name} does not have a VERSION property set, using the project version instead (PROJECT_VERSION=${PROJECT_VERSION}).
            To remove this warning, set the VERSION property on the target using:

                set_target_properties(${target_name} PROPERTIES VERSION \${PROJECT_VERSION})
            "
            )
            set(LIBRARY_VERSION ${PROJECT_VERSION})
        endif()
    endif()

    string(REPLACE "." ";" version_parts ${LIBRARY_VERSION})
    list(GET version_parts 0 LIBRARY_VERSION_MAJOR)
    list(GET version_parts 1 LIBRARY_VERSION_MINOR)
    list(GET version_parts 2 LIBRARY_VERSION_PATCH)

    configure_file(${arg_TEMPLATE_FILE} ${output_file} @ONLY)

    target_include_directories(${target_name} ${visibility} $<BUILD_INTERFACE:${arg_HEADER_DIR}>)

    if(arg_SKIP_INSTALL)
        return()
    endif()

    xxx_target_headers(${target_name} ${visibility} HEADERS ${output_file} BASE_DIRS ${arg_HEADER_DIR})
endfunction()

function(xxx_target_generate_warning_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 2 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)

    set(filename ${target_name}/warning.hpp)
    if(arg_FILENAME)
        set(filename ${arg_FILENAME})
    endif()

    set(header_dir ${CMAKE_CURRENT_BINARY_DIR}/generated/include)
    if(arg_HEADER_DIR)
        set(header_dir ${arg_HEADER_DIR})
    endif()

    set(install_destination ${CMAKE_INSTALL_INCLUDEDIR}/${target_name})
    if(arg_INSTALL_DESTINATION)
        set(install_destination ${arg_INSTALL_DESTINATION})
    endif()

    set(skip_install "")
    if(arg_SKIP_INSTALL)
        set(skip_install SKIP_INSTALL)
    endif()

    xxx_target_generate_header(${target_name} ${visibility}
        FILENAME ${filename}
        HEADER_DIR ${header_dir}
        TEMPLATE_FILE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/warning.hpp.in
        INSTALL_DESTINATION ${install_destination}
        VERSION ${PROJECT_VERSION}
        ${skip_install}
    )
endfunction()

function(xxx_target_generate_deprecated_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 2 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)

    set(filename ${target_name}/deprecated.hpp)
    if(arg_FILENAME)
        set(filename ${arg_FILENAME})
    endif()

    set(header_dir ${CMAKE_CURRENT_BINARY_DIR}/generated/include)
    if(arg_HEADER_DIR)
        set(header_dir ${arg_HEADER_DIR})
    endif()

    set(install_destination ${CMAKE_INSTALL_INCLUDEDIR}/${target_name})
    if(arg_INSTALL_DESTINATION)
        set(install_destination ${arg_INSTALL_DESTINATION})
    endif()

    set(skip_install "")
    if(arg_SKIP_INSTALL)
        set(skip_install SKIP_INSTALL)
    endif()

    xxx_target_generate_header(${target_name} ${visibility}
        FILENAME ${filename}
        HEADER_DIR ${header_dir}
        TEMPLATE_FILE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/deprecated.hpp.in
        INSTALL_DESTINATION ${install_destination}
        VERSION ${PROJECT_VERSION}
        ${skip_install}
    )
endfunction()

function(xxx_target_generate_config_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR INSTALL_DESTINATION VERSION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 2 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)
    xxx_require_variable(PROJECT_VERSION)
    xxx_require_variable(PROJECT_VERSION_MAJOR)
    xxx_require_variable(PROJECT_VERSION_MINOR)
    xxx_require_variable(PROJECT_VERSION_PATCH)

    set(filename ${target_name}/config.hpp)
    if(arg_FILENAME)
        set(filename ${arg_FILENAME})
    endif()

    set(header_dir ${CMAKE_CURRENT_BINARY_DIR}/generated/include)
    if(arg_HEADER_DIR)
        set(header_dir ${arg_HEADER_DIR})
    endif()

    set(install_destination ${CMAKE_INSTALL_INCLUDEDIR}/${target_name})
    if(arg_INSTALL_DESTINATION)
        set(install_destination ${arg_INSTALL_DESTINATION})
    endif()

    set(skip_install "")
    if(arg_SKIP_INSTALL)
        set(skip_install SKIP_INSTALL)
    endif()

    xxx_target_generate_header(${target_name} ${visibility}
        FILENAME ${filename}
        HEADER_DIR ${header_dir}
        TEMPLATE_FILE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/config.hpp.in
        INSTALL_DESTINATION ${install_destination}
        VERSION ${arg_VERSION}
        ${skip_install}
    )
endfunction()

function(xxx_target_generate_tracy_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 2 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)
    xxx_require_variable(PROJECT_VERSION)
    xxx_require_variable(PROJECT_VERSION_MAJOR)
    xxx_require_variable(PROJECT_VERSION_MINOR)
    xxx_require_variable(PROJECT_VERSION_PATCH)

    set(filename ${target_name}/tracy.hpp)
    if(arg_FILENAME)
        set(filename ${arg_FILENAME})
    endif()

    set(header_dir ${CMAKE_CURRENT_BINARY_DIR}/generated/include)
    if(arg_HEADER_DIR)
        set(header_dir ${arg_HEADER_DIR})
    endif()

    set(install_destination ${CMAKE_INSTALL_INCLUDEDIR}/${target_name})
    if(arg_INSTALL_DESTINATION)
        set(install_destination ${arg_INSTALL_DESTINATION})
    endif()

    set(skip_install "")
    if(arg_SKIP_INSTALL)
        set(skip_install SKIP_INSTALL)
    endif()

    xxx_target_generate_header(${target_name} ${visibility}
        FILENAME ${filename}
        HEADER_DIR ${header_dir}
        TEMPLATE_FILE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/tracy.hpp.in
        INSTALL_DESTINATION ${install_destination}
        VERSION ${PROJECT_VERSION}
        ${skip_install}
    )
endfunction()

# This function searches for a find module named Find<package>.cmake).
# It iterates over the CMAKE_MODULE_PATH and cmake builtin modules.
function(xxx_search_package_module_file package_name output_filepath)
    set(module_filename "Find${package_name}.cmake")
    set(found_module_file "")
    # QUESTION: Should we look into cmake builtin modules?
    # set(cmake_builtin_modules_path "${CMAKE_ROOT}/Modules")
    set(extra_modules_path "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../find-modules")
    cmake_path(CONVERT "${extra_modules_path}" TO_CMAKE_PATH_LIST extra_modules_path NORMALIZE)

    foreach(module_path IN LISTS CMAKE_MODULE_PATH extra_modules_path)
        set(candidate_filepath "${module_path}/${module_filename}")
        message(DEBUG "        Searching for package module file at: ${candidate_filepath}")
        if(EXISTS ${candidate_filepath})
            set(found_module_file ${candidate_filepath})
            break()
        endif()
    endforeach()

    set(${output_filepath} ${found_module_file} PARENT_SCOPE)
endfunction()

# Usage: xxx_find_package(<package> [version] [REQUIRED] [COMPONENTS ...] MODULE_PATH <path_to_find_module>)
# ref: https://cmake.org/cmake/help/latest/command/find_package.html
# This function allows to automatically retrieve the imported targets provided by the package
# and store info in global properties for later use (e.g. when exporting dependencies)
# Note: this needs to be a macro so find_package can leak variables (like Python_SITELIB)
macro(xxx_find_package)
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --blue --bold [${ARGV0}]
    )
    message(DEBUG "Executing xxx_find_package with args ${ARGV}")

    set(options)
    set(oneValueArgs MODULE_PATH)
    set(multiValueArgs)
    cmake_parse_arguments(arg "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Pkg name is the first argument of find_package(<pkg_name> ...)
    set(package_name ${ARGV0})
    set(find_package_args "${arg_UNPARSED_ARGUMENTS}")

    set(execute_find_package true)
    string(SHA256 find_package_args_hash "${find_package_args}")
    set(existing_find_package_hashes "")
    get_property(
        existing_find_package_hashes
        GLOBAL
        PROPERTY _xxx_${PROJECT_NAME}_find_package_hashes
    )

    # TODO: re-enable optimization. So far it's only depending on <pkg>_FOUND, which might not be enough.
    # if(${package_name}_FOUND AND find_package_args_hash IN_LIST existing_find_package_hashes)
    #     string(REPLACE ";" " " fp_pp "${find_package_args}")
    #     message("   Package '${package_name}' already found with the same arguments, skipping find_package(${fp_pp})")
    #     set(execute_find_package false)
    # else()
    #     set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_find_package_hashes "${find_package_args_hash}" APPEND)
    # endif()

    unset(existing_find_package_hashes)
    unset(find_package_args_hash)

    if(execute_find_package)
        unset(executing_find_package)

        # Handle custom module file
        if(arg_MODULE_PATH)
            set(module_file "${arg_MODULE_PATH}/Find${package_name}.cmake")
            if(NOT EXISTS ${module_file})
                message(
                    FATAL_ERROR
                    "Custom module file provided with MODULE_PATH ${module_file} does not exist."
                )
            endif()
        else()
            # search for the module file only is CONFIG is not in the find_package args
            if(NOT "CONFIG" IN_LIST find_package_args)
                xxx_search_package_module_file(${package_name} module_file)
            endif()
        endif()

        if(module_file)
            cmake_path(CONVERT "${module_file}" TO_CMAKE_PATH_LIST module_file NORMALIZE)
            # Add the parent path to the CMAKE_MODULE_PATH
            cmake_path(GET module_file PARENT_PATH module_dir)
            list(APPEND CMAKE_MODULE_PATH ${module_dir})
            message("   Using custom module file: ${module_file}")
        endif()

        # Call find_package with the provided arguments
        string(REPLACE ";" " " fp_pp "${find_package_args}")
        message("   Executing find_package(${fp_pp})")
        unset(fp_pp)

        # Saving the list of imported targets and variables BEFORE the call to find_package
        get_property(
            imported_targets_before
            DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            PROPERTY IMPORTED_TARGETS
        )
        get_property(variables_before DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VARIABLES)

        find_package(${find_package_args}) # TODO: handle QUIET properly

        if(${package_name}_FOUND)
            message("   Executing find_package()...✅")
        else()
            message("   Executing find_package()...❌")
        endif()

        # Put back CMAKE_MODULE_PATH to its previous value
        if(module_dir)
            list(REMOVE_ITEM CMAKE_MODULE_PATH ${module_dir})
        endif()

        # Getting the list of imported targets and variables AFTER the call to find_package
        get_property(package_variables DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VARIABLES)
        get_property(
            package_targets
            DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            PROPERTY IMPORTED_TARGETS
        )
        list(REMOVE_ITEM package_variables ${variables_before} variables_before)
        list(REMOVE_ITEM package_targets ${imported_targets_before})

        if(${package_name}_VERSION)
            message("   Version found: ${${package_name}_VERSION}")
        endif()

        string(REPLACE ";" ", " package_variables_pp "${package_variables}")
        if(package_variables)
            message(DEBUG "   New variables detected: ${package_variables_pp}")
        else()
            message("   No new variables detected.")
        endif()

        string(REPLACE ";" ", " package_targets_pp "${package_targets}")
        if(package_targets)
            message("   Imported targets detected: ${package_targets_pp}")
        else()
            message("   No imported targets detected.")
        endif()

        get_property(deps GLOBAL PROPERTY _xxx_${PROJECT_NAME}_package_dependencies)
        if(NOT deps)
            string(JSON deps SET "{}" "package_dependencies" "[]")
        endif()

        set(package_json "{}")
        string(REPLACE ";" " " find_package_args "${find_package_args}")
        string(JSON package_json SET "${package_json}" "package_name" "\"${package_name}\"")
        string(
            JSON package_json
            SET "${package_json}"
            "find_package_args"
            "\"${find_package_args}\""
        )
        string(
            JSON package_json
            SET "${package_json}"
            "package_variables"
            "\"${package_variables}\""
        )
        string(JSON package_json SET "${package_json}" "package_targets" "\"${package_targets}\"")
        string(JSON package_json SET "${package_json}" "module_file" "\"${module_file}\"")
        string(JSON deps_length LENGTH "${deps}" "package_dependencies")
        string(JSON deps SET "${deps}" "package_dependencies" ${deps_length} "${package_json}")

        set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_package_dependencies "${deps}")
    endif()

    unset(package_targets)
    unset(package_targets_pp)
    unset(package_variables)
    unset(package_variables_pp)
    unset(variables_before)
    unset(imported_targets_before)
    unset(deps)
    unset(module_file)
    unset(package_json)
    unset(deps_length)
endmacro()

# xxx_print_dependencies_summary()
# Print a summary of all dependencies found via xxx_find_package, and some properties of their imported targets.
function(xxx_print_dependencies_summary)
    get_property(deps GLOBAL PROPERTY _xxx_${PROJECT_NAME}_package_dependencies)
    if(NOT deps)
        message(STATUS "No dependencies found via xxx_find_package.")
        return()
    endif()

    message("")
    message("================= External Dependencies ======================================")
    message("")

    string(JSON num_deps LENGTH "${deps}" "package_dependencies")
    math(EXPR max_idx "${num_deps} - 1")
    message("${num_deps} dependencies declared xxx_find_package: ")
    foreach(i RANGE 0 ${max_idx})
        string(JSON package_name GET "${deps}" "package_dependencies" ${i} "package_name")
        string(JSON package_targets GET "${deps}" "package_dependencies" ${i} "package_targets")

        # Replace ; by , for better readability
        string(REPLACE ";" ", " package_targets_pp "${package_targets}")
        math(EXPR i "${i} + 1")
        message(
            "${i}/${num_deps} Package [${package_name}] imported targets [${package_targets_pp}]"
        )

        # Print target properties
        if(package_targets STREQUAL "")
            continue()
        endif()
        xxx_cmake_print_properties(TARGETS ${package_targets} PROPERTIES
            NAME
            ALIASED_TARGET
            TYPE
            VERSION
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
            CXX_STANDARD
            CXX_EXTENSIONS
            CXX_STANDARD_REQUIRED
        )
    endforeach()
endfunction()

# xxx_cmake_print_properties
# Usage: xxx_cmake_print_properties(<mode> <items> PROPERTIES <property1> <property2> ... [VERBOSITY <verbosity_level>])
# This is taken and adapted from cmake's own cmake_print_properties function to add verbosity control and print only found properties.
function(xxx_cmake_print_properties)
    set(options)
    set(oneValueArgs VERBOSITY)
    set(cpp_multiValueArgs PROPERTIES)
    set(cppmode_multiValueArgs
        TARGETS
        SOURCES
        TESTS
        DIRECTORIES
        CACHE_ENTRIES
    )

    string(JOIN " " _mode_names ${cppmode_multiValueArgs})
    set(_missing_mode_message
        "Mode keyword missing in xxx_cmake_print_properties() call, there must be exactly one of ${_mode_names}"
    )

    cmake_parse_arguments(CPP "${options}" "${oneValueArgs}" "${cpp_multiValueArgs}" ${ARGN})

    if(NOT CPP_PROPERTIES)
        message(
            FATAL_ERROR
            "Required argument PROPERTIES missing in xxx_cmake_print_properties() call"
        )
        return()
    endif()

    set(verbosity)
    if(CPP_VERBOSITY)
        set(verbosity ${CPP_VERBOSITY})
    endif()

    if(NOT CPP_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${_missing_mode_message}")
        return()
    endif()

    cmake_parse_arguments(
        CPPMODE
        "${options}"
        "${oneValueArgs}"
        "${cppmode_multiValueArgs}"
        ${CPP_UNPARSED_ARGUMENTS}
    )

    if(CPPMODE_UNPARSED_ARGUMENTS)
        message(
            FATAL_ERROR
            "Unknown keywords given to cmake_print_properties(): \"${CPPMODE_UNPARSED_ARGUMENTS}\""
        )
        return()
    endif()

    set(mode)
    set(items)
    set(keyword)

    if(CPPMODE_TARGETS)
        set(items ${CPPMODE_TARGETS})
        set(mode ${mode} TARGETS)
        set(keyword TARGET)
    endif()

    if(CPPMODE_SOURCES)
        set(items ${CPPMODE_SOURCES})
        set(mode ${mode} SOURCES)
        set(keyword SOURCE)
    endif()

    if(CPPMODE_TESTS)
        set(items ${CPPMODE_TESTS})
        set(mode ${mode} TESTS)
        set(keyword TEST)
    endif()

    if(CPPMODE_DIRECTORIES)
        set(items ${CPPMODE_DIRECTORIES})
        set(mode ${mode} DIRECTORIES)
        set(keyword DIRECTORY)
    endif()

    if(CPPMODE_CACHE_ENTRIES)
        set(items ${CPPMODE_CACHE_ENTRIES})
        set(mode ${mode} CACHE_ENTRIES)
        # This is a workaround for the fact that passing `CACHE` as an argument to
        # set() causes a cache variable to be set.
        set(keyword "")
        string(APPEND keyword CACHE)
    endif()

    if(NOT mode)
        message(FATAL_ERROR "${_missing_mode_message}")
        return()
    endif()

    list(LENGTH mode modeLength)
    if("${modeLength}" GREATER 1)
        message(
            FATAL_ERROR
            "Multiple mode keywords used in cmake_print_properties() call, there must be exactly one of ${_mode_names}."
        )
        return()
    endif()

    set(msg "\n")
    foreach(item ${items})
        set(itemExists TRUE)
        if(keyword STREQUAL "TARGET")
            if(NOT TARGET ${item})
                set(itemExists FALSE)
                string(APPEND msg "\n No such TARGET \"${item}\" !\n\n")
            endif()
        endif()

        if(itemExists)
            string(APPEND msg " Properties for ${keyword} ${item}:\n")
            foreach(prop ${CPP_PROPERTIES})
                get_property(propertySet ${keyword} ${item} PROPERTY "${prop}" SET)

                if(propertySet)
                    get_property(property ${keyword} ${item} PROPERTY "${prop}")
                    #   string(APPEND msg "   ${item}.${prop} = \"${property}\"\n")
                    _pad_string("${prop}"      40 _prop)
                    string(APPEND msg "   ${_prop} = ${property}\n")
                else()
                    # EDIT: Do not print unset properties
                    # string(APPEND msg "   ${item}.${prop} = <NOTFOUND>\n")
                endif()
            endforeach()
        endif()
    endforeach()
    message(${verbosity} "${msg}")
endfunction()

# Usage: xxx_export_dependencies(TARGETS [target1...] GEN_DIR <gen_dir> INSTALL_DESTINATION <destination>)
# This function analyzes the link libraries of the provided targets,
# determines which packages are needed and generates a <export_name>-dependencies.cmake file
function(xxx_export_dependencies)
    set(options)
    set(oneValueArgs INSTALL_DESTINATION GEN_DIR PACKAGE_DEPENDENCIES_FILE)
    set(multiValueArgs TARGETS)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(arg_TARGETS)
    xxx_require_variable(arg_PACKAGE_DEPENDENCIES_FILE)

    if(arg_GEN_DIR)
        set(GEN_DIR ${arg_GEN_DIR})
    else()
        set(GEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME})
    endif()

    if(arg_INSTALL_DESTINATION)
        set(INSTALL_DESTINATION ${arg_INSTALL_DESTINATION})
    else()
        set(INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})
    endif()

    if(arg_FILENAME)
        set(FILENAME ${arg_FILENAME})
    else()
        set(FILENAME ${PROJECT_NAME}-dependencies.cmake)
    endif()

    set(PACKAGE_DEPENDENCIES_FILE ${arg_PACKAGE_DEPENDENCIES_FILE})

    # Get all BUILDSYSTEM_TARGETS of the current project (i.e. added via add_library/add_executable)
    # We need this to filter out internal targets when analyzing link libraries
    get_property(
        buildsystem_targets
        DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        PROPERTY BUILDSYSTEM_TARGETS
    )
    foreach(target ${arg_TARGETS})
        if(NOT target IN_LIST buildsystem_targets)
            message(
                FATAL_ERROR
                "Target '${target}' is not a buildsystem target of the current project. Cannot export dependencies for it."
            )
        endif()
    endforeach()

    set(all_imported_libraries "")
    foreach(target ${arg_TARGETS})
        get_target_property(interface_link_libraries ${target} INTERFACE_LINK_LIBRARIES)
        if(NOT interface_link_libraries)
            message("Target '${target}' has no INTERFACE_LINK_LIBRARIES.")
            continue()
        endif()
        foreach(lib ${interface_link_libraries})
            if(lib IN_LIST buildsystem_targets)
                continue()
            endif()

            if(lib IN_LIST all_imported_libraries)
                continue()
            endif()

            list(APPEND all_imported_libraries ${lib})
        endforeach()
    endforeach()

    message("All link libraries for targets '${arg_TARGETS}': ${all_imported_libraries}")

    message("Reading package dependencies JSON ${PACKAGE_DEPENDENCIES_FILE}")
    file(READ ${PACKAGE_DEPENDENCIES_FILE} package_dependencies_json_content)

    file(
        GENERATE OUTPUT ${GEN_DIR}/imported-libraries.cmake
        CONTENT
            "
# Generated file - do not edit
# This file contains the list of imported libraries that needs to be exported
set(imported_libraries [[${all_imported_libraries}]])
set(package_dependencies_json_content [[${package_dependencies_json_content}]])

# For debugging purposes
set(targets [[${arg_TARGETS}]])
set(buildsystem_targets [[${buildsystem_targets}]])
"
    )
    # needs @INSTALL_DESTINATION@
    configure_file(
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/generate-dependencies.cmake.in
        ${GEN_DIR}/generate-dependencies.cmake
        @ONLY
    )
    install(SCRIPT ${GEN_DIR}/generate-dependencies.cmake)
endfunction()

# xxx_add_export_component(NAME <component_name> TARGETS <target1> <target2> ...)
# Add an export component with associated targets that will be exported as a CMake package component.
# Each export component will have its own <package>-component-<name>-targets.cmake
# and <package>-component-<name>-dependencies.cmake generated.
# Components are used with: find_package(<package> CONFIG REQUIRED COMPONENTS <component1> <component2> ...)
function(xxx_add_export_component)
    set(options)
    set(oneValueArgs NAME)
    set(multiValueArgs TARGETS)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(PROJECT_NAME)
    xxx_require_variable(arg_TARGETS)
    xxx_require_variable(arg_NAME)

    # Check export component is not already declared
    get_property(existing_components GLOBAL PROPERTY _xxx_${PROJECT_NAME}_export_components)
    if(${arg_NAME} IN_LIST existing_components)
        message(
            FATAL_ERROR
            "Export component '${arg_NAME}' is already declared for project '${PROJECT_NAME}'."
        )
    endif()

    # Check if target is already in an export component
    foreach(component ${existing_components})
        get_property(component_targets GLOBAL PROPERTY _xxx_${PROJECT_NAME}_${component}_targets)
        foreach(target ${arg_TARGETS})
            if(${target} IN_LIST component_targets)
                message(
                    FATAL_ERROR
                    "Target '${target}' is already part of export component '${component}'. Cannot add it to export component '${arg_NAME}'."
                )
            endif()
        endforeach()
    endforeach()

    message(
        "Adding export component '${arg_NAME}' with targets: ${arg_TARGETS} (${PROJECT_NAME}-${arg_NAME})"
    )

    # This option associates the installed target files with an export, without installing anything.
    # TODO: Declare exports first like that, split the xxx_export_package() with a generation and an install step.
    # install(TARGETS ${arg_TARGETS} EXPORT ${PROJECT_NAME}-${arg_NAME})

    set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_export_components ${arg_NAME} APPEND)
    set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_${arg_NAME}_targets ${arg_TARGETS})
endfunction()

# xxx_contains_generator_expressions(<input_string> <output_var>)
# Check if the provided string contains generator expressions.
# Sets output_var to True or False.
function(xxx_contains_generator_expressions input_string output_var)
    string(GENEX_STRIP "${input_string}" stripped_string)
    if(stripped_string STREQUAL input_string)
        set(${output_var} False PARENT_SCOPE)
    else()
        set(${output_var} True PARENT_SCOPE)
    endif()
endfunction()

# xxx_target_headers(<target>
#   HEADERS <list_of_headers>
#   BASE_DIRS <list_of_base_dirs> # Optional, default is empty
# )
# Declare headers for target (to be installed later)
# This will populate the _xxx_install_headers and _xxx_install_headers_base_dirs properties of the target.
# In CMake 3.23, we will use FILE_SETS instead of this trick.
# cf: https://cmake.org/cmake/help/latest/command/target_sources.html#file-sets
function(xxx_target_headers target visibility)
    set(options)
    set(oneValueArgs GENERATED_DIR)
    set(multiValueArgs HEADERS BASE_DIRS)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(arg_HEADERS)
    xxx_require_target(${target})
    xxx_require_visibility(${visibility})

    if(NOT arg_BASE_DIRS)
        set(arg_BASE_DIRS "")
    endif()

    # Save the headers in a property of the target
    # NOTE: The PUBLIC_HEADER technically works, but does not support base_dirs
    # cf: https://cmake.org/cmake/help/latest/command/install.html#install
    set_property(TARGET ${target} APPEND PROPERTY _xxx_install_headers "${arg_HEADERS}")
    set_property(TARGET ${target} APPEND PROPERTY _xxx_install_headers_base_dirs "${arg_BASE_DIRS}")
endfunction()

# xxx_target_install_headers(<target>
#   DESTINATION <destination> # Optional, default is CMAKE_INSTALL_INCLUDEDIR
# )
# Install declared header for a given target and solve the relative path using the provided base dirs.
# It is using the _xxx_install_headers and _xxx_install_headers_base_dirs properties set via xxx_target_headers().
# For a whole project, use xxx_install_headers() instead (which calls this function for each component, that contains targets).
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

    get_target_property(headers ${target} _xxx_install_headers)
    get_target_property(base_dirs ${target} _xxx_install_headers_base_dirs)

    if(NOT headers)
        message(DEBUG "No headers declared for target '${target}'. Skipping installation.")
        return()
    endif()

    file(
        GENERATE OUTPUT
            ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME}/${target}-install-headers.cmake
        CONTENT
            "
# Generated file - do not edit
# This file contains the list of headers declared for target '${target}' with visibility '${visibility}'
set(headers \"${headers}\")
set(base_dirs \"${base_dirs}\")
foreach(header \${headers})
    foreach(base_dir \${base_dirs})
        string(FIND \${header} \${base_dir} pos)
        if(pos EQUAL 0)
            string(REPLACE \${base_dir} \"\" relative_path \${header})
            string(REGEX REPLACE \"^/\" \"\" relative_path \${relative_path})
            break()
        endif()
    endforeach()

    if(IS_ABSOLUTE \${header})
        set(header_path \${header})
    else()
        set(header_path ${CMAKE_CURRENT_SOURCE_DIR}/\${header})
    endif()

    if(relative_path)
        cmake_path(GET relative_path PARENT_PATH header_dir)
        file(INSTALL DESTINATION \"\${CMAKE_INSTALL_PREFIX}/${install_destination}/\${header_dir}\" TYPE FILE FILES \${header_path})
    else()
        # No base directory matched, install without subdirectory
        file(INSTALL DESTINATION \"\${CMAKE_INSTALL_PREFIX}/${install_destination}\" TYPE FILE FILES \${header_path})
    endif()
endforeach()
"
    )
    install(
        SCRIPT
            ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME}/${target}-install-headers.cmake
    )
endfunction()

# xxx_install_headers(
#   DESTINATION <destination> # Optional, default is CMAKE_INSTALL_INCLUDEDIR
#   COMPONENTS <component1> <component2> ... # Optional, default is all declared components
# )
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

    get_property(declared_components GLOBAL PROPERTY _xxx_${PROJECT_NAME}_export_components)

    set(components "")
    if(arg_COMPONENTS)
        set(components ${arg_COMPONENTS})
    else()
        if(NOT declared_components)
            message(
                FATAL_ERROR
                "No export components declared for project '${PROJECT_NAME}'. Cannot install headers. Use xxx_add_export_component() first."
            )
        endif()
        set(components ${declared_components})
        message(
            "Installing headers for all declared components. Declared components: [${declared_components}]"
        )
    endif()

    foreach(component ${components})
        if(NOT component IN_LIST declared_components)
            message(
                FATAL_ERROR
                "Component '${component}' is not declared for project '${PROJECT_NAME}'."
            )
        endif()

        get_property(targets GLOBAL PROPERTY _xxx_${PROJECT_NAME}_${component}_targets)
        if(NOT targets)
            message(WARNING "No targets found for component '${component}'. Skipping.")
            continue()
        endif()

        foreach(target ${targets})
            message(
                "Installing headers for target '${target}' of component '${component}' to '${install_destination}'"
            )
            xxx_target_install_headers(${target} DESTINATION ${install_destination})
        endforeach()
    endforeach()
endfunction()

# xxx_export_package()
# Export the CMake package with all its components (targets, headers, package modules, etc.)
# Generates and installs CMake package configuration files:
#  - <package>-config.cmake
#  - <package>-config-version.cmake
#  - <package>-component-<componentA>-targets.cmake
#  - <package>-component-<componentA>-dependencies.cmake
#  - <package>-component-<componentB>-targets.cmake
#  - <package>-component-<componentB>-dependencies.cmake
# NOTE: This is for CMake package export only. Python bindings are handled separately.
function(xxx_export_package)
    message(STATUS "[${PROJECT_NAME}] Exporting package (${CMAKE_CURRENT_FUNCTION})")

    set(options)
    set(oneValueArgs PACKAGE_CONFIG_TEMPLATE CMAKE_FILES_INSTALL_DIR)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    include(CMakePackageConfigHelpers)
    xxx_require_variable(PROJECT_NAME)
    xxx_require_variable(PROJECT_VERSION)
    xxx_require_variable(CMAKE_INSTALL_BINDIR)
    xxx_require_variable(CMAKE_INSTALL_LIBDIR)
    xxx_require_variable(CMAKE_INSTALL_INCLUDEDIR)

    if(arg_PACKAGE_CONFIG_TEMPLATE)
        set(PACKAGE_CONFIG_TEMPLATE ${arg_PACKAGE_CONFIG_TEMPLATE})
    else()
        set(PACKAGE_CONFIG_TEMPLATE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/config.cmake.in)
        set(using_default_template True)
    endif()

    if(arg_CMAKE_FILES_INSTALL_DIR)
        set(CMAKE_FILES_INSTALL_DIR ${arg_CMAKE_FILES_INSTALL_DIR})
    else()
        set(CMAKE_FILES_INSTALL_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})
    endif()

    # NOTE: Expose as options if needed
    set(GEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME})
    set(PACKAGE_CONFIG_OUTPUT ${GEN_DIR}/${PROJECT_NAME}-config.cmake)
    set(PACKAGE_VERSION ${PROJECT_VERSION})
    set(PACKAGE_VERSION_OUTPUT ${GEN_DIR}/${PROJECT_NAME}-config-version.cmake)
    set(PACKAGE_VERSION_COMPATIBILITY AnyNewerVersion)
    set(PACKAGE_VERSION_ARCH_INDEPENDENT "")
    set(NO_SET_AND_CHECK_MACRO "NO_SET_AND_CHECK_MACRO")
    set(NO_CHECK_REQUIRED_COMPONENTS_MACRO "NO_CHECK_REQUIRED_COMPONENTS_MACRO")
    set(NAMESPACE "${PROJECT_NAME}::")

    # Dump package dependencies recorded with xxx_find_package()
    _xxx_dump_package_dependencies_json(${GEN_DIR}/${PROJECT_NAME}-package-dependencies.json)

    # Get declared export components
    get_property(declared_components GLOBAL PROPERTY _xxx_${PROJECT_NAME}_export_components)
    if(using_default_template AND NOT declared_components)
        message(
            FATAL_ERROR
            "No export component declared for project '${PROJECT_NAME}'.
        The default config.cmake.in template requires at least one export component.
        Either add export-components via:
            xxx_add_export_component(NAME <comp_name> TARGETS [target1...])
        Or provide your own config template:
            xxx_export_package(PACKAGE_CONFIG_TEMPLATE <config-template.cmake.in>)
        "
        )
    endif()

    # <package>-config.cmake
    # Needs the variable PROJECT_COMPONENTS
    set(PROJECT_COMPONENTS ${declared_components})
    configure_package_config_file(
        ${PACKAGE_CONFIG_TEMPLATE}
        ${PACKAGE_CONFIG_OUTPUT}
        INSTALL_DESTINATION ${CMAKE_FILES_INSTALL_DIR}
        ${NO_SET_AND_CHECK_MACRO}
        ${NO_CHECK_REQUIRED_COMPONENTS_MACRO}
    )
    install(FILES ${PACKAGE_CONFIG_OUTPUT} DESTINATION ${CMAKE_FILES_INSTALL_DIR})

    # <package>-config-version.cmake
    write_basic_package_version_file(
        ${PACKAGE_VERSION_OUTPUT}
        VERSION ${PACKAGE_VERSION}
        COMPATIBILITY ${PACKAGE_VERSION_COMPATIBILITY}
        ${PACKAGE_VERSION_ARCH_INDEPENDENT}
    )
    install(FILES ${PACKAGE_VERSION_OUTPUT} DESTINATION ${CMAKE_FILES_INSTALL_DIR})

    foreach(component ${declared_components})
        message("Generating cmake module files for component '${component}'")

        get_property(targets GLOBAL PROPERTY _xxx_${PROJECT_NAME}_${component}_targets)

        xxx_target_install_headers(${targets} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

        # <package>-component-<component>-dependencies.cmake
        xxx_export_dependencies(
            TARGETS ${targets}
            GEN_DIR ${GEN_DIR}/${component}
            PACKAGE_DEPENDENCIES_FILE ${GEN_DIR}/${PROJECT_NAME}-package-dependencies.json
            INSTALL_DESTINATION ${CMAKE_FILES_INSTALL_DIR}/${component}
        )
        # Create the export for the component targets
        install(
            TARGETS ${targets}
            EXPORT ${PROJECT_NAME}-${component}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        )
        # <package>-component-<component>-targets.cmake
        install(
            EXPORT ${PROJECT_NAME}-${component}
            FILE targets.cmake
            NAMESPACE ${NAMESPACE}
            DESTINATION ${CMAKE_FILES_INSTALL_DIR}/${component}
        )
    endforeach()
endfunction()

# _xxx_dump_package_dependencies_json()
# Internal function to dump the package dependencies recorded with xxx_find_package()
# It is called at the end of the configuration step via cmake_language(DEFER CALL ...)
# In the function xxx_export_package().
function(_xxx_dump_package_dependencies_json output)
    get_property(
        package_dependencies_json
        GLOBAL
        PROPERTY _xxx_${PROJECT_NAME}_package_dependencies
    )
    if(NOT package_dependencies_json)
        message(STATUS "No package dependencies recorded with xxx_find_package()")
        return()
    endif()
    message(STATUS "[${PROJECT_NAME}] Dumping package dependencies JSON to ${output}")
    file(WRITE ${output} "${package_dependencies_json}")
endfunction()

# xxx_option(<option_name> <description> <default_value>)
# Example: xxx_option(BUILD_TESTING "Build the tests" ON)
# Override cmake option() to get a nice summary at the end of the configuration step
function(xxx_option option_name description default_value)
    option(${option_name} "${description}" ${default_value})

    cmake_parse_arguments(arg "" "COMPATIBILITY_OPTION" "" ${ARGN})
    if(arg_COMPATIBILITY_OPTION)
        set_property(
            GLOBAL
            PROPERTY
                _xxx_${PROJECT_NAME}_option_${option_name}_compat_option ${arg_COMPATIBILITY_OPTION}
        )
        if(DEFINED ${arg_COMPATIBILITY_OPTION})
            message(
                WARNING
                "Option ${arg_COMPATIBILITY_OPTION} is deprecated. Please use ${option_name} instead."
            )
            set(${option_name} ${${arg_COMPATIBILITY_OPTION}} CACHE BOOL "${description}" FORCE)
        endif()
    endif()

    set_property(
        GLOBAL
        PROPERTY _xxx_${PROJECT_NAME}_option_${option_name}_default_value ${default_value}
    )
    set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_option_names ${option_name} APPEND)
endfunction()

function(
    xxx_cmake_dependent_option
    option_name
    description
    default_value
    condition
    else_value
)
    include(CMakeDependentOption)
    cmake_dependent_option(${ARGV})

    set_property(
        GLOBAL
        PROPERTY _xxx_${PROJECT_NAME}_option_${option_name}_default_value ${default_value}
    )
    set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_option_names ${option_name} APPEND)
endfunction()

# Helper function: pad or truncate a string to a fixed width
function(_pad_string input width output_var)
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
# Usage: xxx_print_options_summary()
function(xxx_print_options_summary)
    get_property(option_names GLOBAL PROPERTY _xxx_${PROJECT_NAME}_option_names)
    if(NOT option_names)
        message(STATUS "No options defined via xxx_option.")
        return()
    endif()

    message("")
    message(
        "================= Configuration Summary =========================================================="
    )
    message("")

    _pad_string("Option"      40 _menu_option)
    _pad_string("Type"        8  _menu_type)
    _pad_string("Value"       5  _menu_value)
    _pad_string("Default"     5  _menu_default)
    _pad_string("Description (default)" 25 _menu_description)
    message("${_menu_option} | ${_menu_type} | ${_menu_value} | ${_menu_description}")
    message(
        "--------------------------------------------------------------------------------------------------"
    )

    foreach(option_name ${option_names})
        get_property(_type CACHE ${option_name} PROPERTY TYPE)
        get_property(_val CACHE ${option_name} PROPERTY VALUE)
        get_property(
            _default
            GLOBAL
            PROPERTY _xxx_${PROJECT_NAME}_option_${option_name}_default_value
        )
        get_property(_help CACHE ${option_name} PROPERTY HELPSTRING)
        get_property(
            _compat_option
            GLOBAL
            PROPERTY _xxx_${PROJECT_NAME}_option_${option_name}_compat_option
        )

        _pad_string("${option_name}"      40 _name)
        _pad_string("${_type}"     8 _type)
        _pad_string("${_val}"      5 _val)
        _pad_string("${_help}"     30 _help)
        _pad_string("${_default}"  3 _default)

        message("${_name} | ${_type} | ${_val} | ${_help} (${_default})")
        if(_compat_option)
            message("  (Compatibility option: ${_compat_option})")
        endif()
    endforeach()

    message(
        "--------------------------------------------------------------------------------------------------"
    )
    message("")
endfunction()

# Shortcut to find Python package and check main variables
# Usage: xxx_find_python([version] [REQUIRED] [COMPONENTS ...])
# Example: xxx_find_python(3.8 REQUIRED COMPONENTS Interpreter Development.Module)
macro(xxx_find_python)
    xxx_find_package(Python ${ARGN})

    # On Windows, Python_SITELIB returns \. Let's convert it to /.
    cmake_path(CONVERT ${Python_SITELIB} TO_CMAKE_PATH_LIST Python_SITELIB NORMALIZE)

    message("   Python_FOUND             : ${Python_FOUND}")
    message("   Python_EXECUTABLE        : ${Python_EXECUTABLE}")
    message("   Python_VERSION           : ${Python_VERSION}")
    message("   Python_SITELIB           : ${Python_SITELIB}")
    message("   Python_INCLUDE_DIRS      : ${Python_INCLUDE_DIRS}")
    message("   Python_LIBRARIES         : ${Python_LIBRARIES}")
    message("   Python_SOABI             : ${Python_SOABI}")
    message("   Python_NumPy_FOUND       : ${Python_NumPy_FOUND}")
    message("   Python_NumPy_VERSION     : ${Python_NumPy_VERSION}")
    message("   Python_NumPy_INCLUDE_DIRS: ${Python_NumPy_INCLUDE_DIRS}")
endmacro()

# Shortcut to find the nanobind package
# Usage: xxx_find_nanobind()
macro(xxx_find_nanobind)
    string(REPLACE ";" " " args_pp "${ARGN}")
    xxx_require_variable(Python_EXECUTABLE "Python executable not found (variable Python_EXECUTABLE).

    Please call xxx_find_python(<args>) first, e.g.:

        xxx_find_python(3.8 REQUIRED COMPONENTS Interpreter Development.Module)
        xxx_find_package(nanobind ${args_pp})
    "
    )
    unset(args_pp)

    # Detect the installed nanobind package and import it into CMake
    # ref: https://nanobind.readthedocs.io/en/latest/building.html#finding-nanobind
    execute_process(
        COMMAND ${Python_EXECUTABLE} -m nanobind --cmake_dir
        OUTPUT_STRIP_TRAILING_WHITESPACE
        OUTPUT_VARIABLE nanobind_ROOT
        ERROR_VARIABLE nanobind_error
    )

    if(nanobind_error)
        unset(nanobind_ROOT)

        # On Ubuntu 24.04, nanobind installed via apt is located in /usr/share/nanobind
        find_path(nanobind_INCLUDE_DIR NAMES nanobind/nanobind.h HINTS /usr/share/nanobind/include)
        if(nanobind_INCLUDE_DIR)
            set(nanobind_ROOT ${nanobind_INCLUDE_DIR}/../cmake)
            cmake_path(CONVERT ${nanobind_ROOT} TO_CMAKE_PATH_LIST nanobind_ROOT NORMALIZE)
        endif()
    endif()

    if(NOT nanobind_ROOT)
        message(FATAL_ERROR "Failed to find nanobind package: ${nanobind_error}")
    endif()

    xxx_find_package(nanobind ${ARGN})

    message("   Nanobind CMake directory: ${nanobind_ROOT}")

    # If you install nanobind with pip, it will include tsl-robin-map in <nanobind>/ext/robin_map
    # On macOS, brew install nanobind will not include tsl-robin-map, we need to install it via: brew install robin-map
    # Naturally, find_package(nanobind CONFIG REQUIRED) will succeed (nanobind_FOUND -> True), but the tsl-robin-map dependency will be missing, causing build errors.
    # So let's check if the headers are available, otherwise require tsl-robin-map explicitly.
    if(EXISTS "${nanobind_ROOT}/../ext/robin_map/include/tsl/robin_map.h")
        message("   Nanobind's tsl-robin-map dependency found in '${nanobind_ROOT}/ext/robin_map'.")
    else()
        xxx_find_package(tsl-robin-map CONFIG REQUIRED)
    endif()
endmacro()

function(xxx_python_compile_all)
    set(options VERBOSE)
    set(oneValueArgs DIRECTORY)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")
    xxx_require_variable(arg_DIRECTORY)

    if(arg_VERBOSE)
        message(STATUS "Compiling all Python files in directory '${arg_DIRECTORY}'")
        # If quiet is False or 0 (the default), the filenames and other information are printed to standard out.
        # Set to 1, only errors are printed. Set to 2, all output is suppressed.
        set(quiet_flag "0")
    else()
        set(quiet_flag "1")
    endif()

    execute_process(
        COMMAND
            ${Python_EXECUTABLE} -c
            "import compileall; compileall.compile_dir(r'${arg_DIRECTORY}', workers=0, quiet=${quiet_flag})"
        RESULT_VARIABLE result
        ERROR_VARIABLE error
        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY ${arg_DIRECTORY}
    )
    if(error)
        message(
            FATAL_ERROR
            "Failed to compile Python files in directory '${arg_DIRECTORY}': ${error}"
        )
    endif()

    if(arg_VERBOSE)
        message(STATUS "Compiling all Python files in directory '${arg_DIRECTORY}'... OK.")
    endif()
endfunction()

function(xxx_python_generate_init_py name)
    set(options)
    set(oneValueArgs OUTPUT_PATH)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 1 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    if(NOT TARGET ${name})
        message(FATAL_ERROR "Target '${name}' does not exist, cannot generate __init__.py")
    endif()

    if(NOT DEFINED arg_OUTPUT_PATH)
        message(FATAL_ERROR "OUTPUT_PATH argument is required")
    endif()

    get_target_property(python_module_link_libraries ${name} LINK_LIBRARIES)
    message(DEBUG "Python module '${name}' link libraries: [${python_module_link_libraries}]")

    set(dlls_to_link "")
    list(REMOVE_DUPLICATES python_module_link_libraries)
    foreach(target IN LISTS python_module_link_libraries)
        get_target_property(target_type ${target} TYPE)
        get_target_property(is_imported ${target} IMPORTED)
        message(
            DEBUG
            "Checking target '${target}' of type '${target_type}' for dll linking. Imported: '${is_imported}'"
        )

        if(
            target_type STREQUAL "SHARED_LIBRARY"
            OR target_type STREQUAL "MODULE_LIBRARY"
            AND NOT ${is_imported}
        )
            message(
                DEBUG
                "    => Adding target '${target}' to dlls to link for python module '${name}'"
            )
            list(APPEND dlls_to_link ${target})
        endif()
    endforeach()

    message(
        DEBUG
        "Python module '${name}' depends on the following buildsystem dlls: [${dlls_to_link}]"
    )

    # Get the relative paths between the python module and each dll
    set(all_rel_paths "")
    foreach(dll_name IN LISTS dlls_to_link)
        get_target_property(python_module_dir ${name} LIBRARY_OUTPUT_DIRECTORY)
        xxx_require_variable(python_module_dir "LIBRARY_OUTPUT_DIRECTORY not set for target '${name}', add it using 'set_target_properties(<target> PROPERTIES LIBRARY_OUTPUT_DIRECTORY <dir>)'")

        get_target_property(dll_dir ${dll_name} RUNTIME_OUTPUT_DIRECTORY)
        xxx_require_variable(dll_dir)

        file(RELATIVE_PATH rel_path ${python_module_dir} ${dll_dir})
        list(APPEND all_rel_paths ${rel_path})
    endforeach()

    # Final formatting to a Python list
    set(dll_dirs "[")
    foreach(rel_path IN LISTS all_rel_paths)
        string(APPEND dll_dirs "'${rel_path}',")
    endforeach()
    string(REGEX REPLACE ",$" "" dll_dirs "${dll_dirs}")
    string(APPEND dll_dirs "]")

    # Configure the __init__.py with PYTHON_MODULE_NAME and optional dll_dirs
    set(__MODULE_NAME__ "${name}")
    set(__DLL_DIRS__ "${dll_dirs}")
    configure_file(
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/__init__.py.in
        ${arg_OUTPUT_PATH}
        @ONLY
    )
endfunction()

# Find if a python module is available, fills <module_name>_FOUND variable
# Displays messages based on REQUIRED and QUIET options
# Usage: xxx_check_python_module(<module_name> [REQUIRED] [QUIET])
# Example: xxx_check_python_module(numpy REQUIRED)
function(xxx_check_python_module module_name)
    set(options REQUIRED QUIET)
    cmake_parse_arguments(ARG "${options}" "" "" ${ARGN})

    if(NOT Python_EXECUTABLE)
        message(
            FATAL_ERROR
            "Python_EXECUTABLE not defined.
        Please use xxx_find_package(Python REQUIRED COMPONENT Interpreter)"
        )
    endif()

    execute_process(
        COMMAND ${Python_EXECUTABLE} -c "import ${module_name}"
        RESULT_VARIABLE module_found
        ERROR_QUIET
    )
    if(module_found STREQUAL 0)
        set(${module_name}_FOUND true PARENT_SCOPE)
        if(NOT ARG_QUIET)
            message(STATUS "Python module '${module_name}' found.")
        endif()
    else()
        set(${module_name}_FOUND false PARENT_SCOPE)
        if(ARG_REQUIRED)
            message(FATAL_ERROR "Required Python module '${module_name}' not found.")
        elseif(NOT ARG_QUIET)
            message(WARNING "Python module '${module_name}' not found.")
        endif()
    endif()
endfunction()

function(xxx_python_compute_install_dir output)
    if(DEFINED ${PROJECT_NAME}_PYTHON_INSTALL_DIR)
        message(
            "${PROJECT_NAME}_PYTHON_INSTALL_DIR is defined, using its value: ${${PROJECT_NAME}_PYTHON_INSTALL_DIR} as python install dir"
        )
        set(${output} ${${PROJECT_NAME}_PYTHON_INSTALL_DIR} PARENT_SCOPE)
        return()
    endif()

    if(NOT Python_EXECUTABLE)
        message(
            FATAL_ERROR
            "Python_EXECUTABLE not defined.
        Please use xxx_find_package(Python REQUIRED COMPONENT Interpreter)"
        )
    endif()

    # purelib: directory for site-specific, non-platform-specific files (‘pure’ Python).
    # data: directory for data files (i.e. The root directory of the Python interpreter).
    # This should return Lib/site-packages on Windows and lib/pythonX.Y/site-packages on Linux
    execute_process(
        COMMAND
            ${Python_EXECUTABLE} -c
            "import sysconfig; from pathlib import Path; print(Path(sysconfig.get_path('purelib')).relative_to(sysconfig.get_path('data')))"
        OUTPUT_VARIABLE relative_python_sitelib_wrt_python_root_dir
        ERROR_VARIABLE error
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(error)
        message(
            FATAL_ERROR
            "Error while trying to compute the python binding install dir: ${error}"
        )
    endif()

    set(${output} "${relative_python_sitelib_wrt_python_root_dir}" PARENT_SCOPE)

    message("Computed python install dir ${output}=${relative_python_sitelib_wrt_python_root_dir}")
endfunction()

# function(xxx_find_python_pytest)
#     xxx_require_target(Python::Interpreter "Python::Interpreter not found. Make sure you have the Python interpreter using xxx_find_package(Python REQUIRED COMPONENTS Interpreter).")

#     if(TARGET Pytest::Pytest)
#         get_target_property(l Pytest::Pytest IMPORTED_LOCATION)
#         get_target_property(v Pytest::Pytest VERSION)
#         message(STATUS "Found pytest: ${l} (version: ${v})")
#         return()
#     endif()

#     # If python is installed via vcpkg and pytest installed via
#     # C:/vcpkg/installed/x64-windows/tools/python3/python.exe -m pip install pytest
#     # Then pytest will be located in C:/vcpkg/installed/x64-windows/tools/python3/Scripts/pytest.exe
#     # So we add an additional hint to find_program

#     cmake_path(GET Python_EXECUTABLE PARENT_PATH Python_ROOT)
#     find_program(pytest_EXECUTABLE pytest HINTS ${Python_ROOT} REQUIRED)

#     execute_process(COMMAND ${pytest_EXECUTABLE} --version OUTPUT_VARIABLE pytest_VERSION_FULL OUTPUT_STRIP_TRAILING_WHITESPACE)
#     string(REGEX MATCH "[0-9]+(\\.[0-9]+)*" pytest_VERSION "${pytest_VERSION_FULL}")

#     mark_as_advanced(pytest_EXECUTABLE pytest_VERSION)

#     add_executable(Pytest::Pytest IMPORTED)
#     set_target_properties(Pytest::Pytest
#         PROPERTIES
#             VERSION ${pytest_VERSION}
#             IMPORTED_LOCATION ${pytest_EXECUTABLE})
#     xxx_require_target(Pytest::Pytest "Pytest::Pytest not found. Make sure you have pytest installed and accessible in your PATH.")

#     message(STATUS "Found pytest: ${pytest_EXECUTABLE} (version: ${pytest_VERSION})")
# endfunction()

# function(xxx_python_compile_file filepath)
#     xxx_require_variable(Python_EXECUTABLE)

#     execute_process(
#         COMMAND ${Python_EXECUTABLE} -c "import py_compile; print(py_compile.compile(r'${filepath}', doraise=True), end='')"
#         OUTPUT_VARIABLE compiled_filepath
#         RESULT_VARIABLE result
#         ERROR_VARIABLE error
#         OUTPUT_STRIP_TRAILING_WHITESPACE
#         WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
#     )

#     if(error)
#         message(FATAL_ERROR "Failed to compile Python file '${filepath}': ${error}")
#     endif()

#     set_source_files_properties(${compiled_filepath} PROPERTIES GENERATED True)

#     cmake_path(CONVERT ${compiled_filepath} TO_CMAKE_PATH_LIST compiled_filepath NORMALIZE)
#     message(STATUS "Compiled Python file '${filepath}' to '${compiled_filepath}'")
# endfunction()

# function(xxx_python_compile_files)
#     set(options)
#     set(oneValueArgs GEN_DIR)
#     set(multiValueArgs FILES)
#     cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

#     xxx_require_variable(arg_FILES)
#     xxx_require_variable(arg_GEN_DIR)

#     # Each file needs to be relative to the current source dir to respect directory structure
#     foreach(file ${arg_FILES})
#         if(IS_ABSOLUTE ${file})
#             message(FATAL_ERROR "File '${file}' is absolute. Please provide relative paths to the current source directory (CMAKE_CURRENT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}).")
#         endif()
#     endforeach()

#     foreach(file ${arg_FILES})
#         cmake_path(GET file PARENT_PATH file_dir)
#         xxx_python_compile_file(
#             FILE ${file}
#             GEN_DIR ${arg_GEN_DIR}/${file_dir}
#         )
#     endforeach()
# endfunction()

# function(xxx_python_copy_files)
#     set(options COMPILE)
#     set(oneValueArgs OUTPUT_DIR)
#     set(multiValueArgs FILES)
#     cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

#     xxx_require_variable(arg_FILES)
#     xxx_require_variable(arg_GEN_DIR)

#     foreach(file ${arg_FILES})
#         if(IS_ABSOLUTE ${file})
#             message(FATAL_ERROR "File '${file}' is absolute. Please provide relative paths to the current source directory (CMAKE_CURRENT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}).")
#         endif()
#     endforeach()

#     foreach(file ${arg_FILES})
#         cmake_path(GET file PARENT_PATH file_dir)
#         file(COPY ${file} DESTINATION ${arg_GEN_DIR}/${file_dir})

#         if(arg_COMPILE)
#             execute_process(
#                 COMMAND ${Python_EXECUTABLE} -c "import py_compile; print(py_compile.compile(r'${file}', doraise=True), end='')"
#                 OUTPUT_VARIABLE compiled_file
#                 RESULT_VARIABLE result
#                 ERROR_VARIABLE error
#                 WORKING_DIRECTORY ${arg_GEN_DIR}
#             )
#             if(error)
#                 message(FATAL_ERROR "Failed to compile Python file '${file}': ${error}")
#             else()
#                 message(STATUS "Compiled Python file '${file}' to '${compiled_file}'")
#             endif()
#         endif()
#     endforeach()
# endfunction()
