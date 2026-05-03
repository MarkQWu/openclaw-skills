#!/usr/bin/env python3
"""
condense-source.py — /仿写 大文件压缩脚本
用法: python3 condense-source.py <源文件路径> [--full-episodes N] [--output 输出路径]

功能：
  - 检测源剧本中两种结构：
    A) 双段式（内置大纲摘要 + 完整剧本正文）→ 保留大纲 + 前N集全文
    B) 单段式（仅完整剧本正文）→ 保留前N集全文 + 关键词提取其余集结构摘要
  - 输出 source-script-condensed.md

支持格式：.docx, .md, .txt
"""

import re
import sys
import os
import argparse
from datetime import date

_CN_DIGIT = {'零':0,'一':1,'二':2,'三':3,'四':4,'五':5,'六':6,'七':7,'八':8,'九':9}
_CN_UNIT  = {'十':10,'百':100,'千':1000}

def _parse_cn_num(s):
    """将中文数字字符串（支持到千）解析为整数，失败返回 -1"""
    s = s.strip()
    if not s:
        return -1
    # 纯阿拉伯数字已在 parse_ep_num 处理
    result = 0
    unit = 1
    tmp = 0
    # 从右到左扫描
    i = len(s) - 1
    while i >= 0:
        ch = s[i]
        if ch in _CN_DIGIT:
            tmp = _CN_DIGIT[ch]
            result += tmp * unit
            i -= 1
        elif ch in _CN_UNIT:
            unit = _CN_UNIT[ch]
            # 十 可以单独出现在最前（十一 = 11，不是 一十一）
            if unit == 10 and i == 0:
                result += 10
            i -= 1
        else:
            return -1
    return result if result > 0 else -1

EP_PATTERN = re.compile(r'^第\s*([零一二三四五六七八九十百千\d]+)\s*集')

# 爽点关键词
SATISFACTION_KEYWORDS = {
    '身份暴露型': ['暴露', '揭穿', '真实身份', '被认出', '身份曝光', '扯下面具'],
    '打脸型':     ['打脸', '啪啪', '被打脸', '反打', '讽刺'],
    '逆袭型':     ['逆袭', '反制', '反将', '将计就计', '绝地反击', '扬眉吐气'],
    '助力型':     ['助力', '贵人', '援兵', '出现', '相助', '救援'],
    '知情者反应': ['震惊', '傻眼', '瞠目结舌', '不敢相信', '惊呆'],
}

# 情感炸点关键词
PEAK_KEYWORDS = {
    '背叛揭露': ['背叛', '出卖', '告密', '叛徒'],
    '权力反转': ['夺权', '反转', '局势逆转', '翻盘'],
    '牺牲':     ['牺牲', '自刎', '殒命', '战死', '以命换'],
    '告白':     ['表白', '告白', '我喜欢你', '我爱你', '心意'],
    '清算':     ['清算', '复仇', '算账', '还债', '报应'],
    '重逢':     ['重逢', '相认', '认出', '失散多年'],
}

# 付费卡点关键词
PAYWALL_KEYWORDS = ['悬念', '未完', '下集', '迷雾', '谜底', '关键时刻', '戛然而止',
                    '就在此时', '千钧一发', '生死关头', '命运转折']


def parse_ep_num(s):
    """解析集数字符串为整数（支持阿拉伯数字和中文数字）"""
    s = s.strip()
    if s.isdigit():
        return int(s)
    return _parse_cn_num(s)


def load_file(path):
    """加载文件，返回段落列表"""
    ext = os.path.splitext(path)[1].lower()
    if ext == '.docx':
        try:
            import docx
        except ImportError:
            print('[ERROR] 需要安装 python-docx: pip install python-docx', file=sys.stderr)
            sys.exit(1)
        doc = docx.Document(path)
        return [p.text for p in doc.paragraphs if p.text.strip()]
    else:
        with open(path, encoding='utf-8') as f:
            raw = f.read()
        return [line.strip() for line in raw.splitlines() if line.strip()]


