#pragma once

#include "test_project/config.hpp"
#include <string>

namespace test_project
{

  class TEST_PROJECT_DLLAPI StringUtils
  {
  public:
    std::string brackets(const std::string & str);
    std::string reverse(const std::string & str);
  };

} // namespace test_project