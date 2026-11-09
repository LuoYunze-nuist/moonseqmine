# 选题与语义查重（2026-11-09）

按 moonbit-hackathon-builder 与 osc2026-guide 的 Project Research Guide 完成。搜索与下载原始证据保存在本地交付目录，不包含凭据。账号为 LuoYunze-nuist；未声称截止日期延长或官方验收通过。

## 候选比较

| 排序 | 不同领域与成熟参照 | 用户与复用性 | 核心模型、完成标准 | 结论 |
|---|---|---|---|---|
| 1 | 有序项集频繁模式；Apache Spark PrefixSpan、PrefixSpan-py | 行为分析、服务事件分析、符号序列研究 | 整数项集序列数据库；每序列一次支持度；I/S扩展；穷举与参考实现对照 | 选择；广度/需求/深度/可验证性/可维护性各4/5，重复风险经下述边界核查 |
| 2 | 右删失生存分析；lifelines/R survival | 临床研究、可靠性工程、用户留存 | Kaplan-Meier、Cox、删失时间数据 | 淘汰：Lyl66655/moon-survival@0.2.4 已有核心API/实现/测试；注册表还有 moon-reliability |
| 3 | 一阶项统一；miniKanren/Prolog | 逻辑查询、类型推断、规则推理 | 项、替换、occurs check、回溯 | 淘汰：bobzhang/prolog@0.1.6 实现统一且测试覆盖 occurs check；另有 unification_table/miniKanren/type_unification |

成熟生态依据：Spark 的 PrefixSpan 接收 sequence-of-itemsets 并按序列支持度输出模式；Python PrefixSpan-py 为标量序列参考。这里没有访谈用户或现有采用者的证据，三个场景是已有算法适用任务的工程演示。

## 实际检索范围

- `moon search QUERY --limit 100 --json`：PrefixSpan、BIDE、SPADE、cSPADE、GSP、sequence mining、sequential pattern、subsequence、pattern growth、projected database相关接口逆向查找，以及 Apriori/Eclat/FP-Growth/itemset/association；生存候选 survival/censored/Kaplan Meier；逻辑候选 unification/occurs check。每次结果/退出状态已保存。模糊命中与没有同名包均不作为唯一结论。
- MoonCakes 精确版本 manifest、文档页、实际发布ZIP的 README、.mbti、.mbt与测试：下表各项目。ZIP内的核心实现定位而非只读介绍。
- GitHub `language:MoonBit` 仓库与代码搜索：PrefixSpan、sequence mining、sequential pattern、frequent_sequences、fpgrowth、pattern mining；每页100，返回 incomplete_results=false。`prefix_span` 命中 MoonJust/parser proof/wite 的源代码位置，`apriori` 命中压缩字典与 Win32类型；名称与路径表明需区分模糊文本命中，未把这些当作已完整审计的算法库。代码索引不能覆盖未索引或私有仓库。
- 官方生态列表 `moonbitlang/awesome-moonbit` 实际README已读取。最初误用 moonbit-community 地址404，改为正确官方仓库；不把失败网页当作不存在。
- 永久 project-registry.md 按完整指纹/场景/模型核对；MoonConcept、MoonEarley、MoonCite、MoonPhone 等保留项目不复用。预留时持排他锁重新读取、原子追加。

## 近邻能力矩阵

| 项目及检查版本 | 实际核心能力/源码证据 | 与本项目边界 |
|---|---|---|
| xingsiyi/processlens@0.3.0 | EventLog.discover/discover_alpha/discover_prefix_net；sequence包按已给定pattern/阶段做CEP，reference_wbtest枚举已给模式的匹配 | 高相邻；不能代替跨数据库发现未知有序项集模式。独立离线算法无需继承日志时间戳、Petri-net或水位线语义 |
| Zh666-lab/moonconcept@0.1.3 | generators.mbt frequent_concepts；FCA Context/NextClosure、闭包/蕴含、支持度；示例确实称frequent_patterns | 高相邻；无序对象属性与有序项集数据库的数据契约不同。不以换名做无序频繁项集库 |
| starAndHonor/fst@0.1.1 | Builder、FstSet、dictionary index、automaton/subsequence检索及测试 | 只给定模式/字符串集合查找；非跨序列支持度与I/S增长 |
| IvanAXu/BioSeqs@0.1.14 | Seq、FreqAnalysis、k-mer统计等实际README/API；源码与测试扫描相关挖掘标识 | 生物序列领域相邻；已检查接口不提供选定挖掘流程 |
| zhaoyuanjuns/moonbit_extractor@0.1.2 | 实际提取/比较API及源码测试；核心算法术语扫描 | 抽取相邻，不是未知频繁项集序列发现 |
| CAIMEOX/symbit@0.5.10 / Juwan-Hwang/moon-certified@0.1.1 | 实际发布源码/API扫描；模糊检索命中需排除数学/证明术语 | 未发现所选流程；不声称审计其每一条算法 |
| Lyl66655/moon-survival@0.2.4 | src/kaplan_meier.mbt与对应测试、Cox API | 直接重复生存候选，否决 |
| bobzhang/prolog@0.1.6 | builtins统一调用、prolog_test.mbt的 cyclic terms occurs check 测试 | 直接重复逻辑统一候选，否决 |

## 选择后的功能边界与可验证交付

整数标签的规范化项集序列；序列级支持计数；I/S投影数据库增长；可检查的出现证据；资源预算超限报错；有界模式族内closed/maximal筛选；严格SPMF/JSON输入输出；三个可运行工作流。独立小规模穷举与Python标量序列参考差分。不提供分布式Spark运行时、实时CEP、流程网发现、任意生物对齐或因果推断。

结论：**在已记录检索范围内未发现成熟直接替代**。检索受索引、分页上限、版本、私有仓库及未命名实现限制；发布前复核，不作绝对不存在或官方查重认证。

参考与近邻：
- https://spark.apache.org/docs/latest/ml-frequent-pattern-mining.html#prefixspan
- https://github.com/chuanconggao/PrefixSpan-py （MIT；2016 Chuancong Gao）
- https://mooncakes.io/docs/xingsiyi/processlens
- https://mooncakes.io/docs/Zh666-lab/moonconcept
- https://mooncakes.io/docs/Lyl66655/moon-survival
- https://mooncakes.io/docs/bobzhang/prolog
- https://github.com/moonbitlang/awesome-moonbit