def detect_episodes(paras):
    """
    返回 [(ep_num, para_idx), ...] 按顺序，所有集数标记的位置
    """
    result = []
    for i, p in enumerate(paras):
        first_line = p.split('\n')[0].strip()
        m = EP_PATTERN.match(first_line)
        if m:
            ep_num = parse_ep_num(m.group(1))
            if ep_num > 0:
                result.append((ep_num, i))
    return result


def detect_structure(paras, ep_markers):
    """
    判断文件结构：
    - 双段式：同一集号出现两次（大纲段 + 正文段）
    - 单段式：每集只出现一次
    返回 'dual' 或 'single'，以及结构信息
    """
    ep_occurrences = {}
    for ep_num, idx in ep_markers:
        ep_occurrences.setdefault(ep_num, []).append(idx)

    dual_count = sum(1 for idxs in ep_occurrences.values() if len(idxs) >= 2)
    total_eps = len(ep_occurrences)

    if total_eps == 0:
        return 'unknown', {}

    dual_ratio = dual_count / total_eps
    if dual_ratio >= 0.7:  # 70%以上的集都出现两次 = 双段式
        first_occ = {ep: idxs[0] for ep, idxs in ep_occurrences.items()}
        second_occ = {ep: idxs[1] for ep, idxs in ep_occurrences.items() if len(idxs) >= 2}
        return 'dual', {
            'outline_start': min(first_occ.values()),
            'outline_end': max(first_occ.values()),
            'script_start': min(second_occ.values()),
            'first_occ': first_occ,
            'second_occ': second_occ,
            'total_eps': total_eps,
        }
    else:
        return 'single', {
            'ep_occurrences': ep_occurrences,
            'first_occ': {ep: idxs[0] for ep, idxs in ep_occurrences.items()},
            'total_eps': total_eps,
        }


def infer_rhythm(ep_num, total_eps):
    """根据集数位置推断节奏段"""
    ratio = ep_num / total_eps
    if ratio <= 0.30:
        return '压迫'
    elif ratio <= 0.70:
        return '蓄力'
    else:
        return '清算'


def infer_satisfaction(text):
    """从文本提取爽点类型"""
    for stype, keywords in SATISFACTION_KEYWORDS.items():
        if any(kw in text for kw in keywords):
            return stype
    return '无'


def infer_peak(text):
    """从文本提取情感炸点类型"""
    for ptype, keywords in PEAK_KEYWORDS.items():
        if any(kw in text for kw in keywords):
            return ptype
    return '无'


def infer_paywall(text):
    """从文本判断是否有付费卡点"""
    return '有' if any(kw in text for kw in PAYWALL_KEYWORDS) else '无'


def get_episode_text(paras, ep_num, first_occ, next_ep_idx_map):
    """获取某集的完整文本"""
    start = first_occ[ep_num]
    end = next_ep_idx_map.get(ep_num, len(paras))
    return '\n'.join(paras[start:end])


_SKIP_LINE = re.compile(
    r'^(\d+-\d+[\s\S]*内\s*[日夜]|人物[：:]|△|（字幕|【字幕|〔字幕|OS：|旁白：|画外音：|#\s|\[场景\])'
)

def build_structure_line(ep_num, text, total_eps):
    """生成5字段结构摘要行"""
    lines = text.split('\n')
    summary = ''
    for line in lines:
        line = line.strip()
        if not line:
            continue
        if EP_PATTERN.match(line):
            continue
        if _SKIP_LINE.match(line):
            continue
        # 取第一条有实质内容的行（剔除纯场景标头、人物表、动作描述）
        summary = line[:60]
        break
    if not summary:
        summary = f'（第{ep_num}集）'

    rhythm = infer_rhythm(ep_num, total_eps)
    sat = infer_satisfaction(text)
    peak = infer_peak(text)
    paywall = infer_paywall(text)

    return f'Ep{ep_num}: {summary} | 节奏段:{rhythm} | 爽点:{sat} | 炸点:{peak} | 卡点:{paywall}'


