set(TARGET_SUFFIX _dbus_gencpp)

macro(add_dbuscxx_interfaces)
  cmake_parse_arguments(LOCAL "" "" "FILES;" ${ARGN})

  if("${XML2CPP_RUNTIME_DIRECTORY}" STREQUAL "")
    set(XML2CPP_RUNTIME_DIRECTORY ${CATKIN_DEVEL_PREFIX}/bin)
  endif()
  file(MAKE_DIRECTORY ${XML2CPP_RUNTIME_DIRECTORY})

  if("${CMAKE_INCLUDE_OUTPUT_DIRECTORY}" STREQUAL "")
    set(CMAKE_INCLUDE_OUTPUT_DIRECTORY ${CATKIN_DEVEL_PREFIX}/include/${PROJECT_NAME})
  endif()
  file(MAKE_DIRECTORY ${CMAKE_INCLUDE_OUTPUT_DIRECTORY})

  set(XML2CPP ${XML2CPP_RUNTIME_DIRECTORY}/dbuscxx-xml2cpp)
  set(DBUS_GENCPP_TARGET ${PROJECT_NAME}${TARGET_SUFFIX})
  add_custom_target(${DBUS_GENCPP_TARGET} ALL)
  foreach(src ${LOCAL_FILES})
    _generate_dbuscxx_interface(
      SRC ${src}
    )
  endforeach()

endmacro()

macro(_generate_dbuscxx_interface)
  cmake_parse_arguments(LOCAL "" "" "SRC;" ${ARGN})

  set(FULL_SRC_PATH ${PROJECT_SOURCE_DIR}/${LOCAL_SRC})

  if(NOT EXISTS ${FULL_SRC_PATH})
    message(SEND_ERROR "Failed to find '${LOCAL_SRC}' in project '${PROJECT_NAME}'")
  endif()

  get_filename_component(BASENAME ${LOCAL_SRC} NAME_WE)

  set(GENERATED_ADAPTER_NAME ${BASENAME}_adapter.h)
  set(GENERATED_ADAPTER_OUTPUT_FILE ${CMAKE_INCLUDE_OUTPUT_DIRECTORY}/${GENERATED_ADAPTER_NAME})
  set(GENERATED_PROXY_NAME ${BASENAME}_proxy.h)
  set(GENERATED_PROXY_OUTPUT_FILE ${CMAKE_INCLUDE_OUTPUT_DIRECTORY}/${GENERATED_PROXY_NAME})

  assert(CATKIN_ENV)
  add_custom_command(OUTPUT ${GENERATED_ADAPTER_OUTPUT_FILE}
    COMMENT "Generating C++ adapter code from ${PROJECT_NAME}/${LOCAL_SRC}"
    COMMAND ${XML2CPP} ${FULL_SRC_PATH} --adapter=${GENERATED_ADAPTER_OUTPUT_FILE}
    DEPENDS ${FULL_SRC_PATH} ${XML2CPP}
  )
  add_custom_target(${GENERATED_ADAPTER_NAME}${TARGET_SUFFIX}
    DEPENDS ${GENERATED_ADAPTER_OUTPUT_FILE}
  )
  add_custom_command(OUTPUT ${GENERATED_PROXY_OUTPUT_FILE}
    COMMENT "Generating C++ proxy code from ${PROJECT_NAME}/${LOCAL_SRC}"
    COMMAND ${XML2CPP} ${FULL_SRC_PATH} --proxy=${GENERATED_PROXY_OUTPUT_FILE}
    DEPENDS ${FULL_SRC_PATH} ${XML2CPP}
  )
  add_custom_target(${GENERATED_PROXY_NAME}${TARGET_SUFFIX}
    DEPENDS ${GENERATED_PROXY_OUTPUT_FILE}
  )
  add_dependencies(${DBUS_GENCPP_TARGET}
    ${GENERATED_PROXY_NAME}${TARGET_SUFFIX}
    ${GENERATED_ADAPTER_NAME}${TARGET_SUFFIX}
  )

  dbuscxx_append_include_dirs()
endmacro()

macro(dbuscxx_append_include_dirs)
  if(NOT APPENDED_INCLUDE_DIRS${TARGET_SUFFIX})
    # make sure we can find generated messages and that they overlay all other includes
    include_directories(BEFORE ${CATKIN_DEVEL_PREFIX}/include)
    # pass the include directory to catkin_package()
    list(APPEND ${PROJECT_NAME}_INCLUDE_DIRS ${CATKIN_DEVEL_PREFIX}/include)
    set(APPENDED_INCLUDE_DIRS${TARGET_SUFFIX} TRUE)
  endif()
endmacro()
