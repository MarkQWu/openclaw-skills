#!/usr/bin/env python3
"""character_consistency_check.py 的单元测试

运行: python3 scripts/test_character_consistency_check.py
"""

import sys
import tempfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from character_consistency_check import (
    extract_appearance_anchors,
    get_color_group,
    parse_characters,
    scan_episode,
    strip_bible_appendix,
    HAIR_COLOR_GROUPS,
    EYE_COLOR_GROUPS,
)

passed = 0
failed = 0
errors = []


def ok(name: str, condition: bool, detail: str = ""):
    global passed, failed
    if condition:
        print(f"  ✅ {name}")
        passed += 1
    else:
        print(f"  ❌ {name}{': ' + detail if detail else ''}")
        failed += 1
        errors.append(name)


# ── 辅助 ──────────────────────────────────────────────────────────────────────

def make_project(tmpdir: Path, chars_content: str, episodes: dict[str, str]) -> Path:
    """在临时目录创建 characters.md + episodes/epXXX.md"""
    (tmpdir / "characters.md").write_text(chars_content, encoding="utf-8")
    ep_dir = tmpdir / "episodes"
    ep_dir.mkdir(exist_ok=True)
    for name, content in episodes.items():
        (ep_dir / name).write_text(content, encoding="utf-8")
    return tmpdir


# ── get_color_group ───────────────────────────────────────────────────────────

print("\n[1] get_color_group")
ok("黑发 → 黑组", get_color_group("黑发", HAIR_COLOR_GROUPS) == "黑")
ok("乌黑头发 → 黑组", get_color_group("乌黑头发", HAIR_COLOR_GROUPS) == "黑")
ok("金发 → 金组", get_color_group("金发", HAIR_COLOR_GROUPS) == "金")
ok("银发 → 白/银组", get_color_group("银发", HAIR_COLOR_GROUPS) == "白/银")
ok("未知词 → None", get_color_group("橙发", HAIR_COLOR_GROUPS) is None)
ok("黑眸 → 黑组", get_color_group("黑眸", EYE_COLOR_GROUPS) == "黑")
ok("琥珀眸 → 棕/琥珀组", get_color_group("琥珀眸", EYE_COLOR_GROUPS) == "棕/琥珀")


# ── extract_appearance_anchors ────────────────────────────────────────────────

print("\n[2] extract_appearance_anchors")

a1 = extract_appearance_anchors("乌黑长发，黑眸深邃，身高175cm")
ok("发色提取", a1.get("hair_color") == "乌黑头发" or a1.get("hair_group") == "黑",
   str(a1))
ok("眼色提取", a1.get("eye_group") == "黑", str(a1))
ok("身高提取", a1.get("height_cm") == 175, str(a1))

a2 = extract_appearance_anchors("金色头发，蓝眸，180cm身高")
ok("金发提取", a2.get("hair_group") == "金", str(a2))
ok("蓝眸提取", a2.get("eye_group") == "蓝", str(a2))
ok("180cm提取", a2.get("height_cm") == 180, str(a2))

a3 = extract_appearance_anchors("温柔性格，没有特殊外貌")
ok("无外貌锚点时返回空", a3 == {}, str(a3))


# ── strip_bible_appendix ──────────────────────────────────────────────────────

print("\n[3] strip_bible_appendix")

content_with = "剧本内容\n<!-- 剧本正文到此结束 -->\n考据附录"
ok("有标记时截断", strip_bible_appendix(content_with) == "剧本内容\n")
ok("无标记时原样返回", strip_bible_appendix("纯剧本内容") == "纯剧本内容")


# ── parse_characters ──────────────────────────────────────────────────────────

print("\n[4] parse_characters")

with tempfile.TemporaryDirectory() as tmp:
    p = Path(tmp)

    # 标准格式
    (p / "characters.md").write_text("""
## 主角

**姓名**：林晓雨
**年龄**：25
**外貌特征**：乌黑长发，黑眸
**性格关键词**：坚韧、温柔
**角色弧线**：从软弱到觉醒

## 反派

**姓名**：赵天明
**年龄**：40
**外貌特征**：金发，蓝眸，185cm
**性格关键词**：强势
**角色弧线**：无
""", encoding="utf-8")

    chars = parse_characters(p)
    ok("解析到 2 个角色", len(chars) == 2, str(chars))
    names = [c["name"] for c in chars]
    ok("角色名正确", "林晓雨" in names and "赵天明" in names, str(names))
    c0 = next(c for c in chars if c["name"] == "林晓雨")
    ok("年龄解析", c0["age"] == 25, str(c0))
    ok("外貌解析", "乌黑" in c0["appearance"], str(c0))

    # 无 characters.md
    p2 = Path(tmp) / "empty_project"
    p2.mkdir()
    ok("无 characters.md 返回 []", parse_characters(p2) == [])


