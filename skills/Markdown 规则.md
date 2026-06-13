# Markdown 规则

## 根本

Markdown 的编写风格需要符合此仓库规定的准则 [DavidAnson/markdownlint](https://github.com/DavidAnson/markdownlint)

## 样例

你需要根据以下样例的风格生成规范 Markdown 文档。

```plaintext
<!-- Markdown 文档必须包含一级标题 -->
# Head 1
<!-- 各级标题与正文之间必须使用一空行分隔 -->

正文文本...

<!-- 表格的单元格内容与列符号“|”必须使用空格分隔，对于表头和表体的分割线部分也同样适用 -->
| TH1 | TH2 | TH3 |
| --- | --- | --- |
| ... | ... | ... |

## Head 2

- Text...
- Text...
<!-- 对于子级内容或文本换行，必须其内容上下侧使用一空行分隔 -->

    - Sub text...
    - Sub text...

- Text...
```
