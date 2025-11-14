function(check_python_module_name target)
  if(NOT TARGET Python::Interpreter)
    message(FATAL_ERROR "Python::Interpreter is not defined. Please use find_package(Python REQUIRED COMPONENTS Interpreter)")
  endif()

  get_target_property(target_type ${target} TYPE)

  if(NOT target_type STREQUAL "MODULE_LIBRARY")
    message(FATAL_ERROR "check_python_module_name() can only be called on a MODULE_LIBRARY target.")
  endif()

  set(python_module_check_script "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/check_python_module_name.py")
  if(NOT EXISTS ${python_module_check_script})
    message(FATAL_ERROR "Python module check script not found at ${python_module_check_script}.")
  endif()

  add_custom_command(
    TARGET ${target}
    POST_BUILD
    COMMAND $<TARGET_FILE:Python::Interpreter> ${python_module_check_script} $<TARGET_FILE:${target}> "${target}"
    COMMENT "Checking Python module name for ${target}"
    VERBATIM
  )

endfunction()
