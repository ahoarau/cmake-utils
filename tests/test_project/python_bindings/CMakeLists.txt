nanobind_add_module(test_project_pywrap
    NB_STATIC STABLE_ABI LTO
    bindings.cpp
)

set(PYTHON_MODULE_NAME "test_project_pywrap")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/__init__.py.in
    ${CMAKE_BINARY_DIR}/lib/site-packages/${PROJECT_NAME}/__init__.py
    @ONLY
)

set_target_properties(test_project_pywrap PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/site-packages/${PROJECT_NAME}
)
target_link_libraries(test_project_pywrap PRIVATE test_project)
xxx_target_set_default_compile_options(test_project_pywrap PRIVATE)

nanobind_add_stub(
    test_project_pywrap_stub
    MODULE test_project
    OUTPUT ${CMAKE_BINARY_DIR}/lib/site-packages/${PROJECT_NAME}/test_project_pywrap.pyi
    PYTHON_PATH ${CMAKE_BINARY_DIR}/lib/site-packages
    DEPENDS test_project_pywrap
    VERBOSE
)