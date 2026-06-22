cmake_minimum_required(VERSION 3.26)
project(@LIBNAME@ VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(MSG_PREFIX "[@LIB_MSG_PREFIX@]")

include(GNUInstallDirs)

# Set the CMAKE_BUILD_TYPE default value to Release.
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Projects cannot be built in the same-level directory of the source code.
if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_CURRENT_BINARY_DIR)
    message(FATAL_ERROR "${MSG_PREFIX} In-source builds are not allowed. Please make a new directory (e.g. build) and run CMake from there.")
endif()

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

option(@LIBNAME@_BUILD_SHARED "Build shared library" OFF)
set(@LIBNAME@_SHARED ${@LIBNAME@_BUILD_SHARED})

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
file(GLOB HEADERS CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp)
list(APPEND HEADERS ${CONFIG_HEADER_PATH})

# Sources
file(GLOB SRCS CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
# TODO: Add other subdirectory sources.

if(WIN32)
    set(PLATFORM_NAME "win")
elseif(APPLE)
    if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        set(PLATFORM_NAME "macos")
    elseif(CMAKE_SYSTEM_NAME STREQUAL "iOS")
        set(PLATFORM_NAME "ios")
    else()
        message(FATAL_ERROR "${MSG_PREFIX} Unsupported platform.")
    endif()
elseif(LINUX)
    set(PLATFORM_NAME "linux")
elseif(ANDROID)
    set(PLATFORM_NAME "android")
else()
    message(FATAL_ERROR "${MSG_PREFIX} Unsupported platform.")
endif()

file(GLOB PLATFORM_SRCS CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/${PLATFORM_NAME}/*.cpp)

list(APPEND SRCS ${PLATFORM_SRCS})
set(${PROJECT_SOURCES} ${HEADERS} ${SRCS})

#########
# Build #
#########

if(@LIBNAME@_BUILD_SHARED)
    message(STATUS "${MSG_PREFIX} Shared library will be built.")
    add_library(${PROJECT_NAME} SHARED ${PROJECT_SOURCES})
    target_compile_definitions(${PROJECT_NAME} PRIVATE @LIBNAME@_BUILD_SHARED)
else()
    message(STATUS "${MSG_PREFIX} Static library will be built.")
    add_library(${PROJECT_NAME} STATIC ${PROJECT_SOURCES})
endif()

# Set library alias.
add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

####################
# Configure target #
####################

set_target_properties(${PROJECT_NAME} PROPERTIES DEBUG_POSTFIX d)
# If it is an MSVC compiler, explicitly specify the encoding to prevent garbled characters.
if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /utf-8)
endif()

##########################
# Configure dependencies #
##########################

# Configure include directories.
target_include_directories(
    ${PROJECT_NAME}
    PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    PRIVATE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
)

# Configure dependencies related to platform.
# TODO

# Configure third-party dependencies.
# TODO

###########
# Install #
###########

install(
    TARGETS ${PROJECT_NAME}
    EXPORT  ${PROJECT_NAME}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
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
    PATH_VARS CMAKE_INSTALL_INCLUDEDIR CMAKE_INSTALL_LIBDIR
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
