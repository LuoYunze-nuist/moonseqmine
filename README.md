# MoonSeqMine

MoonSeqMine 是用 MoonBit 实现的频繁序列挖掘基础库。输入是**多条有序项集序列**，输出是达到序列支持度阈值的模式及支持数。一个记录即使有多种嵌入也只计一次；同一项集中的标签表示同时出现，项集之间表示先后顺序。

行为分析系统可发现跨会话的常见路径，服务分析工具可发现请求内事件批次的重复次序，符号序列工具可发现跨记录重复的有序符号。项目提供可复用 API，不绑定某个网站、日志厂商或生物数据来源。示例均为合成数据。

## 安装与快速开始

需要 MoonBit `moonc >= 0.10.16`。本地交付验证使用 `moonc 0.10.18+6c83a7f62`、`moon 0.1.20261028`。库为纯 MoonBit，面向 wasm-gc、wasm、js、native；native 需要 C 编译器，JS 运行需要 Node.js。

在现有模块根目录安装精确版本：

```sh
moon add LuoYunze-nuist/moonseqmine@0.1.0
```

在调用包的 `moon.pkg` 中导入：

```text
import {
  "LuoYunze-nuist/moonseqmine" @seq,
}
```

可将下面的测试放进调用包（作为 `quickstart_wbtest.mbt`）：

```moonbit
test "ordered itemsets" {
  let db = @seq.database([[[1, 2], [3]], [[1], [3]], [[2], [3]], []])
  let found = @seq.mine(db, @seq.options(2, max_items=3))
  let p = @seq.pattern([[1], [3]])
  assert_eq(@seq.supporting_ids(db, p), [0, 1])
  assert_true(found.any(fn(record) { record.pattern == p && record.support == 2 }))
}
```

执行 `moon test --target wasm-gc --deny-warn`。空序列仍计入数据库大小；`[[1,2],[3]]` 与 `[[1],[2],[3]]` 不等价。

## 核心 API 与约束

- `database`、`pattern` 深拷贝输入并将各项集排序去重，拒绝负 ID、空项集和空模式。空数据库/空序列有效。公共结构可手工构造，因此接受它们的计算入口会重新验证规范性。
- `mine(db, options(count, ...), constraints=...)` 同时执行项集内 I-extension 与后继项集 S-extension。`mine_with_stats` 还返回投影扫描次数、累计生成状态数、输出模式数。
- `options` 默认 `max_items=8`、`max_patterns=10000`、`max_states=1000000`、`max_steps=10000000`。`max_items` 限定所声明的模式族，合法范围 1..64；其他三个预算一旦用尽就抛出 `Resource`，不会返回伪装成完整结果的截断数组。`min_support` 必须为正整数，超过数据库大小返回空结果。
- `constraints(max_gap=0)` 表示相邻匹配项集之间不能跳过项集；`max_span=2` 表示末位置减首位置最多为 2。均为零基项集位置，非时间秒数。I-extension 不增加位置差。未指定的约束不限制。
- `support` / `supporting_ids` 返回每记录一次的支持及零基序列 ID；`witnesses` 枚举完整嵌入；`verify_witness` 验证外部保存的证据。证据数量/工作超限报错，不静默截断。证据模式最多 64 个项集。
- `support_index` 对数据库建隔离快照及倒排候选表；`query_ids`、`query_support` 仍做精确顺序与位置约束匹配。原数组的后续修改不影响索引。
- `closed_patterns` / `maximal_patterns` **只相对于所传入的有界模式族**定义。传入不完整列表或 `max_items` 较小，不能据此宣称在无限模式空间中全局闭合/极大。重复模式支持冲突会报错。位置约束可能破坏任意子模式的支持单调性，筛选依旧仅比较传入模式及其实际支持。
- `compare_cohorts` 给出两组支持率、差值和可选比值；空群组支持率定义为 0，背景率为 0 时比值为 `None`。
- `sequential_rules` 只在完整项集边界拆分前缀/后缀，重新核对无约束支持，计算 confidence 和 lift。它不接受位置约束语义，不推断因果或显著性。
- `select_sequences` / `partition_database` 保留来源序列 ID，拒绝重复加权；`relative_min_support(N,a,b)` 用 Int64 精确计算 `ceil(N*a/b)`；空库返回 0，需要调用方先处理再传给 `options`。`summarize_database` 区分记录支持与事件出现次数。

