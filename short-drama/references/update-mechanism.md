# 版本更新机制（Update Mechanism）

## 版本更新检测（每次激活自动执行）

**本 skill 被激活时（用户输入任何命令前），必须先执行以下检测：**

Mac/Linux：
```bash
bash "$(dirname "$(find ~/.claude/skills ~/.openclaw/skills ~/.workbuddy/skills -name update-check -path "*/short-drama/*" 2>/dev/null | head -1)")/update-check" 2>/dev/null || true
```

Windows（PowerShell）：
```powershell
$s = Get-ChildItem "$HOME\.claude\skills","$HOME\.openclaw\skills","$HOME\.workbuddy\skills" -Recurse -Filter "VERSION" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "short-drama" } | Select-Object -First 1; if ($s) { $local = (Get-Content $s.FullName -TotalCount 1).Trim() -replace '^v',''; try { $remote = ((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MarkQWu/openclaw-skills/main/short-drama/VERSION" -TimeoutSec 5 -ErrorAction Stop).Content -split "`n")[0].Trim() -replace '^v',''; if ($remote -match '^\d+\.\d' -and $remote -ne $local) { "UPGRADE_AVAILABLE $local $remote" } } catch {} }
```

### 输出处理

根据输出决定行为：

- **无输出** → 已是最新，正常进入创作流程
- **`UPGRADE_AVAILABLE <旧版本> <新版本>`** → 用 `AskUserQuestion` 让用户选择（不要先回答用户命令再问，直接先问）：

  问题：「[锚点] 新版本 v{新版本} 可用（当前 v{旧版本}），是否更新？」

  选项：
  1. **立即更新** → 执行下方升级流程
  2. **开启自动更新** → 写入配置 `auto_upgrade: true`（以后静默升级），然后执行升级
  3. **暂不** → 写入递增退避 snooze（24h→48h→7d），继续响应用户原始命令
  4. **永远不提醒** → 写入 `update_check: false`，继续响应用户原始命令

- **`AUTO_UPGRADE <旧版本> <新版本>`** → 用户已开启自动更新，不询问，直接执行升级流程，完成后显示：
  > [完成] 已自动升级到 v{新版本}（从 v{旧版本}）。下次对话生效。

  然后继续响应用户原始命令。

- **`JUST_UPGRADED <旧版本> <新版本>`** → 显示升级成功信息并展示更新内容：
  > [完成] 已从 v{旧版本} 升级到 v{新版本}！
  
  然后读取 `WHATSNEW.md`，原文展示其内容（不要精简，让用户看到本次更新了什么）：
  > **本次更新内容：**
  > {WHATSNEW.md 全文}

- **`CHECK_FAILED 7d`** → 网络连续 7 天无法检查更新，显示淡提示：
  > [提示] 已超过 7 天未能检查更新（网络问题）。可手动运行 `/更新` 检查，或确认网络连通后自动恢复。

**重要**：版本检测只在每次对话的**首次命令**时执行一次，后续命令不再检测。网络失败时静默跳过，不影响正常使用。

---

## /更新 命令详细流程

**功能：** 检查最新版本并升级。

### 步骤 1：强制检查版本

```bash
SKILL_DIR="$(find ~/.claude/skills ~/.openclaw/skills ~/.workbuddy/skills -name update-check -path "*/short-drama/*" 2>/dev/null | head -1 | xargs dirname | xargs dirname)"
bash "$SKILL_DIR/bin/update-check" --force 2>/dev/null || true
```

### 步骤 2：根据输出决定行为

**无输出（已是最新）：**
> [完成] 当前已是最新版本 v{版本号}，无需更新。

**`UPGRADE_AVAILABLE <旧版本> <新版本>`：**

询问用户选择：
- **立即更新** → 执行步骤 3
- **开启自动更新**（以后不再问）→ 写入配置后执行步骤 3
- **暂不更新** → 写入暂缓文件（递增退避：24h → 48h → 7d）
- **永远不提醒** → 禁用更新检测

### 步骤 3：执行升级

```bash
# 定位安装目录
SKILL_DIR="$(find ~/.claude/skills ~/.openclaw/skills ~/.workbuddy/skills -name SKILL.md -path "*/short-drama/*" 2>/dev/null | head -1 | xargs dirname)"
STATE_DIR="$HOME/.openclaw"
mkdir -p "$STATE_DIR"

# 记录旧版本（升级后首次检测显示 JUST_UPGRADED）
OLD_VER="$(head -1 "$SKILL_DIR/VERSION" 2>/dev/null | sed 's/^v//' | awk '{print $1}')"
echo "$OLD_VER" > "$STATE_DIR/just-upgraded-from"

# 拉取最新代码
CACHE="$HOME/.claude/.skill-repos/openclaw-skills"
if [ -d "$CACHE/.git" ]; then
  git -C "$CACHE" pull --ff-only 2>/dev/null || {
    echo "GitHub 连接失败，尝试镜像源..."
    git -C "$CACHE" remote set-url origin "https://ghfast.top/https://github.com/MarkQWu/openclaw-skills.git"
    git -C "$CACHE" pull --ff-only
    git -C "$CACHE" remote set-url origin "https://github.com/MarkQWu/openclaw-skills.git"
  }
else
  mkdir -p "$(dirname "$CACHE")"
  git clone "https://github.com/MarkQWu/openclaw-skills.git" "$CACHE" 2>/dev/null || \
  git clone "https://ghfast.top/https://github.com/MarkQWu/openclaw-skills.git" "$CACHE"
fi

# 覆盖安装（保留用户的创作文件）
cp -r "$CACHE/short-drama/SKILL.md" "$SKILL_DIR/"
cp -r "$CACHE/short-drama/VERSION" "$SKILL_DIR/"
cp -r "$CACHE/short-drama/references/" "$SKILL_DIR/" 2>/dev/null || true
cp -r "$CACHE/short-drama/scripts/" "$SKILL_DIR/" 2>/dev/null || true
cp -r "$CACHE/short-drama/bin/" "$SKILL_DIR/" 2>/dev/null || true
chmod +x "$SKILL_DIR/bin/"* 2>/dev/null || true

# 清除缓存
rm -f "$STATE_DIR/last-update-check"
rm -f "$STATE_DIR/update-snoozed"

NEW_VER="$(head -1 "$SKILL_DIR/VERSION" 2>/dev/null | sed 's/^v//' | awk '{print $1}')"
echo "升级完成：v$OLD_VER → v$NEW_VER"
```

4. 读取 `WHATSNEW.md`，原文展示其内容（不要精简）：
   > **本次更新内容：**
   > {WHATSNEW.md 全文}

5. 提示用户：
> [完成] 升级完成！新版本在**下次对话**中生效（当前对话仍使用旧版 SKILL.md）。

---

## 辅助脚本

### 暂缓写入（用户选「暂不更新」时）

```bash
STATE_DIR="$HOME/.openclaw"
SNOOZE_FILE="$STATE_DIR/update-snoozed"
SKILL_DIR="$(find ~/.claude/skills ~/.openclaw/skills ~/.workbuddy/skills -name VERSION -path "*/short-drama/*" 2>/dev/null | head -1 | xargs dirname)"
mkdir -p "$STATE_DIR"

# 从缓存读取远程版本号
REMOTE_VER="$(awk '/^UPGRADE_AVAILABLE/{print $3}' "$STATE_DIR/last-update-check" 2>/dev/null)"

# 读取当前 snooze level，递增
CURRENT_LEVEL=0
if [ -f "$SNOOZE_FILE" ]; then
  CURRENT_LEVEL="$(awk '{print $2}' "$SNOOZE_FILE" 2>/dev/null || echo 0)"
fi
NEW_LEVEL=$((CURRENT_LEVEL + 1))

echo "$REMOTE_VER $NEW_LEVEL $(date +%s)" > "$SNOOZE_FILE"
```

### 自动更新配置写入

```bash
STATE_DIR="$HOME/.openclaw"; mkdir -p "$STATE_DIR"
echo "auto_upgrade: true" >> "$STATE_DIR/config.yaml"
```

### 禁用更新检测

```bash
STATE_DIR="$HOME/.openclaw"; mkdir -p "$STATE_DIR"
echo "update_check: false" > "$STATE_DIR/config.yaml"
```
