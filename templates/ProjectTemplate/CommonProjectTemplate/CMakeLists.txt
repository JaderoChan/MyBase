cmake_minimum_required(VERSION 3.17)
#!!! TODO：@PROJECT_NAME@
project( VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 默认使用 Release 构建
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# 头文件（可用于在 Visual Studio IDE 的项目文件树中显示头文件）
file(
    GLOB_RECURSE HEADERS
    ${CMAKE_CURRENT_SOURCE_DIR}/*.h
    ${CMAKE_CURRENT_SOURCE_DIR}/*.hpp
)
# 源文件
file(
    GLOB_RECURSE SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/*.c
    ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp
)

set(PROJECT_SOURCES ${HEADERS} ${SRCS})

# 配置头文件路径
target_include_directories(
    ${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)
