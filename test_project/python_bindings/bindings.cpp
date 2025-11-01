#include <nanobind/nanobind.h>
#include <test_project/math.hpp>
#include <test_project/string.hpp>

namespace nb = nanobind;

NB_MODULE(pytest_bindings, m) {
    nb::class_<test_project::Math>(m, "Math")
        .def_static("add", &test_project::Math::add)
        .def_static("multiply", &test_project::Math::multiply);

    nb::class_<test_project::StringUtils>(m, "StringUtils")
        .def_static("to_upper", &test_project::StringUtils::to_upper)
        .def_static("reverse", &test_project::StringUtils::reverse);
}