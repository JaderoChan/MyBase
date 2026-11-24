#include <qapplication.h>
#include <qfont.h>
#include <qsettings.h>
#include <qstringlist.h>

#include <easy_translate.hpp>

#include <app_defines.h>
#include "app_configuration.h"
#include "app_logo_icon.h"

int main(int argc, char* argv[])
{
    qRegisterMetaType<LanguageManager::Language>("Language");
    qRegisterMetaType<ColorSchemeManager::ColorScheme>("ColorScheme");

    // 设置程序全局属性。
    QApplication a(argc, argv);
    a.setOrganizationDomain(APP_ORGANIZATION_DOMAIN);
    a.setOrganizationName(APP_ORGANIZATION);
    a.setApplicationName(APP_TITLE);
    a.setApplicationVersion(APP_VERSION);
#ifndef Q_OS_MAC
    a.setWindowIcon(getAppLogoIcon());
#else
    // 启用长按键重复功能。
    QSettings(QSettings::NativeFormat, QSettings::UserScope, QStringLiteral(APP_PACKAGE_NAME))
        .setValue(QStringLiteral("ApplePressAndHoldEnabled"), false);
#endif // Q_OS_MAC

    // 设置字体
    {
        QFont       font;
        QStringList families;

    #ifdef Q_OS_WIN
        families << "Microsoft YaHei" << "SimHei";
    #elif defined(Q_OS_MACOS)
        families << "PingFang SC" << "Heiti SC";
    #else
        families << "Noto Sans CJK SC" << "WenQuanYi Micro Hei";
    #endif // Q_OS_WIN

        families << "Arial" << "sans-serif";

        font.setFamilies(families);
        a.setFont(font);
    }

    {
        // 加载程序设置。
        const auto& config = AppConfiguration::instance();
        // 设置语言与色彩主题。
        LanguageManager::instance().setLanguage(config.mainGroup.language);
        ColorSchemeManager::instance().setColorScheme(config.mainGroup.colorScheme);
    }

    // TODO

    int ret = a.exec();

#ifdef DUMP_TRANSLATION_ID
    easytr::dumpCollectedTranslationIds("./TranslationIds.json");
#endif // DUMP_TRANSLATION_ID

    return ret;
}
