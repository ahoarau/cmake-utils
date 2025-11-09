function(boostpy_add_module name)
    # Adapted from: https://github.com/wjakob/nanobind/blob/master/cmake/nanobind-config.cmake
    set(options)
    set(oneValueArgs)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 1 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    if(NOT TARGET Python::Module)
        message(
            FATAL_ERROR
            "You must invoke 'find_package(Python COMPONENTS Interpreter Development REQUIRED)' prior to including boostpy."
        )
    endif()

    # We always need to know the extension
    if(WIN32)
        set(BP_SUFFIX_EXT ".pyd")
    else()
        set(BP_SUFFIX_EXT "${CMAKE_SHARED_MODULE_SUFFIX}")
    endif()

    # Check if FindPython/scikit-build-core defined a SOABI/SOSABI variable
    if(DEFINED SKBUILD_SOABI)
        set(BP_SOABI "${SKBUILD_SOABI}")
    elseif(DEFINED Python_SOABI)
        set(BP_SOABI "${Python_SOABI}")
    endif()

    if(DEFINED SKBUILD_SOSABI)
        set(BP_SOSABI "${SKBUILD_SOSABI}")
    elseif(DEFINED Python_SOSABI)
        set(BP_SOSABI "${Python_SOSABI}")
    endif()

    # Error if scikit-build-core is trying to build Stable ABI < 3.12 wheels
    if(
        DEFINED SKBUILD_SABI_VERSION
        AND SKBUILD_ABI_VERSION
        AND SKBUILD_SABI_VERSION VERSION_LESS "3.12"
    )
        message(
            FATAL_ERROR
            "You must set tool.scikit-build.wheel.py-api to 'cp312' or later when "
            "using scikit-build-core with nanobind, '${SKBUILD_SABI_VERSION}' is too old."
        )
    endif()

    # PyPy sets an invalid SOABI (platform missing), causing older FindPythons to
    # report an incorrect value. Only use it if it looks correct (X-X-X form).
    if(DEFINED BP_SOABI AND "${BP_SOABI}" MATCHES ".+-.+-.+")
        set(BP_SUFFIX ".${BP_SOABI}${BP_SUFFIX_EXT}")
    endif()

    if(DEFINED BP_SOSABI)
        if(BP_SOSABI STREQUAL "")
            set(BP_SUFFIX_S "${BP_SUFFIX_EXT}")
        else()
            set(BP_SUFFIX_S ".${BP_SOSABI}${BP_SUFFIX_EXT}")
        endif()
    endif()

    # Extract Python version and extensions (e.g. free-threaded build)
    string(REGEX REPLACE "[^-]*-([^-]*)-.*" "\\1" BP_ABI "${BP_SOABI}")

    # If either suffix is missing, call Python to compute it
    if(NOT DEFINED BP_SUFFIX OR NOT DEFINED BP_SUFFIX_S)
        # Query Python directly to get the right suffix.
        execute_process(
            COMMAND
                "${Python_EXECUTABLE}" "-c"
                "import sysconfig; print(sysconfig.get_config_var('EXT_SUFFIX'))"
            RESULT_VARIABLE BP_SUFFIX_RET
            OUTPUT_VARIABLE EXT_SUFFIX
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        if(BP_SUFFIX_RET AND NOT BP_SUFFIX_RET EQUAL 0)
            message(
                FATAL_ERROR
                "boostpy: Python sysconfig query to "
                "find 'EXT_SUFFIX' property failed!"
            )
        endif()

        if(NOT DEFINED BP_SUFFIX)
            set(BP_SUFFIX "${EXT_SUFFIX}")
        endif()

        if(NOT DEFINED BP_SUFFIX_S)
            get_filename_component(BP_SUFFIX_EXT "${EXT_SUFFIX}" LAST_EXT)
            if(WIN32)
                set(BP_SUFFIX_S "${BP_SUFFIX_EXT}")
            else()
                set(BP_SUFFIX_S ".abi3${BP_SUFFIX_EXT}")
            endif()
        endif()
    endif()

    add_library(${name} MODULE ${arg_UNPARSED_ARGUMENTS})
    set_target_properties(${name} PROPERTIES PREFIX "" SUFFIX "${BP_SUFFIX}")
    target_link_libraries(${name} PRIVATE Python::Module Boost::python)
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
    message(STATUS "Python module '${name}' link libraries: [${python_module_link_libraries}]")

    set(dlls_to_link "")
    list(REMOVE_DUPLICATES python_module_link_libraries)
    foreach(target IN LISTS python_module_link_libraries)
        get_target_property(target_type ${target} TYPE)
        get_target_property(is_imported ${target} IMPORTED)
        message(STATUS "Checking target '${target}' of type '${target_type}' for dll linking. Imported: '${is_imported}'")

        if(target_type STREQUAL "SHARED_LIBRARY" OR target_type STREQUAL "MODULE_LIBRARY" AND NOT ${is_imported})
            message(STATUS "Adding target '${target}' to dlls to link for python module '${name}'")
            list(APPEND dlls_to_link ${target})
        endif()
    endforeach()

    message(STATUS "Python module '${name}' depends on the following buildsystem dlls: [${dlls_to_link}]")

    # Get the relative paths between the python module and each dll
    set(all_rel_paths "")
    foreach(dll_name IN LISTS dlls_to_link)
        get_target_property(python_module_dir ${name} LIBRARY_OUTPUT_DIRECTORY)
        xxx_require_variable(python_module_dir "LIBRARY_OUTPUT_DIRECTORY not set for target '${name}', add it using 'set_target_properties(<target> PROPERTIES LIBRARY_OUTPUT_DIRECTORY <dir>)'")

        get_target_property(dll_dir ${dll_name} RUNTIME_OUTPUT_DIRECTORY)
        xxx_require_variable(dll_dir)

        file(RELATIVE_PATH rel_path
            ${python_module_dir}
            ${dll_dir}
        )
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
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/__init__.py.in
        ${CMAKE_BINARY_DIR}/lib/site-packages/${PROJECT_NAME}_bp/__init__.py
        @ONLY
    )
