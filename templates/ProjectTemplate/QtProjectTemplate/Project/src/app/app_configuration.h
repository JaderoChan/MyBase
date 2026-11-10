#pragma once

#include <components/color_scheme_manager.h>
#include <components/language_manager.h>

class QTimer;

/** 程序的设置/配置单例类。 */
class AppConfiguration : public QObject
{
    Q_OBJECT

public:
    static AppConfiguration& instance();

    void reload();
    void save() const;
    void saveLater(int delayMs) const;

    ColorSchemeManager::ColorScheme colorScheme;
    LanguageManager::Language       language;

private:
    AppConfiguration();
    ~AppConfiguration();

    QTimer* timer_;
};
