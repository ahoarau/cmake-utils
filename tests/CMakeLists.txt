function(add_cmake_test dir)
    cmake_parse_arguments(arg "" "" "EXTRA_OPTIONS" ${ARGN})
    string(SHA256 hash "${dir};${arg_EXTRA_OPTIONS}")
    string(SUBSTRING ${hash} 0 8 test_id)
    # gersemi: off
    add_test(
        NAME "${dir} ${arg_EXTRA_OPTIONS} (test_id=${test_id})"
        COMMAND ${CMAKE_CTEST_COMMAND}
        --build-and-test "${CMAKE_CURRENT_SOURCE_DIR}/${dir}"
                        "${CMAKE_CURRENT_BINARY_DIR}/${dir}/${test_id}/build"
        ${arg_EXTRA_OPTIONS}
        --build-config "Release"
        --build-generator "${CMAKE_GENERATOR}"
        --build-target install
        --build-options "-DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/${dir}/${test_id}/install"
    )
    # gersemi: on
endfunction()

add_cmake_test(test_project)
add_cmake_test(test_project EXTRA_OPTIONS "--build-noclean")
add_cmake_test(test_project EXTRA_OPTIONS "--build-noclean" "--build-two-config")

add_cmake_test(test_project_without_deps)
add_cmake_test(test_project_without_deps EXTRA_OPTIONS "--build-noclean")
add_cmake_test(test_project_without_deps EXTRA_OPTIONS "--build-noclean" "--build-two-config")

add_cmake_test(packaging/fetchcontent)
