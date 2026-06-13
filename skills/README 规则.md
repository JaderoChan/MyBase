# README 规则

- 使用 AI 对文档进行翻译，需要在文档简介中使用如下方式进行标记：

    ```plaintext
    # Document Head

    > This document was translated by AI.
    ```

    此标记部分必须出现紧随文档一级标题之后，唯一的例外是文档语言切换部分可以在其之前，例如：

    ```plaintext
    # Document Head

    [**中文简体** | [English](...)]

    > This document was translated by AI.
    ```

- 对于文档多语言切换部分，需要保证：

    - 每种语言选项都使用其对应的语言进行表述
    - 不同语言的文档中语言选项的文本与位置都保持相同
    - 当前文档的语言选项需要使用双星号加粗
    - 基本样式

        ```plaintext
        [**中文简体** | [English](...) | [日本語](...) | ...]
        ```
