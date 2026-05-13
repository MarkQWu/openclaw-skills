# gobuildit 社区 Skills 一键安装 (Windows)
$ErrorActionPreference = "Stop"

$repoGitHub = "https://github.com/MarkQWu/drama-workshop-skills.git"
$repoMirror = "https://ghfast.top/https://github.com/MarkQWu/drama-workshop-skills.git"
$cache = Join-Path $env:USERPROFILE ".gobuildit\skill-repos\drama-workshop-skills"
$scriptDir = if ($PSCommandPath) { Split-Path -Parent $PSCommandPath } else { "" }

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

function Get-LinkTarget($path) {
    $item = Get-Item $path -Force -ErrorAction SilentlyContinue
    if (-not $item -or -not $item.LinkType) { return "" }
    if ($item.Target -is [array]) { return ($item.Target | Select-Object -First 1) }
    return [string]$item.Target
}

function New-SkillLink($target, $source) {
    try {
        New-Item -ItemType Junction -Path $target -Target $source -ErrorAction Stop | Out-Null
        return
    } catch {
        try {
            New-Item -ItemType SymbolicLink -Path $target -Target $source -ErrorAction Stop | Out-Null
            return
        } catch {
            throw "无法完成安装。请以管理员身份运行终端，或开启 Windows 开发者模式后重试。"
        }
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "错误：未找到 git。请先安装 Git 后重新运行本安装命令。" -ForegroundColor Red
    Write-Host ""
    Write-Host "Windows 可让 AI agent 运行：" -ForegroundColor Yellow
    Write-Host "  winget install --id Git.Git -e --source winget" -ForegroundColor Yellow
    Write-Host "安装完成后重新打开终端，再运行安装命令。" -ForegroundColor Yellow
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
    Write-Host "错误：GitHub 下载失败。请打开全局代理后重新运行安装命令。" -ForegroundColor Red
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
    Move-Item -Path $dir -Destination "$dir.backup-$(Get-Timestamp)" -Force -ErrorAction SilentlyContinue
    if (Test-Path $dir) { return $false }
    return (Try-Clone $dir)
}

# Clone 或更新仓库到唯一 canonical 目录。
# 本地从完整 repo 运行时直接引用当前 checkout；irm | iex 时使用 ~/.gobuildit/skill-repos 下的唯一缓存 repo。
if ($scriptDir -and (Test-Path (Join-Path $scriptDir "short-drama\SKILL.md")) -and (Test-Path (Join-Path $scriptDir ".git"))) {
    $cache = $scriptDir
    Write-Host "使用本地仓库安装。" -ForegroundColor Gray
} else {
    $cacheParent = Split-Path $cache -Parent
    if (-not (Test-Path $cacheParent)) { New-Item -ItemType Directory -Path $cacheParent -Force | Out-Null }

    if (Test-Path (Join-Path $cache ".git")) {
        $ok = Try-Pull $cache
    } else {
        if (Test-Path $cache) {
            Move-Item -Path $cache -Destination "$cache.backup-$(Get-Timestamp)" -Force -ErrorAction SilentlyContinue
            if (Test-Path $cache) { throw "无法准备安装目录，请关闭正在占用它的程序后重试。" }
        }
        $ok = Try-Clone $cache
    }
    if (-not $ok) {
        Write-Host ""
        Write-Host "错误：下载失败。请确认已安装 Git，并打开全局代理后重新运行安装命令。" -ForegroundColor Red
        throw "安装失败"
    }
}

# 检测平台并收集目标目录
$targets = @()

# Claude Code
$claudeDir = Join-Path $env:USERPROFILE ".claude"
if (Test-Path $claudeDir) {
    $targets += Join-Path $claudeDir "skills"
}

# Codex / OpenClaw / WorkBuddy
foreach ($name in @(".codex", ".openclaw", ".workbuddy")) {
    $dir = Join-Path $env:USERPROFILE $name
    if (Test-Path $dir) {
        $targets += Join-Path $dir "skills"
    }
}

# 都没检测到，默认装 Claude Code 目录
if ($targets.Count -eq 0) {
    $targets += Join-Path $env:USERPROFILE ".claude\skills"
}

# 安装 skill 到所有检测到的平台：skills\<name> 只保留 junction，内容只存在于 $cache。
$installed = 0
foreach ($skillsDir in $targets) {
    if (-not (Test-Path $skillsDir)) { New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null }
    Move-EmbeddedTrash $skillsDir
    Get-ChildItem "$cache" -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | ForEach-Object {
        $target = Join-Path $skillsDir $_.Name
        $existingTarget = Get-LinkTarget $target
        if ($existingTarget -and ((Resolve-Path $existingTarget -ErrorAction SilentlyContinue).Path -eq $_.FullName)) {
            $installed++
            return
        }
        if ($existingTarget -and -not (Test-Path $existingTarget)) {
            $safeRoot = Join-Path (Split-Path $skillsDir -Parent) ".skill-trash"
            if (-not (Test-Path $safeRoot)) { New-Item -ItemType Directory -Path $safeRoot -Force | Out-Null }
            $backup = Join-Path $safeRoot ("broken-link-" + $_.Name + "-" + (Get-Timestamp))
            Move-Item -Path $target -Destination $backup -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $target) {
            $safeRoot = Join-Path (Split-Path $skillsDir -Parent) ".skill-trash"
            if (-not (Test-Path $safeRoot)) { New-Item -ItemType Directory -Path $safeRoot -Force | Out-Null }
            $backup = Join-Path $safeRoot ("reinstall-" + $_.Name + "-" + (Get-Timestamp))
            Move-Item -Path $target -Destination $backup -Force -ErrorAction SilentlyContinue
            if (Test-Path $target) {
                Write-Host "  警告：无法备份旧目录 $target，请关闭占用它的程序后重试。" -ForegroundColor Yellow
                return
            }
        }
        New-SkillLink $target $_.FullName
        Write-Host "  已安装: $($_.Name)"
        $installed++
    }
}

foreach ($packageDir in Get-ChildItem "$cache" -Directory -ErrorAction SilentlyContinue) {
    $binDir = Join-Path $packageDir.FullName "bin"
    if (Test-Path $binDir) {
        Get-ChildItem $binDir -File -ErrorAction SilentlyContinue | ForEach-Object {
            $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
        }
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
    Write-Host ""
    Write-Host "版本：$version" -ForegroundColor Gray
    Write-Host ""
    Write-Host "关闭当前 Claude Code / Codex / OpenClaw 会话，重新打开后输入 /开始 即可使用。"
    Write-Host "WorkBuddy 用户：需要从工作空间移除/关闭当前项目再重新打开，单独新建对话可能仍沿用旧 skill 缓存。"
    Write-Host "这不会删除 ~/short-drama-projects/ 下的剧本项目。"
} else {
    Write-Host "警告：未找到任何 Skill，请检查仓库内容。" -ForegroundColor Yellow
}
