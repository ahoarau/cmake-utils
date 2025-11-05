# gersemi: off
cmake_minimum_required(VERSION 3.22...4.1)

macro(xxx_use_external_modules)
  set(utils_ROOT ${CMAKE_CURRENT_LIST_DIR}/..)
  cmake_path(CONVERT "${utils_ROOT}" TO_CMAKE_PATH_LIST utils_ROOT NORMALIZE)

  # Adding the pytest_discover_tests function for pytest
  # repo: https://github.com/python-cmake/pytest-cmake
  include(${utils_ROOT}/external-modules/pytest-cmake/PytestAddTests.cmake)
  list(APPEND CMAKE_MODULE_PATH ${utils_ROOT}/external-modules/pytest-cmake)

  # Adding the boosttest_discover_tests function for Boost Unit Testing
  # repo: https://github.com/DenizThatMenace/cmake-modules
  include(${utils_ROOT}/external-modules/boost-test/BoostTestDiscoverTests.cmake)
  list(APPEND CMAKE_MODULE_PATH ${utils_ROOT}/external-modules/boost-test)

  list(REMOVE_DUPLICATES CMAKE_MODULE_PATH)
  unset(utils_ROOT)
endmacro()

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
        message(FATAL_ERROR "visibility (${visibility}) must be one of PRIVATE, PUBLIC or INTERFACE")
    endif()
endfunction()

# Include CTest but simply prevent adding a lot of useless targets. Useful for IDEs.
function(xxx_include_ctest)
    set_property(GLOBAL PROPERTY CTEST_TARGETS_ADDED 1)
    include(CTest)
endfunction()

macro(xxx_configure_apple_rpath)
  if(APPLE) # Ensure that the policy if is only applied on OSX systems
    xxx_require_variable(CMAKE_INSTALL_PREFIX)

    set(CMAKE_MACOSX_RPATH True)
    set(CMAKE_SKIP_BUILD_RPATH False)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH False)
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH True)
    set(CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_PREFIX}/lib)
  endif()
endmacro()

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
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE PATH "") # For .exe and .dll add_library(SHARED ...) .dll
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE PATH "") # for add_library(MODULE ...) .dll
        set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "") # add_library(STATIC ...) .lib
    else()
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE PATH "") # For .exe and .dll
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "") # for shared libraries .so/.dylib and add_library(MODULE ...) .so/.dylib
        set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "") # add_library(STATIC ...) .a
    endif()

    # set(config Debug Release RelWithDebInfo MinSizeRel)
    # foreach(conf ${config})
    #     string(TOUPPER ${conf} conf_upper)
    #     set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${conf_upper} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY} CACHE PATH "")
    #     set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${conf_upper} ${CMAKE_LIBRARY_OUTPUT_DIRECTORY} CACHE PATH "")
    #     set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${conf_upper} ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY} CACHE PATH "")
    # endforeach()
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
        set(library_version ${PROJECT_VERSION})
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

    xxx_target_headers(${target_name} ${visibility} HEADERS ${output_file} BASE_DIRS ${arg_HEADER_DIR})
endfunction()

function(xxx_target_generate_warning_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")
    
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
        ${skip_install}
    )
endfunction()

function(xxx_target_generate_deprecated_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")
    
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
        ${skip_install}
    )
endfunction()

function(xxx_target_generate_config_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")
    
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
        ${skip_install}
    )
endfunction()

