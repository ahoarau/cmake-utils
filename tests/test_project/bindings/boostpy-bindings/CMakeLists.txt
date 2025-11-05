add_library(test_project_pywrap_bp MODULE bindings.cpp)
target_link_libraries(test_project_pywrap_bp 
    PRIVATE 
        test_project   
        Python::Module Python::NumPy
        Boost::python Boost::numpy
)

set(PYTHON_MODULE_NAME "test_project_pywrap_bp")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/__init__.py.in
    ${CMAKE_BINARY_DIR}/lib/site-packages/${PROJECT_NAME}_bp/__init__.py
    @ONLY
)

# default extension is .dll on windows, change to .pyd
if(WIN32)
    set_target_properties(test_project_pywrap_bp PROPERTIES
        PREFIX ""
        SUFFIX ".pyd"
    )
endif()


set_target_properties(test_project_pywrap_bp PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/site-packages/${PROJECT_NAME}_bp
)
xxx_target_set_default_compile_options(test_project_pywrap_bp PRIVATE)