def condense_dual(paras, info, full_eps, source_name):
    """处理双段式文件（内置大纲 + 完整剧本）"""
    first_occ = info['first_occ']
    second_occ = info['second_occ']
    total_eps = info['total_eps']
    outline_start = info['outline_start']
    script_start = info['script_start']

    # 构建 next_ep_idx（全本段中，每集的结束位置 = 下一集的开始位置）
    sorted_script_eps = sorted(second_occ.keys())
    next_ep_map = {}
    for i, ep in enumerate(sorted_script_eps):
        if i + 1 < len(sorted_script_eps):
            next_ep_map[ep] = second_occ[sorted_script_eps[i + 1]]
        else:
            next_ep_map[ep] = len(paras)

    # 元数据段（大纲开始前的所有内容）
    meta = '\n\n'.join(paras[:outline_start])

    # 大纲摘要段（全部保留，已经是压缩格式）
    outline_paras = []
    for ep_num in sorted(first_occ.keys()):
        idx = first_occ[ep_num]
        text = paras[idx]
        # 去掉内嵌的换行，让每集变成一行
        first_line = text.split('\n')[0]
        rest = ' '.join(text.split('\n')[1:]).strip()
        if rest:
            outline_paras.append(f'{first_line}\n{rest}')
        else:
            outline_paras.append(first_line)
    outline_section = '\n'.join(outline_paras)

    # 全本正文段（只保留前 full_eps 集）
    full_text_parts = []
    keep_eps = sorted([ep for ep in sorted_script_eps if ep <= full_eps])
    for ep_num in keep_eps:
        start = second_occ[ep_num]
        end = next_ep_map[ep_num]
        ep_text = '\n'.join(paras[start:end])
        full_text_parts.append(ep_text)
    full_text_section = '\n\n'.join(full_text_parts)

    skipped_count = total_eps - len(keep_eps)

    output = f"""<!-- 自动压缩 | 原文: {source_name} | 总集数: {total_eps} | 全文集: 1-{full_eps} | 结构模式: 双段式（内置大纲）| 压缩日期: {date.today()} -->
<!-- 节省: 跳过第{full_eps+1}-{total_eps}集全文（{skipped_count}集），保留大纲摘要段 -->

## 元数据 & 人物简介

{meta}

## 大纲摘要（全{total_eps}集）

{outline_section}

## 完整正文（第1-{full_eps}集 · voice/style 锚定）

{full_text_section}
"""
    return output.strip()


def condense_single(paras, info, full_eps, source_name):
    """处理单段式文件（仅完整剧本，需要规则生成摘要）"""
    first_occ = info['first_occ']
    total_eps = info['total_eps']

    sorted_eps = sorted(first_occ.keys())
    next_ep_map = {}
    for i, ep in enumerate(sorted_eps):
        if i + 1 < len(sorted_eps):
            next_ep_map[ep] = first_occ[sorted_eps[i + 1]]
        else:
            next_ep_map[ep] = len(paras)

    # 元数据（第一集开始前）
    meta_end = first_occ[sorted_eps[0]]
    meta = '\n\n'.join(paras[:meta_end])

    # 全文段（前 full_eps 集）
    full_text_parts = []
    keep_eps = [ep for ep in sorted_eps if ep <= full_eps]
    for ep_num in keep_eps:
        start = first_occ[ep_num]
        end = next_ep_map[ep_num]
        ep_text = '\n'.join(paras[start:end])
        full_text_parts.append(ep_text)
    full_text_section = '\n\n'.join(full_text_parts)

    # 结构摘要（剩余集）
    summary_lines = []
    remaining_eps = [ep for ep in sorted_eps if ep > full_eps]
    for ep_num in remaining_eps:
        start = first_occ[ep_num]
        end = next_ep_map[ep_num]
        ep_text = '\n'.join(paras[start:end])
        line = build_structure_line(ep_num, ep_text, total_eps)
        summary_lines.append(line)
    summary_section = '\n'.join(summary_lines)

    skipped_count = len(remaining_eps)

    output = f"""<!-- 自动压缩 | 原文: {source_name} | 总集数: {total_eps} | 全文集: 1-{full_eps} | 结构模式: 单段式（规则生成摘要）| 压缩日期: {date.today()} -->
<!-- 节省: 第{full_eps+1}-{total_eps}集（{skipped_count}集）转为5字段结构摘要 -->

## 元数据

{meta}

## 完整正文（第1-{full_eps}集 · voice/style 锚定）

{full_text_section}

## 结构摘要（第{full_eps+1}-{total_eps}集）

格式：Ep{'{'}N{'}'}: 核心冲突 | 节奏段:[压迫/蓄力/清算] | 爽点:[类型/无] | 炸点:[类型/无] | 卡点:[有/无]

{summary_section}
"""
    return output.strip()


