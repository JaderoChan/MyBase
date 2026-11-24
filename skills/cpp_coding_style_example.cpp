#include "cpp_coding_style_example.hpp" // 与头文件强绑定的源文件，其头文件预处理指令始终位于顶部。

#include <stdlib.h>
#include <algorithm>

#include <qbutton.h>

// Other headers ...

namespace my_namespace
{

} // namespace my_namespace

MyWidget::MyWidget(QWidget* parent = nullptr)
    : QWidget(parent)
    , subWidget_(new QWidget())
    , data_(0)
{}