endfunction()

boostpy_add_module(test_project_pywrap_bp bindings.cpp)
target_link_libraries(test_project_pywrap_bp PRIVATE test_project)
xxx_target_set_default_compile_options(test_project_pywrap_bp PRIVATE)

set_target_properties(
    test_project_pywrap_bp
    PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/site-packages/${PROJECT_NAME}_bp
)
xxx_python_generate_init_py(
    test_project_pywrap_bp
    OUTPUT_PATH ${CMAKE_BINARY_DIR}/lib/site-packages/${PROJECT_NAME}_bp
)
install(
    TARGETS test_project_pywrap_bp
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/site-packages/${PROJECT_NAME}_bp
)
install(
    FILES ${CMAKE_BINARY_DIR}/lib/site-packages/${PROJECT_NAME}_bp/__init__.py
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/site-packages/${PROJECT_NAME}_bp
)

function(boostpy_add_stubs name)
    set(options VERBOSE)
    set(oneValueArgs MODULE OUTPUT PYTHON_PATH DEPENDS)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 1 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    if(NOT arg_MODULE)
        message(FATAL_ERROR "MODULE argument is required")
    endif()

    if(NOT arg_OUTPUT)
        message(FATAL_ERROR "OUTPUT argument is required")
    endif()

    if(NOT arg_PYTHON_PATH)
        set(pythonpath "")
    else()
        set(pythonpath "PYTHONPATH=${arg_PYTHON_PATH}")
    endif()

    if(arg_VERBOSE)
        set(loglevel "--log-level=DEBUG")
    endif()

    set(stubgen_py ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../../external-modules/pybind11-stubgen-e48d1f1/pybind11_stubgen.py)
    if(NOT EXISTS ${stubgen_py})
        message(FATAL_ERROR "Could not find 'pybind11_stubgen.py' at expected location: ${stubgen_py}")
    endif()
    cmake_path(CONVERT ${stubgen_py} TO_CMAKE_PATH_LIST stubgen_py NORMALIZE)

    add_custom_command(
        OUTPUT ${arg_OUTPUT}
        COMMAND ${CMAKE_COMMAND} -E env ${pythonpath} $<TARGET_FILE:Python::Interpreter> ${stubgen_py} --output-dir ${arg_OUTPUT} ${arg_MODULE} ${loglevel} --boost-python --ignore-invalid signature --no-setup-py
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        DEPENDS ${arg_DEPENDS}
        VERBATIM
        COMMENT "Generating boost python stubs for module '${arg_MODULE}'"
    )
    add_custom_target(${name} ALL DEPENDS ${arg_OUTPUT})
    if(arg_DEPENDS)
        add_dependencies(${name} ${arg_DEPENDS})
    endif()
endfunction()

boostpy_add_stubs(
    test_project_pywrap_bp_stubs
    MODULE test_project_bp
    OUTPUT ${CMAKE_BINARY_DIR}/lib/site-packages
    PYTHON_PATH ${CMAKE_BINARY_DIR}/lib/site-packages
    DEPENDS test_project_pywrap_bp
    VERBOSE
)
install(
    DIRECTORY ${CMAKE_BINARY_DIR}/lib/site-packages/test_project_bp-stubs
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/site-packages
)
