#pragma once

#include <test_project/config.hpp>

namespace test_project {

class TEST_PROJECT_API Math {
public:
    static int add(int a, int b);
    static int multiply(int a, int b);
};

} // namespace test_project