#pragma once

#include <test_project/config.hpp>

namespace test_project {

class TEST_PROJECT_DLL StringUtils {
public:
    std::string to_upper(const std::string& str);
    std::string reverse(const std::string& str);
};

} // namespace test_project