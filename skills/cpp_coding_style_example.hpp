// - 文件名始终使用蛇形命名法，例如 `module_header.hpp`。
// - 假设存在某类 MyWidget，其声明/实现文件可命名为 `my_widget`。
// - 始终使用 4 空格进行缩进。
// - 指针和引用类型，`*` 和 `&` 符号始终左对齐，例如：`void* pt` `const auto& ref`。
// - 函数首单词尽量使用动词，对于类内的 getter 函数可省略 `get`。
// - 对于没有直接用注释文本指定的风格始终遵循所给示例代码的风格。
// - 此示例代码中包含 Qt 相关的编码风格，对于非 Qt 项目可忽略。

#pragma once // 使用 `pragma once` 进行头文件重包含保护。

// - 头文件大组之间以空行分隔。
// - 每大组与子组内头文件按字典序排序。

// C 标准头文件位于顶部
#include <stdint.h>
#include <cstddef>
// C++ 标准头文件
#include <string>

// 平台头文件
#include <windows.h>
#include <Carbon/Carbon.h>
#include <X11/Xlib.h>
#include <poll.h>

// 框架头文件
#include <qwidget.h> // Qt 头文件使用 `#include <qwidget.h>` 风格，而不是 `#include <QWidget>`。

// 第三方库头文件
#include <json.h>

// 项目内部头文件
#include <backend/api.hpp> // 非同级目录的头文件位于顶部
#include "same_directory_header.hpp"

// - 预处理指令分支语句进行缩进。
// - 预处理指令 `#endif` 后接注释用于标识所属分支的结束，对于 `#ifndef` 以及 `#if !defined(...) ...` 等指令对应的 `#endif` 需要根据其实际逻辑编写对应的注释。
#ifdef COMPILE_OPTION_1
    // Do something
#else
    #ifndef COMPILE_OPTION_2
        // Do something
    #endif // !COMPILE_OPTION_2

    #if !defined(COMPILE_OPTION_3) && !defined(COMPILE_OPTION_4)
        // Do something
    #endif // !COMPILE_OPTION_3 && !COMPILE_OPTION_4
#endif // COMPILE_OPTION_1

// 宏、字面量、常量始终使用以下风格命名：各字母大写，单词间使用下划线连接。
#define ENABLE_SOMETHING 1

constexpr double PI = 3.1415926;

// - 命名空间始终使用蛇形命名法。
// - 命名空间结束后始终接注释用于标识结束。
namespace my_namespace
{

// 宏参数名始终使用蛇形命名法。
#define CLAMP(v, min, max) (v < min ? min : (v > max ? max : v))

} // namespace my_namespace

// - 类名始终使用大驼峰命名法。
// - 访问权限说明符与 class 关键字缩进级别相同。
// - 成员变量以下划线结尾。
// - 成员变量始终进行显式初始化（不限定初始化方法，此处使用类内初始化，编码时可根据实际场景选择合适的初始化方法）。
class MyWidget : public QWidget
{
    Q_OBJECT // 继承于 QObject 的类始终包含 `Q_OBJECT` 宏，其应位于类声明顶部的私有访问权限域中，且以空行与其他内容隔开。

public:
    explicit MyWidget(QWidget* parent = nullptr);

    int data() const;
    void setData(int data);

private:
    QWidget* subWidget_ = nullptr;
    int      data_      = 0;
};
