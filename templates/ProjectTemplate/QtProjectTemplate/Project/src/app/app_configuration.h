#pragma once

#include <components/color_scheme_manager.h>
#include <components/language_manager.h>

/** 程序的设置/配置结构体。 */
struct ConfigurationData
{
    ColorSchemeManager::ColorScheme colorScheme;
    LanguageManager::Language       language;
};

ConfigurationData loadConfiguration();

void saveConfiguration(const ConfigurationData& config);

const ConfigurationData& getAppConfiguration();

ConfigurationData& getAppConfigurationRef();

void setAppConfiguration(ConfigurationData config);
