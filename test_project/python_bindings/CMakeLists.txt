nanobind_add_module(pytest_bindings
    bindings.cpp
)
target_link_libraries(pytest_bindings PRIVATE math_lib string_lib)
xxx_target_set_default_compile_options(pytest_bindings PRIVATE)