# ── scan_episode: 年龄矛盾 ────────────────────────────────────────────────────

print("\n[5] scan_episode — 年龄矛盾")

with tempfile.TemporaryDirectory() as tmp:
    p = Path(tmp)
    char = {"name": "林晓雨", "age": 25, "appearance": "", "personality": "", "arc": ""}

    # 精确匹配
    ep = p / "episodes"
    ep.mkdir()
    (ep / "ep001.md").write_text("林晓雨今年25岁，来到公司。", encoding="utf-8")
    issues = scan_episode(ep / "ep001.md", char)
    ok("年龄精确匹配无 issue", len(issues) == 0, str(issues))

    # ±1 容差
    (ep / "ep002.md").write_text("林晓雨刚满26岁生日。", encoding="utf-8")
    issues = scan_episode(ep / "ep002.md", char)
    ok("±1 岁容差不报错", len(issues) == 0, str(issues))

    # ±2 报错
    (ep / "ep003.md").write_text("林晓雨才28岁就升了总监。", encoding="utf-8")
    issues = scan_episode(ep / "ep003.md", char)
    ok("差 3 岁报 age_mismatch error", len(issues) == 1 and issues[0]["type"] == "age_mismatch", str(issues))
    ok("severity 是 error", issues and issues[0]["severity"] == "error")

    # 排除超出范围的数字（年代、集数）
    (ep / "ep004.md").write_text("林晓雨提到2024年的往事，在ep100播出。", encoding="utf-8")
    issues = scan_episode(ep / "ep004.md", char)
    ok("年代数字/集数不触发", len(issues) == 0, str(issues))

    # 角色不在集中
    (ep / "ep005.md").write_text("完全没有这个人出现。", encoding="utf-8")
    issues = scan_episode(ep / "ep005.md", char)
    ok("角色不出现时返回 []", issues == [])


# ── scan_episode: 外貌矛盾 ────────────────────────────────────────────────────

print("\n[6] scan_episode — 外貌矛盾")

with tempfile.TemporaryDirectory() as tmp:
    p = Path(tmp)
    ep = p / "episodes"
    ep.mkdir()
    char_hair = {
        "name": "林晓雨", "age": None,
        "appearance": "乌黑长发，黑眸，身高165cm",
        "personality": "", "arc": "",
    }

    # 同组发色：无 issue
    (ep / "ep001.md").write_text("林晓雨黑发飘逸，走进大厅。", encoding="utf-8")
    issues = scan_episode(ep / "ep001.md", char_hair)
    ok("同组发色无 issue", all(i["type"] != "appearance_conflict" or i.get("attr") != "发色" for i in issues), str(issues))

    # 跨组发色：warning
    (ep / "ep002.md").write_text("林晓雨一头金发在阳光下闪耀。", encoding="utf-8")
    issues = scan_episode(ep / "ep002.md", char_hair)
    hair_issues = [i for i in issues if i.get("attr") == "发色"]
    ok("跨组发色报 appearance_conflict warning", len(hair_issues) >= 1, str(hair_issues))
    ok("severity 是 warning", hair_issues and hair_issues[0]["severity"] == "warning")

    # 跨组眼色：warning
    (ep / "ep003.md").write_text("林晓雨的蓝眸中流露出担忧。", encoding="utf-8")
    issues = scan_episode(ep / "ep003.md", char_hair)
    eye_issues = [i for i in issues if i.get("attr") == "眼色"]
    ok("跨组眼色报 appearance_conflict warning", len(eye_issues) >= 1, str(eye_issues))

    # 身高 ±3 容差
    (ep / "ep004.md").write_text("林晓雨，168cm的身材匀称。", encoding="utf-8")
    issues = scan_episode(ep / "ep004.md", char_hair)
    height_issues = [i for i in issues if i.get("attr") == "身高"]
    ok("身高差 3cm 不报（容差内）", len(height_issues) == 0, str(height_issues))

    (ep / "ep005.md").write_text("林晓雨，身高175cm，比预想中高。", encoding="utf-8")
    issues = scan_episode(ep / "ep005.md", char_hair)
    height_issues = [i for i in issues if i.get("attr") == "身高"]
    ok("身高差 10cm 报 warning", len(height_issues) >= 1, str(height_issues))


