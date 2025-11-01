#include <nanobind/nanobind.h>
#include <test_project/Math.hpp>
#include <test_project/StringUtils.hpp>

namespace nb = nanobind;

NB_MODULE(test_project_bindinds, m) {
    nb::class_<test_project::Math>(m, "Math")
        .def("add", &test_project::Math::add)
        .def("multiply", &test_project::Math::multiply);

    nb::class_<test_project::StringUtils>(m, "StringUtils")
        .def("to_upper", &test_project::StringUtils::to_upper)
        .def("reverse", &test_project::StringUtils::reverse);
}