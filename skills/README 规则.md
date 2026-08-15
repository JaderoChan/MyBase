# README 规则

- 对于具有多种语言版本的 README 文档，必须包含 **文档语言切换引用**（见下文），不同语言的 README 文档通过 `_`（下划线）符号在文件名后添加大写的语言代码进行区分，例如 `README_ZH`，`README_EN`，`README_RU`。

- 对于使用 AI 进行翻译的文档，需要在文档简介中使用如下方式进行标记：

    ```markdown
    # Document Title

    > This document was translated by AI.
    ```

    此标记必须紧随文档一级标题之后，唯一的例外是 **文档语言切换引用** 可以在其之前，例如：

    ```markdown
    # Document Title

    [**中文简体** | [English](...)]

    > This document was translated by AI.
    ```

- 对于 **文档语言切换引用**，需要保证：

    - 每种语言选项都使用其对应的语言进行表述（即无论当前文档语言如何，指向其他语言文档的超链接文本均使用其所指向文档的语言）
    - 不同语言文档中语言选项的文本与位置都保持相同
    - 当前文档的语言选项需要使用双星号加粗

    **样例**：

    ```markdown
    <!-- README_ZH -->
    [**中文简体** | [English](...) | [日本語](...) | ...]
    ```

    ```markdown
    <!-- README_EN -->
    [[中文简体](...) | **English** | [日本語](...) | ...]
    ```