完整公共接口见 [`src/pkg.generated.mbti`](src/pkg.generated.mbti)，实现约束见 [架构说明](docs/architecture.md)。所有错误统一为 `MiningError` 的 `Invalid`、`Parse` 或 `Resource`。

## 数据交换

`parse_database_json` / `format_database_json` 使用三层整数数组，模式 JSON 为两层数组；拒绝浮点、指数、负数、溢出、尾逗号和错误层级，避免 Double 转换损失。构造过程规范化各项集，不改变序列顺序。

`parse_spmf` / `format_spmf` 支持正整数项、`-1` 项集结束、`-2` 序列结束，以及以 `#`、`%`、`@` 开头的注释行。拒绝截断、0、未知负数及溢出。整数模型允许 ID 0，而 SPMF 子格式不允许；不隐式改写 ID，标签字典用户应选择 JSON 或显式采用正整数映射。

`encode_labeled_sequences` 按首次出现顺序分配从 0 开始的 ID，返回数据库和私有存储的 `LabelDictionary`；`intern_label`、`label_of`、`decode_labeled_sequences` 支持复用。字符串严格保留大小写和 Unicode，不自动归一化。应保存配套字典，不能混用不同字典解释同一 ID。

## 三个可运行场景

在仓库根目录执行：

```sh
moon run src/examples/journeys --target wasm-gc --deny-warn
moon run src/examples/services --target wasm-gc --deny-warn
moon run src/examples/symbols --target wasm-gc --deny-warn
```

1. **行为路径**：四条客户行为序列，经标签编码、挖掘及有界闭合筛选，输出 `browse -> cart : 3/4` 等带支持数的路径。
2. **服务事件**：SPMF 请求批次，经邻接约束挖掘、证据验证及群组比较，输出 6 个模式和 2 个完整嵌入；测试断言保留成功请求与重试请求的差异。
3. **符号序列**：三条合成符号记录，经挖掘、支持索引和描述性规则，输出 9 个频繁模式、6 条规则及 `A -> G -> T : 2`。这是离散序列挖掘，不是基因比对。

## 检查与测试

```sh
moon info
moon fmt --check
moon check --deny-warn --target wasm-gc
moon build --deny-warn --target wasm-gc
moon test --deny-warn --target wasm-gc
```

将目标改为 `wasm`、`js`、`native` 可重复其他后端检查、构建及测试。CI 对四个目标都执行这些步骤并运行三个示例；本机 Windows 未配置 C 编译器，native 实际运行证据由 Ubuntu CI 提供。

核心测试包括 864 次独立源序列位置/项子集穷举对照（非调用同一挖掘器作期望），以及 128 个 Python PrefixSpan 标量序列差分用例。仅生成的测试向量不计入生产行数。可重建参考向量：

```sh
python -m pip install -r scripts/reference-requirements.txt
python scripts/reference_vectors.py --check
moon test --deny-warn
```

发布验证和文件清单见 [验收说明](docs/competition/acceptance.md)；选题边界见 [有界查重报告](docs/competition/duplicate-check.md)。本地测试、CI 和发布验证分别记录，不把工程验收称为组委会通过。

## 已知限制

频繁模式数可能指数增长；这是有明确预算的内存型实现，不承诺 Spark 性能、分布式、GPU 或无限大数据库。工作计数度量投影扫描/匹配步骤，不是 CPU 指令或总耗时，输入校验、倒排候选交集、输出排序不计入该计数；上限不能代替进程级内存/时间隔离。公开数组是可变值，调用期间不得并发修改输入。所有闭合/极大判断限于输入模式族，规则限于无约束描述统计。

不提供实时 CEP、水位线、Petri-net 流程发现、无序 FCA 引擎、序列比对或统计显著性认证。

## 许可证与来源

采用 [MIT](LICENSE)。算法参考 Apache Spark PrefixSpan，标量差分参考 PrefixSpan-py 0.5.2；生产代码以 MoonBit 独立实现，不嵌入上游引擎，不声称完整移植。版权、许可和参考边界见 [THIRD_PARTY.md](THIRD_PARTY.md)，AI 辅助范围见 [AI_USAGE.md](AI_USAGE.md)。私人中文申报材料仅在本地仓库外保存。