function(xxx_target_generate_tracy_header target_name visibility)
    set(options SKIP_INSTALL)
    set(oneValueArgs FILENAME HEADER_DIR INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")
    
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
    string(ASCII 27 Esc)
    message("${Esc}[1;34m" "[${ARGV0}]" "${Esc}[m")
    message(DEBUG "Executing xxx_find_package with args ${ARGV}")

    set(options)
    set(oneValueArgs MODULE_PATH)
    set(multiValueArgs)
    cmake_parse_arguments(arg "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Pkg name is the first argument of find_package(<pkg_name> ...)
    set(package_name ${ARGV0})
    set(find_package_args "${arg_UNPARSED_ARGUMENTS}")

    # Handle custom module file
    if(arg_MODULE_PATH)
        set(module_file "${arg_MODULE_PATH}/Find${package_name}.cmake")
        if(NOT EXISTS ${module_file})
            message(FATAL_ERROR "Custom module file provided with MODULE_PATH ${module_file} does not exist.")
        endif()
    else()
        # search for the module file only is CONFIG is not in the find_package args
        if(NOT "${find_package_args}" MATCHES "CONFIG")
            xxx_search_package_module_file(${package_name} module_file)
        endif()
    endif()

    if(module_file)
        cmake_path(CONVERT "${module_file}" TO_CMAKE_PATH_LIST module_file NORMALIZE)
        set(using_custom_module true)
    else() 
        set(using_custom_module false)
    endif()

    if(module_file)
        # Copy the module file to the generated cmake directory in the build dir
        file(COPY ${module_file} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME}/find-modules/${package_name})

        # Add the parent path to the CMAKE_MODULE_PATH
        cmake_path(GET module_file PARENT_PATH module_dir)
        list(APPEND CMAKE_MODULE_PATH ${module_dir})
        message("   Using custom module file: ${module_file}")
    endif()

    # Call find_package with the provided arguments
    string(REPLACE ";" " " fp_pp "${find_package_args}")
    message("   Executing find_package(${fp_pp})")

    # Saving the list of imported targets and variables BEFORE the call to find_package
    get_property(imported_targets_before DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY IMPORTED_TARGETS)
    get_property(variables_before DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VARIABLES)

    find_package(${find_package_args}) # TODO: handle QUIET properly

    # Getting the list of imported targets and variables AFTER the call to find_package
    get_property(package_variables DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VARIABLES)
    get_property(package_targets DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY IMPORTED_TARGETS)
    list(REMOVE_ITEM package_variables ${variables_before} variables_before)
    list(REMOVE_ITEM package_targets ${imported_targets_before})
    
    unset(variables_before)
    unset(imported_targets_before)

    if(${package_name}_VERSION)
        message("   Version: ${${package_name}_VERSION}")
    endif()

    string(REPLACE ";" ", " package_variables_pp "${package_variables}")
    if(package_variables)
        message(DEBUG "   New variables detected: ${package_variables_pp}")
    else()
        message("   No new variables detected.")
    endif()
    unset(package_variables_pp)

    string(REPLACE ";" ", " package_targets_pp "${package_targets}")
    if(package_targets)
        message("   Imported targets detected: ${package_targets_pp}")
    else()
        message("   No imported targets detected.")
    endif()
    unset(package_targets_pp)

    get_property(deps GLOBAL PROPERTY _xxx_${PROJECT_NAME}_package_dependencies)
    if(NOT deps)
        string(JSON deps SET "{}" "package_dependencies" "[]")
    endif()

    set(package_json "{}")
    string(REPLACE ";" " " find_package_args "${find_package_args}")
    string(JSON package_json SET "${package_json}" "package_name" "\"${package_name}\"")
    string(JSON package_json SET "${package_json}" "find_package_args" "\"${find_package_args}\"")
    string(JSON package_json SET "${package_json}" "package_variables" "\"${package_variables}\"")
    string(JSON package_json SET "${package_json}" "package_targets" "\"${package_targets}\"")
    string(JSON package_json SET "${package_json}" "using_custom_module" "\"${using_custom_module}\"")


    string(JSON deps_length LENGTH "${deps}" "package_dependencies")
    string(JSON deps SET "${deps}" "package_dependencies" ${deps_length} "${package_json}")

    set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_package_dependencies "${deps}")

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

    message( "")
    message( "================= External Dependencies ======================================")
    message( "")

    string(JSON num_deps LENGTH "${deps}" "package_dependencies")
    math(EXPR max_idx "${num_deps} - 1")
    message("${num_deps} dependencies declared xxx_find_package: ")
    foreach(i RANGE 0 ${max_idx})
        string(JSON package_name GET "${deps}" "package_dependencies" ${i} "package_name")
        string(JSON package_targets GET "${deps}" "package_dependencies" ${i} "package_targets")

        # Replace ; by , for better readability
        string(REPLACE ";" ", " package_targets_pp "${package_targets}")
        math(EXPR i "${i} + 1")
        message("${i}/${num_deps} Package [${package_name}] imported targets [${package_targets_pp}]")

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
  set(options )
  set(oneValueArgs VERBOSITY)
  set(cpp_multiValueArgs PROPERTIES)
  set(cppmode_multiValueArgs TARGETS SOURCES TESTS DIRECTORIES CACHE_ENTRIES )

  string(JOIN " " _mode_names ${cppmode_multiValueArgs})
  set(_missing_mode_message
    "Mode keyword missing in xxx_cmake_print_properties() call, there must be exactly one of ${_mode_names}")

  cmake_parse_arguments(
    CPP "${options}" "${oneValueArgs}" "${cpp_multiValueArgs}" ${ARGN})

  if(NOT CPP_PROPERTIES)
    message(FATAL_ERROR
      "Required argument PROPERTIES missing in xxx_cmake_print_properties() call")
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
    CPPMODE "${options}" "${oneValueArgs}" "${cppmode_multiValueArgs}"
    ${CPP_UNPARSED_ARGUMENTS})

  if(CPPMODE_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR
      "Unknown keywords given to cmake_print_properties(): \"${CPPMODE_UNPARSED_ARGUMENTS}\"")
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
    message(FATAL_ERROR
      "Multiple mode keywords used in cmake_print_properties() call, there must be exactly one of ${_mode_names}.")
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

    if (itemExists)
      string(APPEND msg " Properties for ${keyword} ${item}:\n")
      foreach(prop ${CPP_PROPERTIES})

        get_property(propertySet ${keyword} ${item} PROPERTY "${prop}" SET)

        if(propertySet)
          get_property(property ${keyword} ${item} PROPERTY "${prop}")
        #   string(APPEND msg "   ${item}.${prop} = \"${property}\"\n")
          pad_string("${prop}"      40 _prop)
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


