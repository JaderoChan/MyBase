#include "app_configuration.h"

#include <qsettings.h>

ConfigurationData loadConfiguration()
{
    ConfigurationData config;
    QSettings         qsettings;

    config.colorScheme = qsettings.value(QStringLiteral("ColorScheme"), ColorSchemeManager::COLOR_SCHEME_AUTO)
        .value<ColorSchemeManager::ColorScheme>();
    config.language    = qsettings.value(QStringLiteral("Language"),    LanguageManager::LANGUAGE_AUTO)
        .value<LanguageManager::Language>();

    return config;
}

void saveConfiguration(const ConfigurationData& config)
{
    QSettings qsettings;

    qsettings.setValue(QStringLiteral("ColorScheme"), config.colorScheme);
    qsettings.setValue(QStringLiteral("Language"),    config.language);
}

static ConfigurationData AppConfig;

const ConfigurationData& getAppConfiguration()
{
    return AppConfig;
}

ConfigurationData& getAppConfigurationRef()
{
    return AppConfig;
}

void setAppConfiguration(ConfigurationData config)
{
    AppConfig = std::move(config);
}
