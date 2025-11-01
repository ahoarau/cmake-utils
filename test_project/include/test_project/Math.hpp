#pragma once

#include <test_project/export.hpp>

namespace test_project {

class TEST_PROJECT_EXPORT Math {
public:
    int add(int a, int b);
    int multiply(int a, int b);
};

} // namespace test_project