# Usage: xxx_export_dependencies(TARGETS <target1> <target2> ... DESTINATION <destination> GEN_DIR <gen_dir> COMPONENT <component>)
# This function analyzes the link libraries of the provided targets,
# determines which packages are needed and generates a <export_name>-dependencies.cmake file
function(xxx_export_dependencies)
    set(options)
    set(oneValueArgs DESTINATION GEN_DIR COMPONENT)
    set(multiValueArgs TARGETS)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(arg_TARGETS)
    xxx_require_variable(arg_DESTINATION)
    xxx_require_variable(arg_COMPONENT)

    if(NOT arg_GEN_DIR)
        set(arg_GEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME})
    endif()

    # Get all BUILDSYSTEM_TARGETS of the current project (i.e. added via add_library/add_executable)
    # We need this to filter out internal targets when analyzing link libraries
    get_property(buildsystem_targets DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY BUILDSYSTEM_TARGETS)
    foreach(target ${arg_TARGETS})
        if(NOT target IN_LIST buildsystem_targets)
            message(FATAL_ERROR "Target '${target}' is not a buildsystem target of the current project. Cannot export dependencies for it.")
        endif()
    endforeach()

    set(all_link_libraries "")
    foreach(target ${arg_TARGETS})
        get_target_property(interface_link_libraries ${target} INTERFACE_LINK_LIBRARIES)
        if(NOT interface_link_libraries)
            message("Target '${target}' has no INTERFACE_LINK_LIBRARIES.")
        else()
            list(APPEND all_link_libraries ${interface_link_libraries})
        endif()
    endforeach()

    message("All link libraries for targets '${arg_TARGETS}': ${all_link_libraries}") 

    file(GENERATE 
        OUTPUT "${arg_GEN_DIR}/${PROJECT_NAME}-component-${arg_COMPONENT}-link-libraries.cmake"
        CONTENT "
# Generated file - do not edit
# This file contains the list of buildsystem targets and all imported libraries linked by the exported targets
set(buildsystem_targets \"${buildsystem_targets}\")
set(imported_libraries \"${all_link_libraries}\")
"
    )

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/generate-dependencies.cmake.in ${arg_GEN_DIR}/${PROJECT_NAME}-component-${arg_COMPONENT}-generate-dependencies.cmake @ONLY)
    install(SCRIPT ${arg_GEN_DIR}/${PROJECT_NAME}-component-${arg_COMPONENT}-generate-dependencies.cmake)
    install(FILES ${arg_GEN_DIR}/${PROJECT_NAME}-component-${arg_COMPONENT}-dependencies.cmake
        DESTINATION ${arg_DESTINATION}
    )
endfunction()

# xxx_declare_component(COMPONENT <component_name> TARGETS <target1> <target2> ...)
# Declare a component for the current project, with associated targets.
# Each component declared and associated to a set of targets will have its own <package>-component-<component>-targets.cmake 
# and <package>-component-<component>-dependencies.cmake generated.
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
        message(WARNING "No headers declared for target '${target}'. Skipping installation.")
        return()
    endif()

    file(GENERATE 
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME}/${target}-install-headers.cmake
        CONTENT "
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

    cmake_path(IS_ABSOLUTE header is_abs)
    if(is_abs)
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
    install(SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME}/${target}-install-headers.cmake)
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
    cmake_language(DEFER CALL _xxx_dump_package_dependencies_json())

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
    set(PACKAGE_CONFIG_INPUT ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/config.cmake.in)
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

    # find-modules/Find<pkg>.cmake 
    # Install the find-modules used for this component
    # TODO: only install the ones that are actually used
    install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME}/find-modules
        DESTINATION ${DESTINATION}
        FILES_MATCHING PATTERN "Find*.cmake"
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

        # <package>-component-<component>-dependencies.cmake
        xxx_export_dependencies(
            TARGETS ${targets}
            COMPONENT ${component}
            DESTINATION ${DESTINATION}
            NAMESPACE ${NAMESPACE}
        )
        # Create the export for the component targets
        install(TARGETS ${targets}
            EXPORT ${PROJECT_NAME}-${component}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        )
        # <package>-component-<component>-targets.cmake
        install(EXPORT ${PROJECT_NAME}-${component}
            FILE ${PROJECT_NAME}-component-${component}-targets.cmake
            NAMESPACE ${NAMESPACE}
            DESTINATION ${DESTINATION}
        )
    endforeach()
