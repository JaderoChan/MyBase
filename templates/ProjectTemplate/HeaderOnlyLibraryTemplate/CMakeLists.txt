cmake_minimum_required(VERSION 3.26)
project(@LIBNAME@ VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(MSG_PREFIX "[@LIB_MSG_PREFIX@]")

include(GNUInstallDirs)

# Check whether the project is the root project.
if(NOT @LIBNAME@_IS_MASTER_PROJECT)
    if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
        set(@LIBNAME@_IS_MASTER_PROJECT ON)
    else()
        set(@LIBNAME@_IS_MASTER_PROJECT OFF)
    endif()
endif()

###########
# Options #
###########

# TODO

########################
# Collect source files #
########################

# Configure config header.
set(CONFIG_HEADER_PATH ${CMAKE_CURRENT_BINARY_DIR}/include/@LIBNAME@/config.hpp)
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/templates/config.hpp.in
    ${CONFIG_HEADER_PATH}
    @ONLY
)

# Headers
file(GLOB_RECURSE HEADERS CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/include/@LIBNAME@/*.hpp)
list(APPEND HEADERS ${CONFIG_HEADER_PATH})

############################
# Make header-only library #
############################

add_library(${PROJECT_NAME} INTERFACE ${HEADERS})
add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

##########################
# Configure dependencies #
##########################

# Configure include directories.
target_include_directories(
    ${PROJECT_NAME}
    INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

# Configure dependencies related to platform.
# TODO

# Configure third-party dependencies.
# TODO

# Example. TODO: remove this in release version.
# find_package(Threads REQUIRED)
# target_link_libraries(
#     ${PROJECT_NAME}
#     INTERFACE
#     Threads::Threads
# )

###########
# Install #
###########

install(
    TARGETS ${PROJECT_NAME}
    EXPORT  ${PROJECT_NAME}
)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/@LIBNAME@ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(FILES ${CONFIG_HEADER_PATH} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/@LIBNAME@)
install(FILES LICENSE DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/licenses/${PROJECT_NAME})

install(
    EXPORT ${PROJECT_NAME}
    FILE ${PROJECT_NAME}Targets.cmake
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}Config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
    PATH_VARS CMAKE_INSTALL_INCLUDEDIR
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

install(
    FILES
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

#################
# Build Example #
#################

option(@LIBNAME@_BUILD_EXAMPLE "Build example" ${@LIBNAME@_IS_MASTER_PROJECT})
if(@LIBNAME@_BUILD_EXAMPLE)
    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/example)
endif()
