add_executable(test_StringUtils test_StringUtils.cpp)
target_link_libraries(test_StringUtils PRIVATE test_project Catch2::Catch2WithMain)

catch_discover_tests(test_StringUtils)

find_program(pytest pytest REQUIRED)
execute_process(COMMAND ${pytest} --version OUTPUT_VARIABLE pytest_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "Found pytest: ${pytest} (${pytest_VERSION})")

add_test(NAME pytest_bindings
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${CMAKE_BINARY_DIR}/lib/site-packages pytest ${CMAKE_CURRENT_SOURCE_DIR}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)
