add_executable(test_StringUtils test_StringUtils.cpp)
target_link_libraries(test_StringUtils PRIVATE test_project Catch2::Catch2WithMain)

catch_discover_tests(test_StringUtils)

add_test(NAME "Test Nanobind Bindings"
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${CMAKE_BINARY_DIR}/lib/site-packages $<TARGET_FILE:Pytest::Pytest> ${CMAKE_CURRENT_SOURCE_DIR}/test_nanobind_bindings.py
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)

add_test(NAME "Test Boost Python Bindings"
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${CMAKE_BINARY_DIR}/lib/site-packages $<TARGET_FILE:Pytest::Pytest> ${CMAKE_CURRENT_SOURCE_DIR}/test_boostpy_bindings.py
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)
