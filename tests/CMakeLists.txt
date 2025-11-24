add_subdirectory(test_project)

function(add_cmake_test dir)
    set(configure_step "Configure ${dir}")
    add_test(
        NAME ${configure_step}
        COMMAND
            ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_SOURCE_DIR}/${dir} -B
            ${CMAKE_CURRENT_BINARY_DIR}/${dir}/build
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )

    set(build_step "Build ${dir}")
    add_test(
        NAME ${build_step}
        COMMAND ${CMAKE_COMMAND} --build ${CMAKE_CURRENT_BINARY_DIR}/${dir}/build
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    set_tests_properties(${build_step} PROPERTIES DEPENDS ${configure_step})

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

add_cmake_test(test_project_without_deps)
add_cmake_test(packaging/fetchcontent)
