#!/usr/bin/env python3
"""Split a short-drama source document into project-managed episode files.

Default granularity is episode-level. The script intentionally does not split
scenes; scene analysis belongs to the agent when a target episode is being read.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
import textwrap
import zipfile
from collections import Counter
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Iterable
from xml.etree import ElementTree as ET


EPISODE_HEADING_RE = re.compile(
    r"^\s*(?:#{1,6}\s*)?"
    r"(?:"
    r"第\s*([0-9〇零一二两三四五六七八九十百千万]+)\s*[集话回]"
    r"|EP(?:ISODE)?\.?\s*0*([0-9]+)"
    r"|E\s*0*([0-9]+)"
    r")"
    r"(?:\s*[：:\-— ]\s*(.*?))?\s*$",
    re.IGNORECASE,
)

SECTION_HEADING_RE = re.compile(
    r"^\s*(?:#{1,6}\s*)?(?:【)?"
    r"(剧情介绍|故事介绍|故事梗概|剧情梗概|梗概|简介|剧情发展脉络|剧情脉络|剧情走向|总大纲|故事大纲|剧情大纲|大纲|人物介绍|人物设定|人物小传|人物表|角色表|人物|角色|分集介绍|分集梗概|分集大纲|剧集大纲|集纲)"
    r"(?:】)?\s*(?:[:：]\s*)?$"
)
SECTION_START_RE = re.compile(
    r"^\s*(?:#{1,6}\s*)?(?:【)?"
    r"(剧情介绍|故事介绍|故事梗概|剧情梗概|梗概|简介|剧情发展脉络|剧情脉络|剧情走向|总大纲|故事大纲|剧情大纲|大纲|人物介绍|人物设定|人物小传|人物表|角色表|人物|角色|分集介绍|分集梗概|分集大纲|剧集大纲|集纲)"
    r"(?:】)?\s*(?:[:：]\s*(.*))?$"
)
EPISODE_SUMMARY_LINE_RE = re.compile(r"^\s*第\s*[0-9〇零一二两三四五六七八九十百千万]+\s*集")
SCENE_HEADING_RE = re.compile(r"^\s*([0-9]{1,3})\s*[-－]\s*([0-9]{1,3})(?:\s|$)")
PDF_NOISE_LINES = set("煮琴的短国编剧手记") | {"煮琴的短国编剧手记"}

SPEAKER_RE = re.compile(r"^\s*([^\s：:（）()【】\[\]#]{1,8})(?:（[^）]{0,20}）|\([^)]{0,20}\))?\s*[：:]")
TRAILING_WORKFLOW_HEADING_RE = re.compile(
    r"^\s*#{1,6}\s*"
    r"(?:"
    r"前\s*\d+\s*集节奏校验|节奏校验|"
    r"下一步可执行指令|下一步|推荐下一步|备选审查|审查建议|输出说明"
    r")\s*$"
)
PARTIAL_SOURCE_RE = re.compile(r"(前\s*[0-9一二两三四五六七八九十百千万]+\s*集|试读|样章|片段|部分)")
EXPECTED_COUNT_RE = re.compile(
    r"(?:^|[^0-9])(?:0*1|一)\s*[-_－—到至]\s*([0-9一二两三四五六七八九十百千万]+)\s*集"
)

CN_NUM = {
    "零": 0,
    "〇": 0,
    "一": 1,
    "二": 2,
    "两": 2,
    "三": 3,
    "四": 4,
    "五": 5,
    "六": 6,
    "七": 7,
    "八": 8,
    "九": 9,
}
CN_UNIT = {"十": 10, "百": 100, "千": 1000, "万": 10000}


@dataclass
class Episode:
    number: int
    title: str
    heading: str
    body: str


def chinese_to_int(value: str) -> int:
    if value.isdigit():
        return int(value)

    total = 0
    section = 0
    number = 0
    for char in value:
        if char in CN_NUM:
            number = CN_NUM[char]
        elif char in CN_UNIT:
            unit = CN_UNIT[char]
            if unit == 10000:
                section = (section + number) * unit
                total += section
                section = 0
            else:
                section += (number or 1) * unit
            number = 0
        else:
            raise ValueError(f"unsupported Chinese number: {value}")
    return total + section + number


def slug_episode(number: int) -> str:
    return f"ep_{number:03d}"


def clean_text(text: str) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n").replace("\f", "\n")
    cleaned_lines = []
    for line in text.splitlines():
        if line.strip() in PDF_NOISE_LINES:
            continue
        cleaned_lines.append(line)
    text = "\n".join(cleaned_lines)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"


def read_docx(path: Path) -> str:
    with zipfile.ZipFile(path) as docx:
        xml = docx.read("word/document.xml")
    root = ET.fromstring(xml)
    ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
    paragraphs: list[str] = []
    for paragraph in root.findall(".//w:p", ns):
        parts = [node.text or "" for node in paragraph.findall(".//w:t", ns)]
        line = "".join(parts).strip()
        if line:
            paragraphs.append(line)
    return "\n".join(paragraphs)


def read_pdf(path: Path) -> str:
    pdftotext = shutil.which("pdftotext")
    if pdftotext:
        with tempfile.TemporaryDirectory() as tmp:
            out_path = Path(tmp) / "source.txt"
            subprocess.run([pdftotext, str(path), str(out_path)], check=True)
            return out_path.read_text(encoding="utf-8", errors="replace")

    for module_name in ("pypdf", "PyPDF2"):
        try:
            module = __import__(module_name)
        except ImportError:
            continue
        reader_cls = getattr(module, "PdfReader")
        reader = reader_cls(str(path))
        return "\n".join(page.extract_text() or "" for page in reader.pages)

    raise RuntimeError("PDF extraction requires pdftotext, pypdf, or PyPDF2.")


def read_source(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix in {".md", ".markdown", ".txt"}:
        return path.read_text(encoding="utf-8", errors="replace")
    if suffix == ".docx":
        return read_docx(path)
    if suffix == ".pdf":
        return read_pdf(path)
    raise RuntimeError(f"Unsupported source format: {suffix or '[no suffix]'}")


def match_episode_heading(line: str) -> tuple[int, str] | None:
    if len(line.strip()) > 80:
        return None
    match = EPISODE_HEADING_RE.match(line)
    if not match:
        return None

    raw_number = next(group for group in match.groups()[:3] if group)
    try:
        number = chinese_to_int(raw_number)
    except ValueError:
        return None
    title = (match.group(4) or "").strip()
    return number, title


def split_episodes(text: str) -> list[Episode]:
    lines = text.splitlines()
    headings = select_episode_heading_run(collect_episode_headings(lines), lines)

    episodes: list[Episode] = []
    for idx, (line_index, number, title, heading) in enumerate(headings):
        start_index = adjusted_episode_start(lines, line_index, number)
        next_index = adjusted_episode_start(lines, headings[idx + 1][0], headings[idx + 1][1]) if idx + 1 < len(headings) else len(lines)
        default_start = line_index + 1
        if start_index == line_index:
            start_index = default_start
        body = normalize_episode_body(number, trim_trailing_workflow("\n".join(lines[start_index:next_index]))).strip()
        episodes.append(Episode(number=number, title=title, heading=heading, body=body))

    return episodes


def collect_episode_headings(lines: list[str]) -> list[tuple[int, int, str, str]]:
    headings: list[tuple[int, int, str, str]] = []
    for index, line in enumerate(lines):
        matched = match_episode_heading(line)
        if matched:
            number, title = matched
            headings.append((index, number, title, line.strip()))
    return headings


def select_episode_heading_run(
    headings: list[tuple[int, int, str, str]], lines: list[str]
) -> list[tuple[int, int, str, str]]:
    if len(headings) <= 1:
        return headings

    runs = group_episode_heading_runs(headings)
    if len(runs) == 1:
        return headings

    return max(runs, key=lambda run: (formal_heading_score(run, lines), len({item[1] for item in run}), run[0][0]))


def group_episode_heading_runs(
    headings: list[tuple[int, int, str, str]]
) -> list[list[tuple[int, int, str, str]]]:
    runs: list[list[tuple[int, int, str, str]]] = []
    current: list[tuple[int, int, str, str]] = []
    previous_number = 0
    for heading in headings:
        number = heading[1]
        if current and number <= previous_number:
            runs.append(current)
            current = []
        current.append(heading)
        previous_number = number
    if current:
        runs.append(current)
    return runs


def formal_heading_score(run: list[tuple[int, int, str, str]], lines: list[str]) -> int:
    score = 0
    for line_index, number, _, _ in run:
        start = max(0, line_index - 8)
        end = min(len(lines), line_index + 30)
        window = lines[start:end]
        scene_seen = any(
            (scene := SCENE_HEADING_RE.match(line)) and int(scene.group(1)) == number for line in window
        )
        cast_seen = any(re.search(r"人物\s*[：:]", line) for line in window)
        action_seen = any("△" in line for line in window)
        if scene_seen:
            score += 3
        if cast_seen:
            score += 2
        if action_seen:
            score += 1
    return score


def heading_diagnostics(text: str) -> dict[str, Any]:
    lines = text.splitlines()
    headings = collect_episode_headings(lines)
    runs = group_episode_heading_runs(headings)
    selected = select_episode_heading_run(headings, lines)
    selected_start = selected[0][0] if selected else None
    selected_index = next((idx for idx, run in enumerate(runs) if run and run[0][0] == selected_start), None)
    run_summaries = []
    for idx, run in enumerate(runs):
        numbers = [item[1] for item in run]
        run_summaries.append(
            {
                "index": idx,
                "first_line": run[0][0] + 1 if run else None,
                "first_episode": numbers[0] if numbers else None,
                "last_episode": numbers[-1] if numbers else None,
                "episode_count": len(numbers),
                "unique_episode_count": len(set(numbers)),
                "formal_score": formal_heading_score(run, lines),
            }
        )
    return {
        "heading_count": len(headings),
        "run_count": len(runs),
        "duplicate_heading_runs": run_summaries if len(runs) > 1 else [],
        "selected_heading_run": selected_index,
        "selected_heading_run_reason": "formal_script_markers" if len(runs) > 1 else "single_heading_run",
    }


def adjusted_episode_start(lines: list[str], line_index: int, episode_number: int) -> int:
    for index in range(line_index - 1, max(-1, line_index - 20), -1):
        match = SCENE_HEADING_RE.match(lines[index])
        if match and int(match.group(1)) == episode_number and int(match.group(2)) == 1:
            return index
    return line_index


def normalize_episode_body(episode_number: int, text: str) -> str:
    normalized_lines = []
    for line in text.splitlines():
        matched = match_episode_heading(line)
        if matched and matched[0] == episode_number:
            continue
        normalized_lines.append(line)
    return "\n".join(normalized_lines)


def trim_trailing_workflow(text: str) -> str:
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if TRAILING_WORKFLOW_HEADING_RE.match(line):
            return "\n".join(lines[:index])
    return text


def split_named_sections(text: str) -> dict[str, str]:
    key_map = {
        "剧情介绍": "synopsis",
        "故事介绍": "synopsis",
        "故事梗概": "synopsis",
        "剧情梗概": "synopsis",
        "梗概": "synopsis",
        "简介": "synopsis",
        "剧情发展脉络": "story_outline",
        "剧情脉络": "story_outline",
        "剧情走向": "story_outline",
        "总大纲": "story_outline",
        "故事大纲": "story_outline",
        "剧情大纲": "story_outline",
        "大纲": "story_outline",
        "人物介绍": "characters",
        "人物设定": "characters",
        "人物小传": "characters",
        "人物表": "characters",
        "角色表": "characters",
        "人物": "characters",
        "角色": "characters",
        "分集介绍": "episode_outline",
        "分集梗概": "episode_outline",
        "分集大纲": "episode_outline",
        "剧集大纲": "episode_outline",
        "集纲": "episode_outline",
    }
    lines = text.splitlines()
    selected_headings = select_episode_heading_run(collect_episode_headings(lines), lines)
    first_episode_index = selected_headings[0][0] if selected_headings else len(lines)
    preface_lines = lines[:first_episode_index]

    section_marks: list[tuple[int, str, str]] = []
    for index, line in enumerate(preface_lines):
        match = SECTION_START_RE.match(line)
        if match:
            section_marks.append((index, key_map[match.group(1)], (match.group(2) or "").strip()))

    sections: dict[str, str] = {}
    for idx, (line_index, key, inline_body) in enumerate(section_marks):
        next_index = section_marks[idx + 1][0] if idx + 1 < len(section_marks) else len(preface_lines)
        body_lines = preface_lines[line_index + 1 : next_index]
        if key == "characters":
            summary_index = next(
                (offset for offset, line in enumerate(body_lines) if EPISODE_SUMMARY_LINE_RE.match(line)),
                len(body_lines),
            )
            body_lines = body_lines[:summary_index]
        if key == "episode_outline":
            ending_index = next((offset for offset, line in enumerate(body_lines) if "全剧终" in line), None)
            if ending_index is not None:
                body_lines = body_lines[: ending_index + 1]
        parts = [inline_body] if inline_body else []
        parts.extend(body_lines)
        body = "\n".join(parts).strip()
        if body and key not in sections:
            sections[key] = body

    summary_start = next(
        (idx for idx, line in enumerate(preface_lines) if EPISODE_SUMMARY_LINE_RE.match(line)),
        None,
    )
    if summary_start is not None and "episode_outline" not in sections:
        sections["episode_outline"] = "\n".join(preface_lines[summary_start:]).strip()
    return sections


def excerpt(text: str, limit: int = 500, tail: bool = False) -> str:
    compact = re.sub(r"\s+", " ", text).strip()
    if len(compact) <= limit:
        return compact
    return compact[-limit:] if tail else compact[:limit]


def normalize_character_name(name: str) -> str:
    name = re.sub(r"[（(].*?[）)]", "", name)
    name = re.sub(r"\s+", "", name)
    return name.strip(" 、，,；;：:")


def cast_names(text: str) -> list[str]:
    names: Counter[str] = Counter()
    for line in text.splitlines():
        for match in re.finditer(r"人物\s*[：:]\s*([^\n△]+)", line):
            raw_names = re.split(r"[、,，/／]+", match.group(1))
            for raw_name in raw_names:
                name = normalize_character_name(raw_name)
                if 2 <= len(name) <= 8 and name not in {"众人", "路人", "仆人", "士兵", "百姓"}:
                    names[name] += 1
    return [name for name, _ in names.most_common()]


def speaker_counts(text: str, allowed_names: set[str] | None = None) -> list[dict[str, int]]:
    counts: Counter[str] = Counter()
    ignored = {"内", "外", "旁白", "字幕", "画面", "人物", "SFX", "OS", "VO", "V.O.", "△"}
    label_tokens = {
        "功能",
        "冲突",
        "受压",
        "动作",
        "反应",
        "爽点",
        "憋屈",
        "钩子",
        "骨架",
        "起承转合",
        "主要道具",
        "出场人物",
    }
    inline_dialogue_re = re.compile(r"([^\s：:（）()【】\[\]#，,。；;、]{1,8})(?:（[^）]{0,20}）|\([^)]{0,20}\))?\s*[：:]")
    for match in inline_dialogue_re.finditer(text):
        name = normalize_character_name(match.group(1))
        if name in ignored or len(name) < 2:
            continue
        if any(token in name for token in label_tokens):
            continue
        if allowed_names and name not in allowed_names:
            continue
        counts[name] += 1
    return [{"name": name, "count": count} for name, count in counts.most_common(12)]


def make_episode_text(episode: Episode) -> str:
    title = f"：{episode.title}" if episode.title else ""
    return clean_text(f"# 第{episode.number:03d}集{title}\n\n{episode.body}")


def make_episode_map(episodes: list[Episode]) -> str:
    rows = [
        "# 剧集地图",
        "",
        "| 集数 | 标题 | 字数 | 开场摘录 | 结尾摘录 | 摘要/功能 | 钩子/反转 |",
        "|---:|---|---:|---|---|---|---|",
    ]
    for episode in episodes:
        body = episode.body
        rows.append(
            "| {number} | {title} | {chars} | {opening} | {ending} | [待确认：需 agent 阅读后填写] | [待确认：需 agent 阅读后填写] |".format(
                number=episode.number,
                title=episode.title or "[待确认]",
                chars=len(body),
                opening=excerpt(body, 120).replace("|", "｜"),
                ending=excerpt(body, 120, tail=True).replace("|", "｜"),
            )
        )
    return "\n".join(rows) + "\n"


def make_bundle_text(episodes: Iterable[Episode]) -> str:
    parts = []
    for episode in episodes:
        parts.append(make_episode_text(episode))
    return "\n\n---\n\n".join(part.strip() for part in parts) + "\n"


def write_if_text(path: Path, content: str, fallback_title: str) -> None:
    if content.strip():
        path.write_text(clean_text(content), encoding="utf-8")
    else:
        path.write_text(f"# {fallback_title}\n\n[待确认：源文件未识别出该模块]\n", encoding="utf-8")


def parse_expected_episode_count(name: str) -> int | None:
    match = EXPECTED_COUNT_RE.search(name)
    if not match:
        return None
    try:
        return chinese_to_int(match.group(1))
    except ValueError:
        return None


def has_partial_marker(name: str) -> bool:
    return bool(PARTIAL_SOURCE_RE.search(name))


def section_present(sections: dict[str, str], key: str) -> bool:
    return bool(sections.get(key, "").strip())


def infer_source_scope(source_path: Path, episodes: list[Episode], sections: dict[str, str]) -> dict[str, Any]:
    numbers = sorted({episode.number for episode in episodes})
    expected_count = parse_expected_episode_count(source_path.name)
    first_episode = numbers[0] if numbers else None
    last_episode = numbers[-1] if numbers else None
    missing = []
    if numbers:
        missing = [number for number in range(first_episode or 1, (last_episode or 0) + 1) if number not in numbers]

    reasons: list[str] = []
    completeness = "unknown"
    partial_marker = has_partial_marker(source_path.name)
    has_core_package = all(section_present(sections, key) for key in ("synopsis", "story_outline", "characters", "episode_outline"))

    if partial_marker:
        completeness = "partial"
        reasons.append("filename indicates a partial/front-episode source")
    if expected_count is not None:
        if len(numbers) < expected_count:
            completeness = "incomplete"
            reasons.append(f"filename indicates {expected_count} episodes but only {len(numbers)} were detected")
        elif len(numbers) == expected_count and first_episode == 1 and not missing and completeness != "partial":
            completeness = "complete"
            reasons.append("filename episode range matches detected contiguous episodes")
    if numbers and first_episode != 1:
        completeness = "incomplete"
        reasons.append(f"detected episodes start at {first_episode}, not 1")
    if missing:
        completeness = "incomplete"
        reasons.append("detected episode sequence has gaps")
    if expected_count is None and len(numbers) <= 10 and not has_core_package and completeness == "unknown":
        completeness = "partial"
        reasons.append("10 or fewer episodes without a synopsis/story-outline/characters/episode-outline package")
    if expected_count is None and len(numbers) > 10 and completeness == "unknown":
        reasons.append("no explicit total episode count found; treat full-series claims as unverified")
    if not numbers:
        completeness = "unknown"
        reasons.append("no episode headings detected")

    source_scope = f"episodes_{first_episode:03d}-{last_episode:03d}" if numbers else "unknown"
    if completeness == "partial":
        source_scope = f"partial_{source_scope}"
    elif completeness == "incomplete":
        source_scope = f"incomplete_{source_scope}"

    return {
        "completeness": completeness,
        "source_scope": source_scope,
        "expected_episode_count": expected_count,
        "provided_episode_count": len(numbers),
        "first_episode": first_episode,
        "last_episode": last_episode,
        "missing_episodes": missing,
        "has_core_package": has_core_package,
        "reasons": reasons,
        "limits": scope_limits(completeness, len(numbers)),
    }


def scope_limits(completeness: str, episode_count: int) -> list[str]:
    if completeness == "complete":
        return [
            "Full-series skeleton analysis is allowed after reading the source package and rolling through later bundles.",
            "Still verify major skeleton claims against episode files or episode-outline.md.",
        ]
    if completeness == "partial":
        return [
            f"Only {episode_count} provided episodes may be analyzed as a sample/opening segment.",
            "Do not claim full-series structure, mid/late reversals, ending payoffs, or complete commercial model.",
            "Mark all downstream full-series assumptions as [待确认].",
        ]
    if completeness == "incomplete":
        return [
            "Detected source is incomplete or has gaps; do not claim full-series structure.",
            "Read the missing/gap information before final skeleton extraction.",
            "Mark any inference beyond provided episodes as [待确认].",
        ]
    return [
        "Completeness is unknown; do not claim full-series structure without explicit confirmation.",
        "Use the detected episodes as evidence and mark unverified full-series claims as [待确认].",
    ]


def gates_for_scope(completeness: str) -> dict[str, bool]:
    allow_full = completeness == "complete"
    return {
        "allow_sample_skeleton": completeness in {"complete", "partial", "incomplete", "unknown"},
        "allow_full_skeleton": allow_full,
        "allow_full_series_claims": allow_full,
        "allow_full_series_concepts": allow_full,
        "require_scope_disclaimer": not allow_full,
    }


def section_detection(sections: dict[str, str]) -> dict[str, str]:
    return {
        "synopsis": "found" if section_present(sections, "synopsis") else "missing",
        "story_outline": "found" if section_present(sections, "story_outline") else "missing",
        "characters": "found" if section_present(sections, "characters") else "missing",
        "episode_outline": "found" if section_present(sections, "episode_outline") else "missing",
    }


def extraction_info(source_path: Path, scope: dict[str, Any]) -> dict[str, str]:
    suffix = source_path.suffix.lower().lstrip(".") or "unknown"
    if suffix == "docx":
        method = "docx_xml"
        confidence = "high"
    elif suffix == "pdf":
        method = "pdftotext" if shutil.which("pdftotext") else "python_pdf_library"
        confidence = "medium"
    elif suffix in {"md", "markdown", "txt"}:
        method = "plain_text"
        confidence = "high"
    else:
        method = "unknown"
        confidence = "low"
    if scope["completeness"] in {"incomplete", "unknown"}:
        confidence = "low" if suffix == "pdf" else "medium"
    return {"format": suffix, "method": method, "confidence": confidence}


def validation_info(
    scope: dict[str, Any], grouped: dict[int, list[Episode]], diagnostics: dict[str, Any], sections: dict[str, str]
) -> dict[str, Any]:
    warnings = list(scope["reasons"])
    if diagnostics["duplicate_heading_runs"]:
        warnings.append("multiple episode heading runs detected; selected the run with formal script markers")
    for key, status in section_detection(sections).items():
        if status == "missing":
            warnings.append(f"{key} section not detected; inspect 00_source/extracted/source.md before assuming absence")
    expected_count = scope["expected_episode_count"]
    return {
        "episode_count_matches_declared": expected_count is None or expected_count == scope["provided_episode_count"],
        "first_last_episode_checked": bool(scope["first_episode"] and scope["last_episode"]),
        "bundle_count": len(grouped),
        "warnings": warnings,
    }


def write_manifest(output_root: Path, source_path: Path, episode_count: int, scope: dict[str, Any]) -> None:
    gates = gates_for_scope(scope["completeness"])
    manifest = textwrap.dedent(
        f"""\
        project: {output_root.name}
        created_at: {datetime.now().isoformat(timespec="seconds")}
        source:
          original: 00_source/original/{source_path.name}
          extracted: 00_source/extracted/source.md
          index: 00_source/source-index.json
          episode_map: 00_source/episode-map.md
        current:
          skeleton: 01_skeleton/reference-skeleton.md
          selected_concept: 02_concepts/selected-concept.md
          bible: 03_plan/project-bible.md
          continuity: 06_state/project-state.md
        counts:
          episodes: {episode_count}
          expected_episodes: {scope["expected_episode_count"] if scope["expected_episode_count"] is not None else "null"}
        scope:
          completeness: {scope["completeness"]}
          source_scope: {scope["source_scope"]}
          first_episode: {scope["first_episode"] if scope["first_episode"] is not None else "null"}
          last_episode: {scope["last_episode"] if scope["last_episode"] is not None else "null"}
          missing_episodes: {json.dumps(scope["missing_episodes"], ensure_ascii=False)}
        gates:
          allow_sample_skeleton: {str(gates["allow_sample_skeleton"]).lower()}
          allow_full_skeleton: {str(gates["allow_full_skeleton"]).lower()}
          allow_full_series_claims: {str(gates["allow_full_series_claims"]).lower()}
          allow_full_series_concepts: {str(gates["allow_full_series_concepts"]).lower()}
          require_scope_disclaimer: {str(gates["require_scope_disclaimer"]).lower()}
        status:
          ingest: {scope["completeness"]}
          completeness: {scope["completeness"]}
          skeleton: pending
          concept: pending
          plan: pending
          outline: pending
          script: pending
        """
    )
    (output_root / "manifest.yaml").write_text(manifest, encoding="utf-8")


def ensure_project_dirs(output_root: Path) -> None:
    for rel in (
        "00_source/original",
        "00_source/extracted",
        "00_source/bundles",
        "00_source/episodes",
        "01_skeleton",
        "02_concepts",
        "03_plan",
        "04_outlines",
        "05_scripts",
        "06_state",
        "07_review",
        "08_export",
        "_archive",
    ):
        (output_root / rel).mkdir(parents=True, exist_ok=True)


def ingest(source_path: Path, output_root: Path, bundle_size: int = 10, force: bool = False) -> dict:
    if output_root.exists() and any(output_root.iterdir()) and not force:
        raise RuntimeError(f"Output directory is not empty: {output_root}. Use --force to write into it.")

    ensure_project_dirs(output_root)
    raw_text = clean_text(read_source(source_path))
    diagnostics = heading_diagnostics(raw_text)
    (output_root / "00_source" / "extracted" / "source.md").write_text(raw_text, encoding="utf-8")
    shutil.copy2(source_path, output_root / "00_source" / "original" / source_path.name)

    sections = split_named_sections(raw_text)
    write_if_text(output_root / "00_source" / "synopsis.md", sections.get("synopsis", ""), "梗概")
    write_if_text(output_root / "00_source" / "story-outline.md", sections.get("story_outline", ""), "总大纲")
    write_if_text(output_root / "00_source" / "characters.md", sections.get("characters", ""), "人物表")
    write_if_text(output_root / "00_source" / "episode-outline.md", sections.get("episode_outline", ""), "剧集大纲")

    episodes = split_episodes(raw_text)
    episodes.sort(key=lambda item: item.number)
    scope = infer_source_scope(source_path, episodes, sections)

    index_entries = []
    for episode in episodes:
        episode_id = slug_episode(episode.number)
        episode_file = Path("00_source") / "episodes" / f"{episode_id}.md"
        bundle_start = ((episode.number - 1) // bundle_size) * bundle_size + 1
        bundle_end = bundle_start + bundle_size - 1
        bundle_file = Path("00_source") / "bundles" / f"eps_{bundle_start:03d}-{bundle_end:03d}.md"
        cast = cast_names(episode.body)
        (output_root / episode_file).write_text(make_episode_text(episode), encoding="utf-8")
        index_entries.append(
            {
                "id": episode_id,
                "episode": episode.number,
                "title": episode.title or "[待确认]",
                "file": episode_file.as_posix(),
                "bundle": bundle_file.as_posix(),
                "char_count": len(episode.body),
                "opening_excerpt": excerpt(episode.body),
                "ending_excerpt": excerpt(episode.body, tail=True),
                "cast": cast,
                "speaker_counts": speaker_counts(episode.body, set(cast)),
                "summary": "[待确认：需 agent 阅读后填写]",
                "hook": "[待确认：需 agent 阅读后填写]",
                "reversal": "[待确认：需 agent 阅读后填写]",
                "character_changes": [],
                "props": [],
                "open_loops": [],
                "status": "auto_split",
            }
        )

    grouped: dict[int, list[Episode]] = {}
    for episode in episodes:
        bundle_start = ((episode.number - 1) // bundle_size) * bundle_size + 1
        grouped.setdefault(bundle_start, []).append(episode)
    for bundle_start, bundle_episodes in grouped.items():
        bundle_end = bundle_start + bundle_size - 1
        bundle_path = output_root / "00_source" / "bundles" / f"eps_{bundle_start:03d}-{bundle_end:03d}.md"
        bundle_path.write_text(make_bundle_text(bundle_episodes), encoding="utf-8")

    (output_root / "00_source" / "episode-map.md").write_text(make_episode_map(episodes), encoding="utf-8")
    index = {
        "schema": "short-drama-source-index.v1",
        "source_file": str(source_path),
        "created_at": datetime.now().isoformat(timespec="seconds"),
        "ingest_mode": scope["completeness"],
        "source_scope": scope["source_scope"],
        "granularity": "episode",
        "bundle_size": bundle_size,
        "episode_count": len(episodes),
        "declared_episode_range": f"1-{scope['expected_episode_count']}" if scope["expected_episode_count"] else None,
        "detected_episode_range": f"{scope['first_episode']}-{scope['last_episode']}" if scope["first_episode"] else None,
        "missing_episodes": scope["missing_episodes"],
        "gates": gates_for_scope(scope["completeness"]),
        "scope": scope,
        "heading_diagnostics": diagnostics,
        "section_detection": section_detection(sections),
        "extraction": extraction_info(source_path, scope),
        "validation": validation_info(scope, grouped, diagnostics, sections),
        "read_strategy": [
            "Read manifest.yaml and 00_source/source-index.json first.",
            "Read 00_source/synopsis.md, story-outline.md, characters.md, episode-outline.md, episode-map.md.",
            "Deep-read 00_source/bundles/eps_001-010.md for opening commercial mechanics.",
            "For later stages, roll through later bundles by tens.",
            "Before writing a target episode, read that episode file plus adjacent and referenced episodes.",
        ],
        "sections": {
            "synopsis": "00_source/synopsis.md",
            "story_outline": "00_source/story-outline.md",
            "characters": "00_source/characters.md",
            "episode_outline": "00_source/episode-outline.md",
            "episode_map": "00_source/episode-map.md",
        },
        "episodes": index_entries,
    }
    (output_root / "00_source" / "source-index.json").write_text(
        json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    write_manifest(output_root, source_path, len(episodes), scope)
    return index


def run_self_test() -> None:
    fixture = textwrap.dedent(
        """\
        # 测试短剧

        梗概
        女主被全家误解，靠祖传账册反击。

        人物
        林晚：女主。
        周沉：男主。
        继母：反派。

        第1集：寿宴受辱
        继母：你也配进这个门？
        林晚：账册在这里。
        众人震惊。

        第2集：账册失踪
        周沉：谁动过保险柜？
        林晚发现账册被换成白纸。

        第十集：真主现身
        继母当众拿出假证。
        林晚：这枚印，只有真正主人能打开。
        门外有人推门而入。
        """
    )
    with tempfile.TemporaryDirectory(prefix="short-drama-ingest-") as tmp:
        tmp_path = Path(tmp)
        source = tmp_path / "fixture.md"
        source.write_text(fixture, encoding="utf-8")
        output = tmp_path / "测试项目"
        index = ingest(source, output, force=True)
        required = [
            output / "manifest.yaml",
            output / "00_source" / "source-index.json",
            output / "00_source" / "episode-map.md",
            output / "00_source" / "bundles" / "eps_001-010.md",
            output / "00_source" / "episodes" / "ep_001.md",
            output / "00_source" / "episodes" / "ep_010.md",
        ]
        missing = [str(path) for path in required if not path.exists()]
        assert not missing, missing
        assert index["episode_count"] == 3, index["episode_count"]
        assert index["granularity"] == "episode"
        print(json.dumps({"ok": True, "output": str(output), "episode_count": 3}, ensure_ascii=False, indent=2))


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Split a short-drama source into episode-level files and project management folders."
    )
    parser.add_argument("source", nargs="?", type=Path, help="Source file: .md, .txt, .docx, or .pdf when extractor exists.")
    parser.add_argument("--out", type=Path, help="Output project directory.")
    parser.add_argument("--bundle-size", type=int, default=10, help="Episodes per bundle. Default: 10.")
    parser.add_argument("--force", action="store_true", help="Allow writing into a non-empty output directory.")
    parser.add_argument("--self-test", action="store_true", help="Run an internal smoke test.")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.self_test:
        run_self_test()
        return 0
    if not args.source:
        print("error: source is required unless --self-test is used", file=sys.stderr)
        return 2
    source_path = args.source.expanduser().resolve()
    if not source_path.exists():
        print(f"error: source not found: {source_path}", file=sys.stderr)
        return 2
    output_root = args.out.expanduser().resolve() if args.out else source_path.with_suffix("")
    index = ingest(source_path, output_root, bundle_size=args.bundle_size, force=args.force)
    print(
        json.dumps(
            {
                "ok": True,
                "output": str(output_root),
                "episode_count": index["episode_count"],
                "granularity": index["granularity"],
                "next_read": [
                    "manifest.yaml",
                    "00_source/source-index.json",
                    "00_source/synopsis.md",
                    "00_source/story-outline.md",
                    "00_source/characters.md",
                    "00_source/episode-outline.md",
                    "00_source/episode-map.md",
                    "00_source/bundles/eps_001-010.md",
                ],
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
