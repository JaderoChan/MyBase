#pragma once

#include <qstring.h>

enum Language : unsigned char
{
    LANG_EN     = 0,
    LANG_ZH,

    LANG_FIRST  = LANG_EN,
    LANG_LAST   = LANG_ZH
};

QString getLanguageStringId(Language lang);

// 如果应用程序不支持当前系统语言则返回 LANG_EN。
Language getCurrentSystemLang();

bool setLanguage(Language lang);
