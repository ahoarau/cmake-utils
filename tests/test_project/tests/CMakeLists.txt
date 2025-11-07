add_executable(test_StringUtils test_StringUtils.cpp)
target_link_libraries(test_StringUtils PRIVATE test_project Catch2::Catch2WithMain)

catch_discover_tests(test_StringUtils)

function(xxx_find_python_pytest)
    xxx_require_target(Python::Interpreter "Python::Interpreter not found. Make sure you have the Python interpreter using find_package(Python COMPONENTS Interpreter).")
    execute_process(COMMAND ${Python_EXECUTABLE} -c "import os; import pytest; print(os.path.dirname(pytest.__file__))"
        OUTPUT_VARIABLE pytest_ROOT
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT pytest_ROOT)
        message(FATAL_ERROR "pytest not found. Please install pytest in your Python environment.")
    endif()
    execute_process(COMMAND ${Python_EXECUTABLE} -m pytest --version OUTPUT_VARIABLE pytest_VERSION_FULL OUTPUT_STRIP_TRAILING_WHITESPACE)
    # pytest --version gives "pytest 6.2.4"
    string(REGEX MATCH "[0-9]+(\\.[0-9]+)*" pytest_VERSION "${pytest_VERSION_FULL}")
    message(STATUS "Found pytest: ${pytest_ROOT} (version: ${pytest_VERSION})")
endfunction()

xxx_find_python_pytest()

add_test(NAME "Test Nanobind Bindings"
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${CMAKE_BINARY_DIR}/lib/site-packages ${Python_EXECUTABLE} -m pytest ${CMAKE_CURRENT_SOURCE_DIR}/test_nanobind_bindings.py
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)

add_test(NAME "Test Boost Python Bindings"
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${CMAKE_BINARY_DIR}/lib/site-packages ${Python_EXECUTABLE} -m pytest ${CMAKE_CURRENT_SOURCE_DIR}/test_boostpy_bindings.py
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)
