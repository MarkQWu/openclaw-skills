# gobuildit 社区 Skills 一键安装 (Windows)
$ErrorActionPreference = "Stop"

$repoGitHub = "https://github.com/MarkQWu/openclaw-skills.git"
$repoMirror = "https://ghfast.top/https://github.com/MarkQWu/openclaw-skills.git"
$cache = Join-Path $env:USERPROFILE ".claude\.skill-repos\openclaw-skills"

Write-Host "=== gobuildit Skills 安装器 ===" -ForegroundColor Cyan
Write-Host ""

# 检查 git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "错误：未找到 git，请先安装 git（https://git-scm.com）" -ForegroundColor Red
    throw "git not found"
}

# 尝试 clone，GitHub 失败则自动切镜像
function Try-Clone($dest) {
    Write-Host "正在下载..."
    & git clone $repoGitHub $dest 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { return $true }

    Write-Host "GitHub 连接失败，切换镜像源..." -ForegroundColor Yellow
    & git clone $repoMirror $dest 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        # 把 remote 改回 GitHub（镜像只用于首次下载）
        & git -C "$dest" remote set-url origin $repoGitHub
        return $true
    }

    Write-Host ""
    Write-Host "错误：下载失败。请开启全局代理后重试，或手动下载：" -ForegroundColor Red
    Write-Host "  https://github.com/MarkQWu/openclaw-skills/archive/refs/heads/main.zip" -ForegroundColor Red
    return $false
}

# 尝试 pull，GitHub 失败则通过镜像 fetch
function Try-Pull($dir) {
    Write-Host "检测到已安装，正在更新..."
    & git -C "$dir" pull --ff-only 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { return $true }

    Write-Host "GitHub 连接失败，切换镜像源..." -ForegroundColor Yellow
    & git -C "$dir" remote set-url origin $repoMirror
    & git -C "$dir" pull --ff-only 2>&1 | Out-Null
    $pullOk = $LASTEXITCODE -eq 0
    & git -C "$dir" remote set-url origin $repoGitHub
    if ($pullOk) { return $true }

    Write-Host "更新失败，正在重新安装..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "$dir"
    return (Try-Clone $dir)
}

# Clone 或更新仓库到缓存目录
$cacheParent = Split-Path $cache -Parent
if (-not (Test-Path $cacheParent)) { New-Item -ItemType Directory -Path $cacheParent -Force | Out-Null }

if (Test-Path (Join-Path $cache ".git")) {
    $ok = Try-Pull $cache
} else {
    if (Test-Path $cache) { Remove-Item -Recurse -Force "$cache" }
    $ok = Try-Clone $cache
}
if (-not $ok) { throw "安装失败" }

# 检测平台并收集目标目录
$targets = @()

# Claude Code
$claudeDir = Join-Path $env:USERPROFILE ".claude"
if (Test-Path $claudeDir) {
    $targets += Join-Path $claudeDir "skills"
}

# OpenClaw / WorkBuddy
foreach ($name in @(".openclaw", ".workbuddy")) {
    $dir = Join-Path $env:USERPROFILE $name
    if (Test-Path $dir) {
        $targets += Join-Path $dir "skills"
    }
}

# 都没检测到，默认装 Claude Code 目录
if ($targets.Count -eq 0) {
    $targets += Join-Path $env:USERPROFILE ".claude\skills"
}

# 安装 skill 到所有检测到的平台
$installed = 0
foreach ($skillsDir in $targets) {
    if (-not (Test-Path $skillsDir)) { New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null }
    Get-ChildItem "$cache" -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | ForEach-Object {
        $target = Join-Path $skillsDir $_.Name
        if (Test-Path $target) { Remove-Item -Recurse -Force "$target" }
        Copy-Item -Recurse -Force $_.FullName "$target"
        Write-Host "  已安装: $($_.Name)"
        $installed++
    }
}

# 显示版本
$version = git -C "$cache" log -1 --format="%h %s" 2>$null
if (-not $version) { $version = "unknown" }

Write-Host ""
if ($installed -gt 0) {
    Write-Host "安装成功！" -ForegroundColor Green
    foreach ($t in $targets) {
        Write-Host "  → $t"
    }
    Write-Host ""
    Write-Host "版本：$version" -ForegroundColor Gray
    Write-Host ""
    Write-Host "关闭当前 Claude Code / OpenClaw 会话，重新打开后输入 /开始 即可使用。"
} else {
    Write-Host "警告：未找到任何 Skill，请检查仓库内容。" -ForegroundColor Yellow
}
