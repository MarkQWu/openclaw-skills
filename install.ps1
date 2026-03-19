# gobuildit 社区 Skills 一键安装 (Windows)
$ErrorActionPreference = "Stop"

$repo = "https://github.com/MarkQWu/openclaw-skills.git"
$target = Join-Path $env:USERPROFILE ".claude\skills\openclaw-skills"

Write-Host "=== gobuildit Skills 安装器 ===" -ForegroundColor Cyan
Write-Host ""

# 检查 git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "错误：未找到 git，请先安装 git" -ForegroundColor Red
    exit 1
}

# 安装或更新
if (Test-Path $target) {
    Write-Host "检测到已安装，正在更新..."
    git -C $target pull --ff-only
} else {
    Write-Host "正在安装到 $target ..."
    $parent = Split-Path $target -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    git clone $repo $target
}

Write-Host ""
Write-Host "安装成功！重启 Claude Code 后输入 /开始 即可使用短剧编剧 Skill" -ForegroundColor Green
Write-Host ""
Write-Host "已安装的 Skills："
Get-ChildItem $target -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | ForEach-Object {
    Write-Host "  - $($_.Name)"
}