endfunction()

# _xxx_dump_package_dependencies_json()
# Internal function to dump the package dependencies recorded with xxx_find_package()
# It is called at the end of the configuration step via cmake_language(DEFER CALL ...)
# In the function xxx_generate_package_module_files().
function(_xxx_dump_package_dependencies_json)
    get_property(package_dependencies_json GLOBAL PROPERTY _xxx_${PROJECT_NAME}_package_dependencies)
    if(NOT package_dependencies_json)
        message(STATUS "No package dependencies recorded with xxx_find_package().")
        return()
    endif()
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/generated/cmake/${PROJECT_NAME}/${PROJECT_NAME}-package-dependencies.json "${package_dependencies_json}")
endfunction()

# xxx_option(<option_name> <description> <default_value>)
# Example: xxx_option(BUILD_TESTING "Build the tests" ON)
# Override cmake option() to get a nice summary at the end of the configuration step
function(xxx_option option_name description default_value)
    option(${ARGV})

    set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_option_${option_name}_default_value ${default_value})
    set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_option_names ${option_name} APPEND)
endfunction()

function(xxx_cmake_dependent_option option_name description default_value condition else-value)
    include(CMakeDependentOption)
    cmake_dependent_option(${ARGV})

    set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_option_${option_name}_default_value ${default_value})
    set_property(GLOBAL PROPERTY _xxx_${PROJECT_NAME}_option_names ${option_name} APPEND)
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
# Usage: xxx_print_options_summary()
function(xxx_print_options_summary)
    get_property(option_names GLOBAL PROPERTY _xxx_${PROJECT_NAME}_option_names)
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
        get_property(_default GLOBAL PROPERTY _xxx_${PROJECT_NAME}_option_${option_name}_default_value)
        get_property(_help CACHE ${option_name} PROPERTY HELPSTRING)

        pad_string("${option_name}"      40 _name)
        pad_string("${_type}"     5 _type)
        pad_string("${_val}"      8 _val)
        pad_string("${_default}"  5 _default)
        pad_string("${_help}"     25 _help)

        message( "${_name} | ${_type} | ${_val} | ${_help} (${_default})")
    endforeach()

    message( "------------------------------------------------------------------------------")
    message( "")
