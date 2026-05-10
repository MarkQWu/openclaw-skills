# gobuildit 社区 Skills 一键安装 (Windows)
$ErrorActionPreference = "Stop"

$repoGitHub = if ($env:DRAMA_WORKSHOP_REPO_GIT) { $env:DRAMA_WORKSHOP_REPO_GIT } else { "https://github.com/MarkQWu/drama-workshop-skills.git" }
$repoMirror = if ($env:DRAMA_WORKSHOP_REPO_GIT_MIRROR) { $env:DRAMA_WORKSHOP_REPO_GIT_MIRROR } else { "https://ghfast.top/https://github.com/MarkQWu/drama-workshop-skills.git" }
$repoZip = if ($env:DRAMA_WORKSHOP_REPO_ZIP) { $env:DRAMA_WORKSHOP_REPO_ZIP } else { "https://github.com/MarkQWu/drama-workshop-skills/archive/refs/heads/main.zip" }
$repoZipCodeload = if ($env:DRAMA_WORKSHOP_REPO_ZIP_CODELOAD) { $env:DRAMA_WORKSHOP_REPO_ZIP_CODELOAD } else { "https://codeload.github.com/MarkQWu/drama-workshop-skills/zip/refs/heads/main" }
$repoZipMirror = if ($env:DRAMA_WORKSHOP_REPO_ZIP_MIRROR) { $env:DRAMA_WORKSHOP_REPO_ZIP_MIRROR } else { "https://ghfast.top/https://github.com/MarkQWu/drama-workshop-skills/archive/refs/heads/main.zip" }
$repoZipCodeloadMirror = if ($env:DRAMA_WORKSHOP_REPO_ZIP_CODELOAD_MIRROR) { $env:DRAMA_WORKSHOP_REPO_ZIP_CODELOAD_MIRROR } else { "https://ghfast.top/https://codeload.github.com/MarkQWu/drama-workshop-skills/zip/refs/heads/main" }
$cache = if ($env:DRAMA_WORKSHOP_CACHE) { $env:DRAMA_WORKSHOP_CACHE } else { Join-Path $env:USERPROFILE ".claude\.skill-repos\drama-workshop-skills" }

Write-Host "=== gobuildit Skills 安装器 ===" -ForegroundColor Cyan
Write-Host ""

function Get-Timestamp {
    return (Get-Date -Format "yyyyMMdd-HHmmss")
}

function Move-EmbeddedTrash($skillsDir) {
    $trashDir = Join-Path $skillsDir ".trash"
    if (-not (Test-Path $trashDir)) { return }

    # WorkBuddy may recursively scan every SKILL.md under skills\. Keep backups
    # outside the scanned skills tree so old skills cannot shadow current ones.
    $ownerDir = Split-Path $skillsDir -Parent
    $safeRoot = Join-Path $ownerDir ".skill-trash"
    if (-not (Test-Path $safeRoot)) { New-Item -ItemType Directory -Path $safeRoot -Force | Out-Null }

    $dest = Join-Path $safeRoot ("from-skills-trash-" + (Get-Timestamp))
    if (Test-Path $dest) {
        $dest = "$dest-$PID"
    }

    try {
        Move-Item -Path $trashDir -Destination $dest -Force
        Write-Host "  已迁移旧备份: $trashDir → $dest" -ForegroundColor Yellow
    } catch {
        Write-Host "  警告：无法迁移 $trashDir，请手动移出 skills 目录，避免旧 skill 被扫描。" -ForegroundColor Yellow
    }
}

function Try-DownloadZip($dest) {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("drama-workshop-skills-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $zip = Join-Path $tmp "main.zip"

    Write-Host "正在下载仓库 zip（不需要 git）..."
    foreach ($url in @($repoZip, $repoZipCodeload, $repoZipMirror, $repoZipCodeloadMirror)) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -TimeoutSec 90 -ErrorAction Stop
            Expand-Archive -Path $zip -DestinationPath $tmp -Force
            $extracted = Get-ChildItem $tmp -Directory | Where-Object { $_.Name -like "drama-workshop-skills-*" } | Select-Object -First 1
            if ($extracted) {
                if (Test-Path $dest) {
                    Move-Item -Path $dest -Destination "$dest.backup-$(Get-Timestamp)" -Force -ErrorAction SilentlyContinue
                    if (Test-Path $dest) { Remove-Item -Recurse -Force "$dest" }
                }
                Move-Item -Path $extracted.FullName -Destination $dest -Force
                Write-Host "仓库 zip 下载完成。"
                return $true
            }
        } catch {
            Write-Host "下载失败，尝试下一个源..." -ForegroundColor Yellow
        }
    }
    return $false
}

