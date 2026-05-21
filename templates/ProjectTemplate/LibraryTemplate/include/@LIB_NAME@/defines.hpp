#ifndef @LIBNAME@_DEFINES_HPP
#define @LIBNAME@_DEFINES_HPP

#include <@LIBNAME@/config.hpp>

#ifdef _WIN32
    #define @LIBNAME@_WIN
#elif defined(__APPLE__)
    #define @LIBNAME@_APPLE
    #include <TargetConditionals.h>
    #if TARGET_OS_MAC && !TARGET_OS_IPHONE
        #define @LIBNAME@_MACOS
    #elif TARGET_OS_IPHONE
        #define @LIBNAME@_IOS
    #else
        #error "Unsupported platform"
    #endif // TARGET_OS_MAC && !TARGET_OS_IPHONE
#elif defined(__linux__)
    #define @LIBNAME@_LINUX
#elif defined(__ANDROID__)
    #define @LIBNAME@_ANDROID
#else
    #error "Unsupported platform"
#endif // _WIN32

#ifdef @LIBNAME@_WIN
    #ifdef @LIBNAME@_BUILD_SHARED
        #define @LIBNAME@_API __declspec(dllexport)
    #elif defined(@LIBNAME@_SHARED)
        #define @LIBNAME@_API __declspec(dllimport)
    #else
        #define @LIBNAME@_API
    #endif // @LIBNAME@_BUILD_SHARED
#else
    #define @LIBNAME@_API __attribute__((visibility("default")))
#endif // @LIBNAME@_WIN

#endif // !@LIBNAME@_DEFINES_HPP
