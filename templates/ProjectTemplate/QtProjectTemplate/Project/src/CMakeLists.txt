#############
# 收集源文件 #
#############

# 配置 app_defines 头文件。
configure_file(
    "${CMAKE_TEMPLATES_DIR}/app_defines.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/include/app_defines.h"
    @ONLY
)

# TODO
# 头文件（可用于在 Visual Studio 等 IDE 的项目文件树中显示头文件）
set(
    HEADERS

    "${CMAKE_CURRENT_BINARY_DIR}/include/app_defines.h"

    ./app/app_configuration.h
    ./app/app_logo_icon.h

    ./components/adaptive_widget.h
    ./components/color_scheme_manager.h
    ./components/flow_grid_layout.h
    ./components/language_manager.h
    ./components/sidebar_widget.h

    ./utils/debug_output.h
    ./utils/directory_scope.h
    ./utils/file_io.h
    ./utils/format_string.h
)

# 源文件
set(
    SRCS

    ./app/app_configuration.cpp
    ./app/app_logo_icon.cpp
    ./app/main.cpp

    ./components/adaptive_widget.cpp
    ./components/color_scheme_manager.cpp
    ./components/flow_grid_layout.cpp
    ./components/language_manager.cpp
    ./components/sidebar_widget.cpp
)

# UI 文件
set(
    UIS
)

# QRC 文件
set(QRC "${RESOURCES_DIR}/app.qrc")

set(PROJECT_SOURCES ${HEADERS} ${SRCS} ${UIS} "${QRC}")

###########
# 构建程序 #
###########

if(QT_VERSION_MAJOR GREATER_EQUAL 6)
    qt_standard_project_setup()
    set(CMAKE_AUTORCC ON)
    qt_add_executable(${PROJECT_NAME} ${PROJECT_SOURCES})
else()
    set(CMAKE_AUTOMOC ON)
    set(CMAKE_AUTOUIC ON)
    set(CMAKE_AUTORCC ON)
    add_executable(${PROJECT_NAME} ${PROJECT_SOURCES})
endif()

###########
# 配置依赖 #
###########

# 配置头文件路径。
target_include_directories(
    ${PROJECT_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_BINARY_DIR}/include"
)

# 链接依赖库。
target_link_libraries(
    ${PROJECT_NAME} PRIVATE
    Qt${QT_VERSION_MAJOR}::Widgets
    easy_translate::easy_translate
)

###############
# 配置生成目标 #
###############

# 如果为 MSVC 编译器，显式指定编码，防止乱码情况。
if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /utf-8)
endif()

# 指定为 GUI 应用程序。
if(WIN32)
    option(KEEP_TERMINAL "Keep terminal window" OFF)
    set_target_properties(
        ${PROJECT_NAME} PROPERTIES
        WIN32_EXECUTABLE $<NOT:$<BOOL:${KEEP_TERMINAL}>>
    )
endif()

# 程序退出时是否提取翻译ID列表。
option(DUMP_TRANSLATION_ID "Dump all translation IDs to temp file." OFF)
target_compile_definitions(
    ${PROJECT_NAME} PRIVATE
    $<$<BOOL:${DUMP_TRANSLATION_ID}>:EASY_TRANSLATE_COLLECT_TRANSLATION_ID>
    $<$<BOOL:${DUMP_TRANSLATION_ID}>:DUMP_TRANSLATION_ID>
)

# 配置应用资源/属性。
if(WIN32)
    # Windows
    set(APP_ICON "${APP_ICON_DIR}/app.ico")

    set(APP_MANIFEST "${CMAKE_CURRENT_BINARY_DIR}/app.manifest")
    configure_file(
        "${CMAKE_TEMPLATES_DIR}/app.manifest.in"
        "${APP_MANIFEST}"
        @ONLY
    )

    # 是否将 app.manifest 文件加入到资源文件中。
    option(EMBED_APP_MANIFEST "Add the app.manifest file to the rc file." OFF)
    if(EMBED_APP_MANIFEST)
        # MSVC 默认会自动嵌入一个 manifest，禁用以避免与资源文件中的 RT_MANIFEST 冲突。
        target_link_options(${PROJECT_NAME} PRIVATE $<$<CXX_COMPILER_ID:MSVC>:/MANIFEST:NO>)
    endif()

    set(RC_FILE "${CMAKE_CURRENT_BINARY_DIR}/app.rc")
    configure_file(
        "${CMAKE_TEMPLATES_DIR}/app.rc.in"
        "${RC_FILE}"
        @ONLY
    )
    target_sources(${PROJECT_NAME} PRIVATE "${RC_FILE}")
