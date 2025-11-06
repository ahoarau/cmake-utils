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

    # ---------------------------------------------------------------------------
    # Helper function to handle undefined CPython API symbols on macOS
    # ---------------------------------------------------------------------------

    function(boostpy_link_options name)
        if(APPLE)
            if(Python_INTERPRETER_ID STREQUAL "PyPy")
                set(BP_LINKER_RESPONSE_FILE darwin-ld-pypy.sym)
            else()
                set(BP_LINKER_RESPONSE_FILE darwin-ld-cpython.sym)
            endif()
            target_link_options(${name} PRIVATE "-Wl,@${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${BP_LINKER_RESPONSE_FILE}")
        endif()
    endfunction()

    add_library(${name} MODULE ${arg_UNPARSED_ARGUMENTS})
    set_target_properties(${name} PROPERTIES PREFIX "" SUFFIX "${NB_SUFFIX}")
    target_link_libraries(${name} PRIVATE Python::Module Boost::python)
    boostpy_link_options(${name})
endfunction()

boostpy_add_module(test_project_pywrap_bp bindings.cpp)
target_link_libraries(test_project_pywrap_bp PRIVATE test_project)

set(PYTHON_MODULE_NAME "test_project_pywrap_bp")
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/__init__.py.in
    ${CMAKE_BINARY_DIR}/lib/site-packages/${PROJECT_NAME}_bp/__init__.py
    @ONLY
)

set_target_properties(
    test_project_pywrap_bp
    PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/site-packages/${PROJECT_NAME}_bp
)
xxx_target_set_default_compile_options(test_project_pywrap_bp PRIVATE)
