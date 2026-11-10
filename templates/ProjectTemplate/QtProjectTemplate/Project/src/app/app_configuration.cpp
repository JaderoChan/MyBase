#include "app_configuration.h"

#include <qsettings.h>
#include <qtimer.h>

#include <utils/debug_output.h>

AppConfiguration::AppConfiguration()
    : QObject(nullptr)
{
    timer_ = new QTimer(this);
    timer_->setSingleShot(true);
    connect(timer_, &QTimer::timeout, this, &AppConfiguration::save);
    reload();
}

AppConfiguration::~AppConfiguration()
{
    save();
}

AppConfiguration& AppConfiguration::instance()
{
    static AppConfiguration data;
    return data;
}

void AppConfiguration::reload()
{
    QSettings qsettings;

    colorScheme = qsettings
        .value(QStringLiteral("ColorScheme"), ColorSchemeManager::COLOR_SCHEME_AUTO)
        .value<ColorSchemeManager::ColorScheme>();
    language    = qsettings
        .value(QStringLiteral("Language"),    LanguageManager::LANGUAGE_AUTO)
        .value<LanguageManager::Language>();
}

void AppConfiguration::save() const
{
    QSettings qsettings;

    qsettings.setValue(QStringLiteral("ColorScheme"), colorScheme);
    qsettings.setValue(QStringLiteral("Language"),    language);
}

void AppConfiguration::saveLater(int delayMs) const
{
    timer_->start(delayMs);
}
