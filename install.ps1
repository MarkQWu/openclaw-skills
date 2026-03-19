# gobuildit 社区 Skills 一键安装 (Windows)
$ErrorActionPreference = "Stop"

$repo = "https://github.com/MarkQWu/openclaw-skills.git"
$cache = Join-Path $env:USERPROFILE ".claude\.skill-repos\openclaw-skills"
$skillsDir = Join-Path $env:USERPROFILE ".claude\skills"

Write-Host "=== gobuildit Skills 安装器 ===" -ForegroundColor Cyan
Write-Host ""

# 检查 git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "错误：未找到 git，请先安装 git（https://git-scm.com）" -ForegroundColor Red
    throw "git not found"
}

# Clone 或更新仓库到缓存目录
if (-not (Test-Path $skillsDir)) { New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null }

if (Test-Path $cache) {
    Write-Host "检测到已安装，正在更新..."
    try {
        git -C "$cache" pull --ff-only 2>$null
    } catch {
        Write-Host "更新失败（本地有改动），正在重新安装..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force "$cache"
        $cacheParent = Split-Path $cache -Parent
        if (-not (Test-Path $cacheParent)) { New-Item -ItemType Directory -Path $cacheParent -Force | Out-Null }
        git clone $repo "$cache"
    }
} else {
    Write-Host "正在下载..."
    $cacheParent = Split-Path $cache -Parent
    if (-not (Test-Path $cacheParent)) { New-Item -ItemType Directory -Path $cacheParent -Force | Out-Null }
    git clone $repo "$cache"
}

# 将每个 skill 目录复制到 ~/.claude/skills/ 下（扁平化，保证一层可被发现）
$installed = 0
Get-ChildItem "$cache" -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | ForEach-Object {
    $target = Join-Path $skillsDir $_.Name
    if (Test-Path $target) { Remove-Item -Recurse -Force "$target" }
    Copy-Item -Recurse -Force $_.FullName "$target"
    Write-Host "  已安装: $($_.Name)"
    $installed++
}

Write-Host ""
if ($installed -gt 0) {
    Write-Host "安装成功！共 $installed 个 Skill。" -ForegroundColor Green
    Write-Host "关闭当前 Claude Code / OpenClaw 会话，重新打开后输入 /开始 即可使用。"
} else {
    Write-Host "警告：未找到任何 Skill，请检查仓库内容。" -ForegroundColor Yellow
}
