# Qt 项目编写指南（未完成）

- Qt 的头文件使用 `qwidget.h` 这类 C 语言风格，而不是 `QWidget` 这类 C++ 风格。
- `Q_OBEJCT` 与权限限定符之间以空行间隔。
- 指针成员变量始终类内初始化为 `nullptr`。

## 命名风格

- C++ 头文件使用 `.hpp` 结尾而不是 `.h`。
- C++ 源文件使用 `.cpp` 结尾而不是 `.c`。
- 文件名使用蛇形命名法，例如 `this_a_file.cpp`。
- 命名空间使用蛇形命名法，例如 `my_namespace`。
- 类型名/类型别名/模板类型/类名/结构体名/联合体名使用大驼峰命名，例如 `MyClass`。
- 函数名使用小驼峰命名，例如 `myFunction`。
- 局部变量使用小驼峰命名，例如 `localVar`。
- 全局变量使用大驼峰命名（尽量不使用全局变量），例如 `GlobalVar`。
- 全局常量（`const`）/常量表达式（`constexpr`）/宏/枚举项使用全字母大写加下划线命名，例如 `TWO_PI`。
- 局部常量（`const`）与局部变量命名保持一致，例如 `localConstVar`。
- 成员变量使用小驼峰命名，并以下划线 `_` 结尾，例如 `memberVar_`。

## 缩进/空格风格

- 使用 4 空格代替 Tab 制表符进行缩进
- 函数/语句/长 lambda 体等左括号置于新行

    ```cpp
    void foo(int x)
    {
        if (x == 1)
        {
            // Do something...
        }
        else
        {
            // Do something...
        }

        for (int i = 0; i < x; ++i)
        {
            // ...
        }

        while (...)
        {
            // ...
        }

        do
        {

        } while(...);

        try
        {

        }
        catch (...)
        {

        }

        auto lamb1 = []()
        {
            // Long content
        };

        auto lamb2 = []() { /* Short content */ };
    }
    ```

- 多行参数使用 Rust 的对齐风格

    ```cpp
    void foo(
        int longLongLongName, int veryVeryVeryLongName,
        int soSoSoSoSoLongName, int otherName)
    {}
    ```

- 简短语句（一行内）不使用 `{}`

    ```cpp
    for (int i = 0; i < 100; ++i)
        printf("%d", i);

    if (ok)
        printf("........");
    else
        printf("........");

    if (x == 1)      return ...;
    else if (x == 2) return ...;
    else if (x == 3) return ...;
    else             return ...;

    if (error)
        return -1;
    ```

- switch 体进行缩进，case 体进行缩进

    ```cpp
    switch (flag)
    {
        case 1:  return 1;
        case 2:  return 2;
        case 3:
        {
            // Do something...
            return 3;
        }
        default: return 0;
    }
    ```

## 预处理指令

- 头文件使用 `#pragma once` 进行保护
- 预处理指令按照级别进行缩进

    ```hpp
    #if VERSION > 1.0.0
        #define  ...
        #include ...
    #endif
    ```

- 函数体内的预处理指令相对函数体少一个缩进

    ```cpp
    void func()
    {
        int a;
    #ifdef ...
        a = 1;
    #else
        a = 2;
    #endif
    }
    ```

## 注释

- 句子的首单词首字母大写
- 长句子使用句点结尾，简短描述/标签/组别等注释可以不添加句点

## 头文件排序风格

C > C++ > 系统头文件 > 框架头文件 > 第三方库头文件 > 项目内部头文件

同级头文件之间按照所属模块与字典序进行排序，所属模块之间的排序不做要求。也就是说先将不同模块间的头文件放一起，在对他们各自进行字典序排序。

除 C 和 C++ 头文件之间不留空行外，其他不同级别的头文件均使用空行隔开。

### 示例

```cpp
#include <stdio.h>
#include <stdlib.h>
#include <algorithm>
#include <string>

#include <wwindows.h>

#include <qapplication.h>
#include <qwidget.h>

#include <mod1_abc.h>
#include <mod1_abd.h>
#include <mod2_abc.h>
#include <mod2_abd.h>
#include <json.h>
#include <json_extra.h>

#include <my_app_setting.h>
#include "language.h"
```
