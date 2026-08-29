cmake_minimum_required(VERSION 3.17)

# TODO
project(@PROJECT_NAME@ VERSION 0.1.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 默认使用 Release 构建
if(NOT DEFINED CMAKE_BUILD_TYPE OR NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build with Release when not build type be specified." FORCE)
endif()

# TODO
# 头文件（可用于在 Visual Studio 等 IDE 的项目文件树中显示头文件）
set(HEADERS
)

# 源文件
set(SRCS
)

set(PROJECT_SOURCES ${HEADERS} ${SRCS})

# 配置头文件路径
target_include_directories(
    ${PROJECT_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
)
