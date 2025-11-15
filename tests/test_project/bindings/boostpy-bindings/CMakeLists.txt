boostpy_add_module(test_project_pywrap_bp bindings.cpp)
xxx_check_python_module_name(test_project_pywrap_bp)
target_link_libraries(test_project_pywrap_bp PRIVATE test_project)
xxx_target_set_default_compile_options(test_project_pywrap_bp PRIVATE)
xxx_target_set_output_directory(test_project_pywrap_bp ${CMAKE_BINARY_DIR}/lib/site-packages/test_project_bp)

xxx_python_generate_init_py(
    test_project_pywrap_bp
    OUTPUT_PATH ${CMAKE_BINARY_DIR}/lib/site-packages/test_project_bp/__init__.py
)

boostpy_add_stubs(
    test_project_pywrap_bp_stubs
    MODULE test_project_bp.test_project_pywrap_bp
    OUTPUT ${CMAKE_BINARY_DIR}/lib/site-packages
    PYTHON_PATH ${CMAKE_BINARY_DIR}/lib/site-packages
    DEPENDS test_project_pywrap_bp
    VERBOSE
)

xxx_python_compile_all(DIRECTORY
    ${CMAKE_BINARY_DIR}/lib/site-packages/test_project_bp
    VERBOSE
)

install(
    DIRECTORY ${CMAKE_BINARY_DIR}/lib/site-packages/test_project_bp
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/site-packages
    FILES_MATCHING
    PATTERN "*.py"
    PATTERN "*.pyc"
    PATTERN "*.typed"
    PATTERN "*.so"
    PATTERN "*.pyd"
)