def main():
    parser = argparse.ArgumentParser(description='/仿写 源剧本大文件压缩工具')
    parser.add_argument('source', help='源剧本路径 (.docx/.md/.txt)')
    parser.add_argument('--full-episodes', type=int, default=10,
                        help='保留全文的集数（默认10）')
    parser.add_argument('--output', help='输出路径（默认: <同目录>/source-script-condensed.md）')
    args = parser.parse_args()

    if not os.path.exists(args.source):
        print(f'[ERROR] 文件不存在: {args.source}', file=sys.stderr)
        sys.exit(1)

    source_name = os.path.basename(args.source)
    print(f'[INFO] 加载: {source_name}')

    paras = load_file(args.source)
    print(f'[INFO] 段落数: {len(paras)}')

    ep_markers = detect_episodes(paras)
    print(f'[INFO] 检测到集数标记: {len(ep_markers)} 个')

    if not ep_markers:
        print('[WARN] 未识别到集数边界，无法自动压缩', file=sys.stderr)
        print('[WARN] 请手动提供前10集+其余集的结构摘要', file=sys.stderr)
        sys.exit(2)

    structure, info = detect_structure(paras, ep_markers)
    total_eps = info.get('total_eps', 0)
    print(f'[INFO] 文件结构: {structure} | 总集数: {total_eps}')

    if total_eps <= args.full_episodes:
        print(f'[INFO] 总集数 ({total_eps}) ≤ 全文集数阈值 ({args.full_episodes})，无需压缩')
        sys.exit(0)

    if structure == 'dual':
        print(f'[INFO] 双段式：保留大纲摘要全{total_eps}集 + 全本前{args.full_episodes}集')
        condensed = condense_dual(paras, info, args.full_episodes, source_name)
    elif structure == 'single':
        print(f'[INFO] 单段式：全本前{args.full_episodes}集 + 规则生成第{args.full_episodes+1}-{total_eps}集摘要')
        condensed = condense_single(paras, info, args.full_episodes, source_name)
    else:
        print('[WARN] 结构识别失败，fallback: 保留前10集全文', file=sys.stderr)
        condensed = condense_single(paras, {'first_occ': {ep: idx for ep, idx in ep_markers},
                                             'total_eps': len(set(ep for ep, _ in ep_markers))},
                                    args.full_episodes, source_name)

    output_path = args.output
    if not output_path:
        base_dir = os.path.dirname(args.source)
        output_path = os.path.join(base_dir, 'source-script-condensed.md')

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(condensed)

    # 统计
    original_chars = sum(len(p) for p in paras)
    condensed_chars = len(condensed)
    savings = (1 - condensed_chars / original_chars) * 100
    print(f'[OK] 压缩完成: {output_path}')
    print(f'     原文: {original_chars:,} 字 ≈ {original_chars//2:,} token')
    print(f'     压缩后: {condensed_chars:,} 字 ≈ {condensed_chars//2:,} token')
    print(f'     节省: {savings:.1f}%')


if __name__ == '__main__':
    main()
