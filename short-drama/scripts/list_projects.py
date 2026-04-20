#!/usr/bin/env python3
"""
扫描短剧项目目录，输出进度表格。

用法:
    python3 scripts/list_projects.py
    python3 scripts/list_projects.py --dir ~/custom-projects
    python3 scripts/list_projects.py --format json
"""

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path


def scan_projects(root: Path) -> list[dict]:
    """扫描 root 下所有含 .drama-state.json 的子目录"""
    projects = []
    if not root.exists():
        return projects

    for child in sorted(root.iterdir()):
        if not child.is_dir():
            continue
        state_file = child / ".drama-state.json"
        if not state_file.exists():
            continue
        try:
            state = json.loads(state_file.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            print(f"⚠ 跳过 {child.name}: state 文件读取失败 ({exc})", file=sys.stderr)
            continue

        completed = state.get("completedEpisodes") or []
        total = state.get("totalEpisodes") or 0
        mtime = datetime.fromtimestamp(child.stat().st_mtime)

        projects.append({
            "path": str(child),
            "name": child.name,
            "dramaTitle": state.get("dramaTitle") or "-",
            "currentStep": state.get("currentStep") or "-",
            "mode": state.get("mode") or "domestic",
            "completed": len(completed) if isinstance(completed, list) else 0,
            "total": total,
            "modified": mtime.strftime("%Y-%m-%d %H:%M"),
        })

    return projects


def print_table(projects: list[dict]) -> None:
    if not projects:
        print("暂无项目，使用 `/开始` 创建第一个项目")
        return

    header = ["剧名", "阶段", "模式", "进度", "最近修改", "目录"]
    rows = [
        [
            p["dramaTitle"],
            p["currentStep"],
            p["mode"],
            f"{p['completed']}/{p['total']}" if p["total"] else f"{p['completed']}/-",
            p["modified"],
            p["name"],
        ]
        for p in projects
    ]

    widths = [max(len(str(row[i])) for row in [header] + rows) for i in range(len(header))]

    def fmt(row):
        return "  ".join(str(cell).ljust(widths[i]) for i, cell in enumerate(row))

    print(fmt(header))
    print("  ".join("-" * w for w in widths))
    for row in rows:
        print(fmt(row))
    print(f"\n共 {len(projects)} 个项目")


def main():
    parser = argparse.ArgumentParser(description="列出所有短剧项目")
    parser.add_argument(
        "--dir",
        type=str,
        default=None,
        help="项目根目录（默认 ~/short-drama-projects/）",
    )
    parser.add_argument(
        "--format",
        choices=["table", "json"],
        default="table",
        help="输出格式（默认 table）",
    )
    args = parser.parse_args()

    root = Path(args.dir).expanduser() if args.dir else Path.home() / "short-drama-projects"
    projects = scan_projects(root)

    if args.format == "json":
        print(json.dumps(projects, ensure_ascii=False, indent=2))
    else:
        print(f"扫描目录: {root}\n")
        print_table(projects)


if __name__ == "__main__":
    main()
