function(boostpy_add_module name)
    # Adapted from: https://github.com/wjakob/nanobind/blob/master/cmake/nanobind-config.cmake
    set(options)
    set(oneValueArgs)
    set(multiValueArgs)
    cmake_parse_arguments(PARSE_ARGV 1 arg "${options}" "${oneValueArgs}" "${multiValueArgs}")

    if(NOT TARGET Python::Module)
        message(
            FATAL_ERROR
            "
            Python::Module target not found.
            Please call find_package(Python REQUIRED COMPONENTS Interpreter Development) prior to calling boostpy_add_module.
        "
        )
    endif()

    if(NOT TARGET Boost::python)
        message(
            FATAL_ERROR
            "
            Boost::python target not found.
            Please call find_package(Boost REQUIRED COMPONENTS python) prior to calling boostpy_add_module.
        "
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

    set(stubgen_py
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../external-modules/pybind11-stubgen-e48d1f1/pybind11_stubgen.py
    )
    if(NOT EXISTS ${stubgen_py})
        message(
            FATAL_ERROR
            "Could not find 'pybind11_stubgen.py' at expected location: ${stubgen_py}"
        )
    endif()
    cmake_path(CONVERT ${stubgen_py} TO_CMAKE_PATH_LIST stubgen_py NORMALIZE)

    add_custom_command(
        OUTPUT ${arg_OUTPUT}
        COMMAND
            ${CMAKE_COMMAND} -E env ${pythonpath} $<TARGET_FILE:Python::Interpreter> ${stubgen_py}
            --output-dir ${arg_OUTPUT} ${arg_MODULE} ${loglevel} --boost-python
            --ignore-invalid=signature --no-setup-py --no-root-module-suffix
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