elseif(APPLE)
    if(NOT CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        message(FATAL_ERROR "Unsupported platform.")
    endif()

    # macOS
    set(APP_ICON "${APP_ICON_DIR}/app.icns")

    # Info Plist Strings
    set(
        INFO_PLIST_STRINGS_NAMES
        en.lproj
        zh-Hans.lproj
    )
    foreach(INFO_PLIST_STRINGS_NAME IN LISTS INFO_PLIST_STRINGS_NAMES)
        configure_file(
            "${CMAKE_TEMPLATES_DIR}/InfoPlistStrings/${INFO_PLIST_STRINGS_NAME}/InfoPlist.strings.in"
            "${CMAKE_CURRENT_BINARY_DIR}/${INFO_PLIST_STRINGS_NAME}/InfoPlist.strings"
            @ONLY
        )
    endforeach()
    foreach(INFO_PLIST_STRINGS_NAME IN LISTS INFO_PLIST_STRINGS_NAMES)
        set(INFO_PLIST_STRINGS_FILE "${CMAKE_CURRENT_BINARY_DIR}/${INFO_PLIST_STRINGS_NAME}/InfoPlist.strings")
        set_source_files_properties(
            "${INFO_PLIST_STRINGS_FILE}" PROPERTIES
            MACOSX_PACKAGE_LOCATION "Resources/${INFO_PLIST_STRINGS_NAME}"
        )
        target_sources(${PROJECT_NAME} PRIVATE "${INFO_PLIST_STRINGS_FILE}")
    endforeach()

    # Info Plist
    set(MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_BINARY_DIR}/Info.plist")
    configure_file(
        "${CMAKE_TEMPLATES_DIR}/Info.plist.in"
        "${MACOSX_BUNDLE_INFO_PLIST}"
        @ONLY
    )

    # 应用图标
    set_source_files_properties(
        ${APP_ICON} PROPERTIES
        MACOSX_PACKAGE_LOCATION "Resources"
    )
    target_sources(${PROJECT_NAME} PRIVATE "${APP_ICON}")

    set_target_properties(
        ${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE ON
        MACOSX_BUNDLE_INFO_PLIST "${MACOSX_BUNDLE_INFO_PLIST}"
    )
elseif(LINUX)
    # Linux
    set(APP_ICON "${APP_ICON_DIR}/app.png")

    # 配置桌面入口文件。
    set(APP_DESKTOP_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop")
    configure_file(
        "${CMAKE_TEMPLATES_DIR}/app.desktop.in"
        "${APP_DESKTOP_FILE}"
        @ONLY
    )

    # 复制桌面入口文件至目标目录。
    add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${APP_DESKTOP_FILE}" "$<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.desktop"
    )

    # 复制图标至目标目录。
    configure_file("${APP_ICON}" "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.png" COPYONLY)
    add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.png" "$<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.png"
    )

    # 按 hicolor 图标主题规范复制各分辨率图标。
    file(GLOB APP_ICON_PNGS CONFIGURE_DEPENDS "${RESOURCES_DIR}/icons/app/*.png")
    foreach(APP_ICON_PNG IN LISTS APP_ICON_PNGS)
        get_filename_component(APP_ICON_PNG_NAME_WE "${APP_ICON_PNG}" NAME_WE)
        string(REGEX MATCH "([0-9]+)$" APP_ICON_SIZE "${APP_ICON_PNG_NAME_WE}")
        if(APP_ICON_SIZE)
            set(APP_ICON_THEME_DIR "$<TARGET_FILE_DIR:${PROJECT_NAME}>/icons/hicolor/${APP_ICON_SIZE}x${APP_ICON_SIZE}/apps")
            add_custom_command(
                TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory "${APP_ICON_THEME_DIR}"
                COMMAND ${CMAKE_COMMAND} -E copy_if_different "${APP_ICON_PNG}" "${APP_ICON_THEME_DIR}/${PROJECT_NAME}.png"
            )
        endif()
    endforeach()
elseif(ANDROID)
    # Android
    set(APP_ANDROID_MIN_SDK_VERSION    26 CACHE STRING "Android minimum SDK version.")
    set(APP_ANDROID_TARGET_SDK_VERSION 36 CACHE STRING "Android target SDK version.")

    math(EXPR APP_ANDROID_VERSION_CODE "${APP_VERSION_MAJOR} * 10000 + ${APP_VERSION_MINOR} * 100 + ${APP_VERSION_PATCH}")

    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/android")

    # 配置清单文件与应用名称字符串资源。
    configure_file(
        "${CMAKE_TEMPLATES_DIR}/android/AndroidManifest.xml.in"
        "${ANDROID_PACKAGE_SOURCE_DIR}/AndroidManifest.xml"
        @ONLY
    )
    configure_file(
        "${CMAKE_TEMPLATES_DIR}/android/strings.xml.in"
        "${ANDROID_PACKAGE_SOURCE_DIR}/res/values/strings.xml"
        @ONLY
    )

    # 复制图标至各密度 mipmap 目录。
    set(APP_ANDROID_ICON_RES_DIR "${APP_ICON_DIR}/android/res")
    if(NOT EXISTS "${APP_ANDROID_ICON_RES_DIR}")
        message(FATAL_ERROR "Android icons not found: \"${APP_ANDROID_ICON_RES_DIR}\".")
    endif()
    file(COPY "${APP_ANDROID_ICON_RES_DIR}/" DESTINATION "${ANDROID_PACKAGE_SOURCE_DIR}/res")

    set_target_properties(
        ${PROJECT_NAME} PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${ANDROID_PACKAGE_SOURCE_DIR}"
    )
else()
    message(FATAL_ERROR "Unsupported platform.")
endif()

#################
# 生成后额外命令 #
#################

# 复制运行时依赖文件至目标目录
if(WIN32)
    add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        $<TARGET_RUNTIME_DLLS:${PROJECT_NAME}>
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
        COMMAND_EXPAND_LISTS
    )