endfunction()

# Shortcut to find Python package and check main variables
# Usage: xxx_find_python([version] [REQUIRED] [COMPONENTS ...])
# Example: xxx_find_python(3.8 REQUIRED COMPONENTS Interpreter Development.Module)
macro(xxx_find_python)
    xxx_find_package(Python ${ARGN})

    # On Windows, Python_SITELIB returns \. Let's convert it to /.
    cmake_path(CONVERT ${Python_SITELIB} TO_CMAKE_PATH_LIST Python_SITELIB NORMALIZE)

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
    string(REPLACE ";" " " args_pp "${ARGN}")
    xxx_require_variable(Python_EXECUTABLE "Python executable not found (variable Python_EXECUTABLE).
        
    Please call xxx_find_python(<args>) first, e.g.:

        xxx_find_python(3.8 REQUIRED COMPONENTS Interpreter Development.Module)
        xxx_find_package(nanobind ${args_pp})
    ")
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
        message(FATAL_ERROR "Failed to find nanobind package: ${nanobind_error}")
    endif()
    
    message("   Nanobind CMake directory: ${nanobind_ROOT}")
    xxx_find_package(nanobind ${ARGN})
endmacro()

function(xxx_python_compile_file)
    set(options)
    set(oneValueArgs FILE GEN_DIR)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(Python_EXECUTABLE)

    xxx_require_variable(arg_FILE)
    xxx_require_variable(arg_GEN_DIR)

    execute_process(
        COMMAND ${Python_EXECUTABLE} -c "import py_compile; print(py_compile.compile(r'${arg_FILE}', doraise=True), end='')"
        OUTPUT_VARIABLE compiled_file
        RESULT_VARIABLE result
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )

    message(STATUS "Compiled Python file '${arg_FILE}' to '${compiled_file}'")

    cmake_path(CONVERT ${compiled_file} TO_CMAKE_PATH_LIST compiled_file NORMALIZE)
    cmake_path(GET compiled_file FILENAME output_filename)

    if(NOT result EQUAL 0)
        message(FATAL_ERROR "Failed to compile Python file '${arg_FILE}'")
    endif()

    file(COPY ${arg_FILE} DESTINATION ${arg_GEN_DIR})
    file(COPY ${compiled_file} DESTINATION ${arg_GEN_DIR}/__pycache__)
    set_source_files_properties(${compiled_file} PROPERTIES GENERATED True)
endfunction()


function(xxx_python_compile_files)
    set(options)
    set(oneValueArgs GEN_DIR)
    set(multiValueArgs FILES)
    cmake_parse_arguments(PARSE_ARGV 0 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    xxx_require_variable(arg_FILES)
    xxx_require_variable(arg_GEN_DIR)

    # Each file needs to be relative to the current source dir to respect directory structure
    foreach(file ${arg_FILES})
        if(IS_ABSOLUTE ${file})
            message(FATAL_ERROR "File '${file}' is absolute. Please provide relative paths to the source directory (CMAKE_CURRENT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}).")
        endif()
    endforeach()

    foreach(file ${arg_FILES})
        cmake_path(GET file PARENT_PATH file_dir)
        xxx_python_compile_file(
            FILE ${file}
            GEN_DIR ${arg_GEN_DIR}/${file_dir}
        )
    endforeach()
endfunction()


# gersemi: on
