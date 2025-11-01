nanobind_add_module(pytest_bindings
    bindings.cpp
)
target_link_libraries(pytest_bindings PRIVATE test_project)
xxx_target_set_default_compile_options(pytest_bindings PRIVATE)