# 尝试 clone，GitHub 失败则自动切镜像
function Try-Clone($dest) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $false }
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
    Write-Host "git 下载失败，继续使用 zip 下载结果或最终错误提示。" -ForegroundColor Yellow
    return $false
}

# 尝试 pull，GitHub 失败则通过镜像 fetch
function Try-Pull($dir) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $false }
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
    if (Try-DownloadZip $dir) { return $true }
    Remove-Item -Recurse -Force "$dir"
    return (Try-Clone $dir)
}

# 下载或更新仓库到缓存目录。zip 优先，避免用户机器没有 git 或 git 被网络拦截。
$cacheParent = Split-Path $cache -Parent
if (-not (Test-Path $cacheParent)) { New-Item -ItemType Directory -Path $cacheParent -Force | Out-Null }

if (Try-DownloadZip $cache) {
    $ok = $true
} elseif (Test-Path (Join-Path $cache ".git")) {
    $ok = Try-Pull $cache
} else {
    if (Test-Path $cache) { Remove-Item -Recurse -Force "$cache" }
    $ok = Try-Clone $cache
}
if (-not $ok) {
    Write-Host ""
    Write-Host "错误：下载失败。可把以下链接复制给 WorkBuddy，让它直接下载 zip 后解压安装：" -ForegroundColor Red
    Write-Host "  $repoZipCodeloadMirror" -ForegroundColor Red
    Write-Host "  $repoZipMirror" -ForegroundColor Red
    Write-Host "  $repoZipCodeload" -ForegroundColor Red
    Write-Host "  $repoZip" -ForegroundColor Red
    Write-Host "也可以先安装 Git：https://git-scm.com/downloads，然后重新运行安装命令。" -ForegroundColor Yellow
    throw "安装失败"
}

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
    Move-EmbeddedTrash $skillsDir
    Get-ChildItem "$cache" -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | ForEach-Object {
        $target = Join-Path $skillsDir $_.Name
        if (Test-Path $target) {
            $safeRoot = Join-Path (Split-Path $skillsDir -Parent) ".skill-trash"
            if (-not (Test-Path $safeRoot)) { New-Item -ItemType Directory -Path $safeRoot -Force | Out-Null }
            $backup = Join-Path $safeRoot ("reinstall-" + $_.Name + "-" + (Get-Timestamp))
            Move-Item -Path $target -Destination $backup -Force -ErrorAction SilentlyContinue
            if (Test-Path $target) { Remove-Item -Recurse -Force "$target" }
        }
        Copy-Item -Recurse -Force $_.FullName "$target"
        Write-Host "  已安装: $($_.Name)"
        $installed++
    }
}

# 读取版本号（来自仓库 VERSION 文件，由发版流程维护）
$version = ""
$mainVersion = Join-Path $cache "short-drama\VERSION"
if (Test-Path $mainVersion) {
    $version = (Get-Content $mainVersion -TotalCount 1 -ErrorAction SilentlyContinue)
} else {
    Get-ChildItem "$cache" -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName "VERSION") } | Select-Object -First 1 | ForEach-Object {
        $version = (Get-Content (Join-Path $_.FullName "VERSION") -TotalCount 1 -ErrorAction SilentlyContinue)
    }
}
if ((-not $version) -and (Get-Command git -ErrorAction SilentlyContinue)) { $version = (& git -C "$cache" log -1 --format="%h" 2>$null) }
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
    Write-Host "WorkBuddy 用户：需要从工作空间移除/关闭当前项目再重新打开，单独新建对话可能仍沿用旧 skill 缓存。"
    Write-Host "这不会删除 ~/short-drama-projects/ 下的剧本项目。"
} else {
    Write-Host "警告：未找到任何 Skill，请检查仓库内容。" -ForegroundColor Yellow
}