endif()

# Qt 部署（需要保证 *deployqt 可见）
option(DEPLOYQT_AFTER_BUILD "Execute *deployqt program to install Qt dependencies after build." ON)
if(DEPLOYQT_AFTER_BUILD)
    if(WIN32)
        add_custom_command(
            TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND windeployqt
            "$<TARGET_FILE:${PROJECT_NAME}>"
            $<$<CONFIG:Debug>:--debug>$<$<NOT:$<CONFIG:Debug>>:--release>
        )
    elseif(APPLE AND CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        add_custom_command(
            TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND macdeployqt
            "$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>"
            -codesign=-
        )
    elseif(LINUX)
        add_custom_command(
            TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND linuxdeployqt
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.desktop"
            -always-overwrite
        )
    elseif(ANDROID)
        # Android 的 Qt 依赖部署由 Qt 的 CMake Android 集成在构建流程中自动完成。
    else()
        message(FATAL_ERROR "Unsupported platform.")
    endif()
endif()

# macOS DMG 打包
option(CREATE_DMG "Create DMG for macOS, create-dmg is required." OFF)
if(APPLE AND CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND CREATE_DMG)
    add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND /bin/sh "${SCRIPTS_DIR}/create_dmg.sh"
        ${PROJECT_NAME}
        "${APP_ICON}"
        "$<PATH:GET_PARENT_PATH,$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>>"
    )
endif()

# Linux AppImage 打包
option(CREATE_APPIMAGE "Create AppImage for Linux, linuxdeployqt is required." OFF)
if(LINUX AND CREATE_APPIMAGE)
    add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND linuxdeployqt
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.desktop"
        -appimage
    )
endif()
