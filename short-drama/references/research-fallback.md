# Research Fallback Guide

> `/考据 auto` 模式下，WebFetch 失败时的降级流程。修订 3 的细化文档。

## 触发条件

WebSearch 返回了高权重源（权重 ≥ 2），但 WebFetch 拿不到正文。常见原因：

1. **PDF 二进制返回**：医疗指南、学术论文常见
2. **SSL 证书错误**：政府/学术站时不时出现
3. **socket 断连 / 超时**：被防火墙挡 / 国际线路不稳
4. **HTTP 403 / 反爬**：部分商业站对自动化请求关闭

---

## 降级阶梯

### 阶梯 1：PDF 预处理

如果 URL 以 `.pdf` 结尾或 Content-Type 是 application/pdf：

```bash
# 优先 pdfplumber（保留表格）
python3 -c "import pdfplumber; pdf = pdfplumber.open('{path}'); print('\n'.join(p.extract_text() for p in pdf.pages))"

# 退到 pdftotext
pdftotext "{path}" -
```

未安装库时：跳到阶梯 2，不在本流程内安装依赖（避免污染环境）。

### 阶梯 2：重试 + 镜像源

| 主源 | 镜像 / 等价源 |
|------|--------------|
| ncbi.nlm.nih.gov | europepmc.org / pmc.ncbi.nlm.nih.gov |
| pubmed.ncbi.nlm.nih.gov | europepmc.org |
| uptodate.com（常付费）| medsci.cn / 丁香园专家专栏 |
| 中华医学会期刊 | medsci.cn / brainmed.com |
| ctext.org | shidianguji.com / gj.cangshu.cn |
| 政府站（*.gov.cn）| 同名政策的人民网/新华网转载 |

重试规则：**最多 2 次**，每次间隔 ≥ 5 秒。仍失败 → 阶梯 3。

### 阶梯 3：搜索结果摘要 fallback

WebSearch 返回的 snippet 通常含核心信息（标题 + 2-3 句摘要）。降级时：

1. 把搜索结果 snippet 写入 bible 对应字段
2. 字段标记：`[fetch-failed-snippet-only]`
3. 来源权重按通用百科（0）计算（虽然原源是高权重，但因为没拿到正文，无法核实）
4. 触发自动通知：「{字段名}：原源 {URL} fetch 失败，仅 snippet 写入。请人工访问验证。」

### 阶梯 4：标记 [待人工核源]

如果该字段是关键事实（官名/数字/术语定义）且只有 fetch-failed 一条来源：

1. bible 字段写入「[待人工核源]」占位
2. 不允许 /分集 引用此字段（强引用 → 自检 0 分）
3. 提示用户：「关键字段 {字段名} 缺权威来源，建议手动补充或 /考据 import 用户资料」

---

## fetch-failed 占比阈值

如果 `/考据 auto` 跑完后，bible 总字段数中 ≥ 30% 标 `[fetch-failed]` → 整个 bible 状态降级为 `auto-degraded`，提示用户：

> [警告] 本次 auto 检索失败率偏高（{N}/{M} = {P}%），bible 可信度受限。建议：
> 1. 手动 /考据 import 补充关键字段
> 2. 检查网络环境（部分权威源国际线路不稳）
> 3. 切换到 hybrid 模式

---

## 缓存策略

所有 fetch（成功 + 失败）都缓存到 `research-cache/`：

- 成功：`fetch-{url-slug}-{timestamp}.md`
- 失败：`fetch-{url-slug}-{timestamp}.failed`（含失败原因 + 重试次数）

下次同 URL 优先读缓存，失败缓存超过 7 天才重试。
