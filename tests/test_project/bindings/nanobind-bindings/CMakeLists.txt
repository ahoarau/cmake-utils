nanobind_add_module(test_project_pywrap
    NB_STATIC STABLE_ABI LTO
    bindings.cpp
)
set_target_properties(test_project_pywrap PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/site-packages/test_project
)

xxx_python_generate_init_py(
    test_project_pywrap
    OUTPUT_PATH ${CMAKE_BINARY_DIR}/lib/site-packages/test_project/__init__.py
)

target_link_libraries(test_project_pywrap PRIVATE test_project)
xxx_target_set_default_compile_options(test_project_pywrap PRIVATE)

nanobind_add_stub(
    test_project_pywrap_stub
    MODULE test_project
    OUTPUT ${CMAKE_BINARY_DIR}/lib/site-packages/test_project/test_project_pywrap.pyi
    PYTHON_PATH ${CMAKE_BINARY_DIR}/lib/site-packages
    DEPENDS test_project_pywrap
    VERBOSE
)

xxx_python_compile_all(DIRECTORY 
    ${CMAKE_BINARY_DIR}/lib/site-packages/test_project
    VERBOSE
)

install(
    DIRECTORY ${CMAKE_BINARY_DIR}/lib/site-packages/test_project
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/site-packages
    FILES_MATCHING 
        PATTERN "*.py" 
        PATTERN "*.pyc" 
        PATTERN "*.typed" 
        PATTERN "*.so" 
        PATTERN "*.pyd"
)