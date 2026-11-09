# 第三方来源与边界

MoonSeqMine 的生产实现以 MoonBit 独立编写，运行时仅依赖 MoonBit core；没有嵌入 Python、Spark、第三方本地挖掘引擎或复制其源码。项目使用 MIT 许可证。

- **PrefixSpan / Apache Spark MLlib**：参考 https://spark.apache.org/docs/latest/ml-frequent-pattern-mining.html#prefixspan 的 sequence-of-itemsets、序列级支持度语义及算法范围。Spark 为 Apache-2.0；本仓库没有复制 Spark 源文件、文档段落或其商标素材，也不提供 Spark 分布式运行时。
- **PrefixSpan-py 0.5.2**：https://github.com/chuanconggao/PrefixSpan-py ，MIT，Copyright (c) 2016 Chuancong Gao。仅在开发时生成单元素项集序列的差分预期结果；相关许可证完整保留于 `licenses/PrefixSpan-py-MIT.txt`。没有把该包或其依赖打包进生产模块。
- **SPMF 序列文本约定**：正整数项、`-1` 结束项集、`-2` 结束序列；本项目独立实现严格解析器。未复制 SPMF Java 实现（其许可证不作为本项目代码的许可）。本库只支持明示的序列数据库子格式，不声称覆盖整个 SPMF 格式族。
- **MoonBit core**：构建工具链提供的标准库，Apache-2.0；未将其源码复制到本仓库。

测试输入为脚本确定性合成数据，三个示例为合成演示，不包含真实用户日志、医疗或生物样本。`scripts/reference-requirements.txt` 仅锁定差分开发依赖；这些依赖不属于 MoonCakes 模块依赖。
