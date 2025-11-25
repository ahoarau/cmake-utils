function(add_cmake_test dir)
    set(configure_step "Configure ${dir}")
    add_test(
        NAME ${configure_step}
        COMMAND
            ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_SOURCE_DIR}/${dir} -B
            ${CMAKE_CURRENT_BINARY_DIR}/${dir}/build -DCMAKE_UTILS_SOURCE_DIR=${PROJECT_SOURCE_DIR}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )

    set(build_step "Build ${dir}")
    add_test(
        NAME ${build_step}
        COMMAND ${CMAKE_COMMAND} --build ${CMAKE_CURRENT_BINARY_DIR}/${dir}/build
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    set_tests_properties(${build_step} PROPERTIES DEPENDS ${configure_step})

    set(test_step "Test ${dir}")
    add_test(
        NAME ${test_step}
        COMMAND
            ${CMAKE_CTEST_COMMAND} --test-dir ${CMAKE_CURRENT_BINARY_DIR}/${dir}/build
            --output-on-failure
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    set_tests_properties(${test_step} PROPERTIES DEPENDS ${build_step})

    set(install_step "Install ${dir}")
    add_test(
        NAME ${install_step}
        COMMAND
            ${CMAKE_COMMAND} --install ${CMAKE_CURRENT_BINARY_DIR}/${dir}/build --prefix
            ${CMAKE_CURRENT_BINARY_DIR}/${dir}/install
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    set_tests_properties(${install_step} PROPERTIES DEPENDS ${build_step})
endfunction()

add_cmake_test(test_project)
add_cmake_test(test_project_without_deps)
add_cmake_test(packaging/fetchcontent)
