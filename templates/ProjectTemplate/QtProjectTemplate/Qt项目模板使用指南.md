# Qt项目模板使用指南

运行脚本文件 `newqtpro`

## 参数

- `-organ`：新项目的组织名。默认值为 `NoOrganization`。

- `-organ_domain`：新项目的组织域名。默认值为 `com.noorganization`。

- `-name <str>`: 新项目名称。默认值为 `NewQtProject`。

- `-ver <str>`：新项目默认版本号。默认值为 `0.1.0`。

  格式为 `MajorVersion.MinorVersion.PatchVersion`。

- `-appname <str>`：新项目的应用名。默认值为项目名称。

- `-appver <str>`：新项目的应用版本。默认值为项目版本。

- `-author <str>`：新项目作者名。默认值为 `Unknown`。

- `-email <str>`：新项目的电子邮箱联系方式。默认值为空。

- `-copyright <str>`：新项目的版权信息文本。默认值取决于项目作者名。

  如果项目作者名值为空，则此值为空。否则此值为 `Copyright (c) $Year $ProjectAuthor`，其中 `$Year` 将会被替换为创建项目时的年份，`$ProjectAuthor` 将会被替换为通过 `-author` 参数设置的项目作者名。

- `-cppver <num>`：新项目使用的C++标准。默认值为 `17`。

- `-appicon <filepath>`$^①$：新项目的的应用图标（`PNG` 格式，推荐大小为 `1024*1024`）。默认值为空。

### 引注

#### ①

- 如果给定文件不存在则回退至空值情况。

- 当值为空时，则仅初始化图标占位文件。

## 参数默认值配置文件

可以自定义参数的默认值，只需要在脚本的同级目录下创建 `default_config.yml` 配置文件，并按照与参数名相同的键名列出其默认值即可。

参见示例配置文件 [default_config_sample.yml](./default_config_sample.yml)