# ── scan_episode: 去重 ────────────────────────────────────────────────────────

print("\n[7] scan_episode — 去重")

with tempfile.TemporaryDirectory() as tmp:
    p = Path(tmp)
    ep = p / "episodes"
    ep.mkdir()
    char_dup = {
        "name": "李雷", "age": 30,
        "appearance": "黑发",
        "personality": "", "arc": "",
    }
    # 同一集里名字出现多次，发色只报一条
    (ep / "ep001.md").write_text(
        "李雷金发帅气。李雷金发飘逸走进来。李雷金发在镜头前闪过。", encoding="utf-8"
    )
    issues = scan_episode(ep / "ep001.md", char_dup)
    hair_issues = [i for i in issues if i.get("attr") == "发色"]
    ok("同集同角色同 found 值只报 1 条", len(hair_issues) == 1, f"实际 {len(hair_issues)} 条")


# ── parse_ep_range ────────────────────────────────────────────────────────────

print("\n[8] parse_ep_range")

from character_consistency_check import parse_ep_range

ok("标准范围 1-20", parse_ep_range("1-20") == (1, 20))
ok("单集 5", parse_ep_range("5") == (5, 5))
ok("起止相同 3-3", parse_ep_range("3-3") == (3, 3))
ok("None 返回 None", parse_ep_range(None) is None)
ok("空字符串返回 None", parse_ep_range("") is None)
ok("非数字返回 None", parse_ep_range("1a") is None)
ok("多段返回 None", parse_ep_range("1-2-3") is None)
ok("反向范围正常解析（不交换）", parse_ep_range("20-1") == (20, 1))


# ── 端到端：乌黑完整链路 ──────────────────────────────────────────────────────

print("\n[9] 端到端：乌黑 characters.md → scan_episode 报冲突")

with tempfile.TemporaryDirectory() as tmp:
    p = Path(tmp)
    ep = p / "episodes"
    ep.mkdir()
    char_uwu = {
        "name": "林晓雨", "age": None,
        "appearance": "乌黑长发，黑眸",
        "personality": "", "arc": "",
    }
    anchors = extract_appearance_anchors(char_uwu["appearance"])
    ok("乌黑长发 → hair_group=黑", anchors.get("hair_group") == "黑", str(anchors))

    (ep / "ep001.md").write_text("林晓雨的金发在阳光下闪耀。", encoding="utf-8")
    issues = scan_episode(ep / "ep001.md", char_uwu)
    hair_issues = [i for i in issues if i.get("attr") == "发色"]
    ok("乌黑设定 vs 金发剧集 → 报 warning", len(hair_issues) >= 1, str(hair_issues))
    ok("conflict 信息含 expected 黑系", hair_issues and "黑" in hair_issues[0].get("expected", ""), str(hair_issues))


# ── strip_bible_appendix 边界：恰好在内容末尾 ─────────────────────────────────

print("\n[10] strip_bible_appendix 边界")

ok("标记在末尾无换行",
   strip_bible_appendix("内容<!-- 剧本正文到此结束 -->") == "内容")
ok("标记前有多行内容",
   strip_bible_appendix("A\nB\n<!-- 剧本正文到此结束 -->\nC") == "A\nB\n")
ok("多个标记取首个",
   strip_bible_appendix("A\n<!-- 剧本正文到此结束 -->\nB\n<!-- 剧本正文到此结束 -->\nC") == "A\n")
ok("标记在最开头返回空字符串",
   strip_bible_appendix("<!-- 剧本正文到此结束 -->\n内容") == "")


# ── 汇总 ──────────────────────────────────────────────────────────────────────

print(f"\n{'=' * 50}")
print(f"✅ 通过 {passed}  ❌ 失败 {failed}")
if errors:
    print("失败项：")
    for e in errors:
        print(f"  - {e}")
print("=" * 50)

sys.exit(0 if failed == 0 else 1)
