#pragma once

#include <test_project/export.hpp>
#include <string>


namespace test_project {

class TEST_PROJECT_EXPORT StringUtils {
public:
    std::string to_upper(const std::string& str);
    std::string reverse(const std::string& str);
};

} // namespace test_project