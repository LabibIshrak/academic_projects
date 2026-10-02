"""
N-Gram Language Model -- Graph & Table Generator
=================================================
Student Name: Hasin Ishrak Labib
Student ID  : 240118

This script trains all 5 N-Gram models, evaluates them, and generates
publication-quality graphs and tables saved to the assets/ folder.
"""

import os
import sys
import math
import time
from collections import defaultdict, Counter

import matplotlib
matplotlib.use('Agg')  # non-interactive backend
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np

import nltk

# ── Paths ──
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
ASSETS_DIR = os.path.join(PROJECT_DIR, "assets")
os.makedirs(ASSETS_DIR, exist_ok=True)

# ──────────────────────────────────────────────────────────────────────
#  CORPUS LOADING
# ──────────────────────────────────────────────────────────────────────
def download_nltk_data():
    try:
        nltk.data.find('corpora/brown')
    except LookupError:
        print("[INFO] Downloading NLTK Brown corpus...")
        nltk.download('brown', quiet=True)
    from nltk.corpus import brown
    return brown


def prepare_data(brown):
    all_words = []
    for fileid in brown.fileids():
        all_words.extend(brown.words(fileid))

    sentences = []
    current_sentence = []
    for word in all_words:
        if word in [".", "!", "?"]:
            if current_sentence:
                sentences.append(current_sentence)
                current_sentence = []
        else:
            cleaned = word.lower()
            if cleaned.isalpha():
                current_sentence.append(cleaned)
    if current_sentence:
        sentences.append(current_sentence)
    return sentences


# ──────────────────────────────────────────────────────────────────────
#  MODEL CLASSES  (same as ngram_model.py)
# ──────────────────────────────────────────────────────────────────────
class UnigramModel:
    def __init__(self):
        self.word_counts = Counter()
        self.total_count = 0

    def train(self, sentences):
        for s in sentences:
            for w in s:
                self.word_counts[w] += 1
                self.total_count += 1

    def get_probability(self, word):
        return self.word_counts[word] / self.total_count if self.total_count else 0.0

    def predict(self, input_text, top_n=5):
        return [(w, c / self.total_count) for w, c in self.word_counts.most_common(top_n)]

    def vocab_size(self):
        return len(self.word_counts)

    def ngram_count(self):
        return len(self.word_counts)

    def __str__(self):
        return "Unigram (1-gram)"


class BigramModel:
    def __init__(self):
        self.bigram_counts = defaultdict(int)
        self.unigram_counts = defaultdict(int)

    def train(self, sentences):
        for s in sentences:
            for i in range(len(s)):
                self.unigram_counts[s[i]] += 1
                if i < len(s) - 1:
                    self.bigram_counts[(s[i], s[i + 1])] += 1

    def get_probability(self, word, context):
        if self.unigram_counts[context] == 0:
            return 0.0
        return self.bigram_counts[(context, word)] / self.unigram_counts[context]

    def predict(self, input_text, top_n=5):
        tokens = input_text.lower().split()
        if not tokens:
            return []
        last = tokens[-1]
        cands = {}
        for bg, cnt in self.bigram_counts.items():
            if bg[0] == last:
                cands[bg[1]] = cnt / self.unigram_counts[last]
        return sorted(cands.items(), key=lambda x: x[1], reverse=True)[:top_n]

    def ngram_count(self):
        return len(self.bigram_counts)

    def __str__(self):
        return "Bigram (2-gram)"


class TrigramModel:
    def __init__(self):
        self.trigram_counts = defaultdict(int)
        self.bigram_counts = defaultdict(int)

    def train(self, sentences):
        for s in sentences:
            for i in range(len(s) - 2):
                self.trigram_counts[(s[i], s[i + 1], s[i + 2])] += 1
                self.bigram_counts[(s[i], s[i + 1])] += 1

    def get_probability(self, word, context):
        if self.bigram_counts[context] == 0:
            return 0.0
        return self.trigram_counts[(context[0], context[1], word)] / self.bigram_counts[context]

    def predict(self, input_text, top_n=5):
        tokens = input_text.lower().split()
        if len(tokens) < 2:
            return []
        ctx = (tokens[-2], tokens[-1])
        cands = {}
        for tg, cnt in self.trigram_counts.items():
            if (tg[0], tg[1]) == ctx:
                cands[tg[2]] = cnt / self.bigram_counts[ctx]
        return sorted(cands.items(), key=lambda x: x[1], reverse=True)[:top_n]

    def ngram_count(self):
        return len(self.trigram_counts)

    def __str__(self):
        return "Trigram (3-gram)"


class FourgramModel:
    def __init__(self):
        self.fourgram_counts = defaultdict(int)
        self.trigram_counts = defaultdict(int)

    def train(self, sentences):
        for s in sentences:
            for i in range(len(s) - 3):
                self.fourgram_counts[(s[i], s[i + 1], s[i + 2], s[i + 3])] += 1
                self.trigram_counts[(s[i], s[i + 1], s[i + 2])] += 1

    def get_probability(self, word, context):
        if self.trigram_counts[context] == 0:
            return 0.0
        return self.fourgram_counts[(context[0], context[1], context[2], word)] / self.trigram_counts[context]

    def predict(self, input_text, top_n=5):
        tokens = input_text.lower().split()
        if len(tokens) < 3:
            return []
        ctx = (tokens[-3], tokens[-2], tokens[-1])
        cands = {}
        for fg, cnt in self.fourgram_counts.items():
            if (fg[0], fg[1], fg[2]) == ctx:
                cands[fg[3]] = cnt / self.trigram_counts[ctx]
        return sorted(cands.items(), key=lambda x: x[1], reverse=True)[:top_n]

    def ngram_count(self):
        return len(self.fourgram_counts)

    def __str__(self):
        return "Four-gram (4-gram)"


class FivegramModel:
    def __init__(self):
        self.fivegram_counts = defaultdict(int)
        self.fourgram_counts = defaultdict(int)

    def train(self, sentences):
        for s in sentences:
            for i in range(len(s) - 4):
                self.fivegram_counts[(s[i], s[i + 1], s[i + 2], s[i + 3], s[i + 4])] += 1
                self.fourgram_counts[(s[i], s[i + 1], s[i + 2], s[i + 3])] += 1

    def get_probability(self, word, context):
        if self.fourgram_counts[context] == 0:
            return 0.0
        return self.fivegram_counts[(context[0], context[1], context[2], context[3], word)] / self.fourgram_counts[context]

    def predict(self, input_text, top_n=5):
        tokens = input_text.lower().split()
        if len(tokens) < 4:
            return []
        ctx = (tokens[-4], tokens[-3], tokens[-2], tokens[-1])
        cands = {}
        for fg, cnt in self.fivegram_counts.items():
            if (fg[0], fg[1], fg[2], fg[3]) == ctx:
                cands[fg[4]] = cnt / self.fourgram_counts[ctx]
        return sorted(cands.items(), key=lambda x: x[1], reverse=True)[:top_n]

    def ngram_count(self):
        return len(self.fivegram_counts)

    def __str__(self):
        return "Five-gram (5-gram)"


# ──────────────────────────────────────────────────────────────────────
#  PERPLEXITY
# ──────────────────────────────────────────────────────────────────────
def calculate_perplexity(model, test_sentences, n):
    log_prob_sum = 0.0
    word_count = 0
    for sentence in test_sentences:
        for i in range(n - 1, len(sentence)):
            if n == 1:
                prob = model.get_probability(sentence[i])
            elif n == 2:
                prob = model.get_probability(sentence[i], sentence[i - 1])
            elif n == 3:
                prob = model.get_probability(sentence[i], (sentence[i - 2], sentence[i - 1]))
            elif n == 4:
                prob = model.get_probability(sentence[i],
                                              (sentence[i - 3], sentence[i - 2], sentence[i - 1]))
            elif n == 5:
                prob = model.get_probability(sentence[i],
                                              (sentence[i - 4], sentence[i - 3],
                                               sentence[i - 2], sentence[i - 1]))
            else:
                continue
            if prob > 0:
                log_prob_sum += math.log2(prob)
            else:
                log_prob_sum += -20
            word_count += 1
    if word_count == 0:
        return float('inf')
    return 2 ** (-(log_prob_sum / word_count))


# ──────────────────────────────────────────────────────────────────────
#  COVERAGE ANALYSIS
# ──────────────────────────────────────────────────────────────────────
def calculate_coverage(model, test_sentences, n):
    """What fraction of test contexts yield at least one prediction."""
    total_contexts = 0
    found_contexts = 0
    for sentence in test_sentences:
        for i in range(n - 1, len(sentence)):
            total_contexts += 1
            if n == 1:
                prob = model.get_probability(sentence[i])
            elif n == 2:
                prob = model.get_probability(sentence[i], sentence[i - 1])
            elif n == 3:
                prob = model.get_probability(sentence[i], (sentence[i - 2], sentence[i - 1]))
            elif n == 4:
                prob = model.get_probability(sentence[i],
                                              (sentence[i - 3], sentence[i - 2], sentence[i - 1]))
            elif n == 5:
                prob = model.get_probability(sentence[i],
                                              (sentence[i - 4], sentence[i - 3],
                                               sentence[i - 2], sentence[i - 1]))
            else:
                prob = 0.0
            if prob > 0:
                found_contexts += 1
    return found_contexts / total_contexts * 100 if total_contexts > 0 else 0.0


# ══════════════════════════════════════════════════════════════════════
#  STYLE CONFIGURATION
# ══════════════════════════════════════════════════════════════════════
# Colors inspired by a modern dark palette
COLORS = ['#4FC3F7', '#81C784', '#FFD54F', '#FF8A65', '#CE93D8']
BG_COLOR = '#1a1a2e'
CARD_BG = '#16213e'
TEXT_COLOR = '#e0e0e0'
GRID_COLOR = '#2a2a4a'
ACCENT = '#4FC3F7'

def apply_style():
    plt.rcParams.update({
        'figure.facecolor': BG_COLOR,
        'axes.facecolor': CARD_BG,
        'axes.edgecolor': GRID_COLOR,
        'axes.labelcolor': TEXT_COLOR,
        'text.color': TEXT_COLOR,
        'xtick.color': TEXT_COLOR,
        'ytick.color': TEXT_COLOR,
        'grid.color': GRID_COLOR,
        'grid.alpha': 0.3,
        'font.family': 'sans-serif',
        'font.size': 11,
    })


# ══════════════════════════════════════════════════════════════════════
#  GRAPH 1: PERPLEXITY COMPARISON  (Bar Chart)
# ══════════════════════════════════════════════════════════════════════
def plot_perplexity_bar(model_names, perplexities, filepath):
    apply_style()
    fig, ax = plt.subplots(figsize=(10, 6))

    bars = ax.bar(model_names, perplexities, color=COLORS, width=0.6,
                  edgecolor='white', linewidth=0.5, zorder=3)

    # Value labels on bars
    for bar, val in zip(bars, perplexities):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + max(perplexities) * 0.02,
                f'{val:,.1f}', ha='center', va='bottom', fontweight='bold',
                fontsize=11, color=TEXT_COLOR)

    ax.set_title('Perplexity Comparison Across N-Gram Models',
                 fontsize=16, fontweight='bold', pad=20, color='white')
    ax.set_xlabel('Model', fontsize=13, labelpad=10)
    ax.set_ylabel('Perplexity (lower is better)', fontsize=13, labelpad=10)
    ax.grid(axis='y', linestyle='--', alpha=0.3)
    ax.set_axisbelow(True)

    # Student info
    fig.text(0.99, 0.01, 'Hasin Ishrak Labib | ID: 240118',
             ha='right', va='bottom', fontsize=8, color='#888888', style='italic')

    plt.tight_layout()
    plt.savefig(filepath, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"  [SAVED] {filepath}")


# ══════════════════════════════════════════════════════════════════════
#  GRAPH 2: PERPLEXITY TREND  (Line Chart)
# ══════════════════════════════════════════════════════════════════════
def plot_perplexity_line(model_names, perplexities, filepath):
    apply_style()
    fig, ax = plt.subplots(figsize=(10, 6))

    n_values = list(range(1, len(model_names) + 1))
    ax.plot(n_values, perplexities, marker='o', markersize=12, linewidth=3,
            color=ACCENT, markerfacecolor='white', markeredgecolor=ACCENT,
            markeredgewidth=2, zorder=5)

    # Fill under curve
    ax.fill_between(n_values, perplexities, alpha=0.15, color=ACCENT)

    # Annotate points
    for x, y, name in zip(n_values, perplexities, model_names):
        ax.annotate(f'{y:,.1f}', (x, y), textcoords="offset points",
                    xytext=(0, 18), ha='center', fontweight='bold', fontsize=10,
                    color='white',
                    bbox=dict(boxstyle='round,pad=0.3', facecolor=CARD_BG,
                              edgecolor=ACCENT, alpha=0.9))

    ax.set_title('Perplexity Trend as N Increases',
                 fontsize=16, fontweight='bold', pad=20, color='white')
    ax.set_xlabel('N-gram Order (N)', fontsize=13, labelpad=10)
    ax.set_ylabel('Perplexity', fontsize=13, labelpad=10)
    ax.set_xticks(n_values)
    ax.set_xticklabels(model_names, rotation=15)
    ax.grid(True, linestyle='--', alpha=0.3)

    fig.text(0.99, 0.01, 'Hasin Ishrak Labib | ID: 240118',
             ha='right', va='bottom', fontsize=8, color='#888888', style='italic')

    plt.tight_layout()
    plt.savefig(filepath, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"  [SAVED] {filepath}")


# ══════════════════════════════════════════════════════════════════════
#  GRAPH 3: TRAINING TIME COMPARISON  (Horizontal Bar Chart)
# ══════════════════════════════════════════════════════════════════════
def plot_training_time(model_names, times, filepath):
    apply_style()
    fig, ax = plt.subplots(figsize=(10, 5))

    y_pos = np.arange(len(model_names))
    bars = ax.barh(y_pos, times, color=COLORS, height=0.55,
                   edgecolor='white', linewidth=0.5, zorder=3)

    for bar, val in zip(bars, times):
        ax.text(bar.get_width() + max(times) * 0.02, bar.get_y() + bar.get_height() / 2,
                f'{val:.2f}s', ha='left', va='center', fontweight='bold',
                fontsize=11, color=TEXT_COLOR)

    ax.set_yticks(y_pos)
    ax.set_yticklabels(model_names)
    ax.set_title('Training Time Comparison',
                 fontsize=16, fontweight='bold', pad=20, color='white')
    ax.set_xlabel('Time (seconds)', fontsize=13, labelpad=10)
    ax.grid(axis='x', linestyle='--', alpha=0.3)
    ax.set_axisbelow(True)
    ax.invert_yaxis()

    fig.text(0.99, 0.01, 'Hasin Ishrak Labib | ID: 240118',
             ha='right', va='bottom', fontsize=8, color='#888888', style='italic')

    plt.tight_layout()
    plt.savefig(filepath, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"  [SAVED] {filepath}")


# ══════════════════════════════════════════════════════════════════════
#  GRAPH 4: N-GRAM COUNT  (Bar Chart)
# ══════════════════════════════════════════════════════════════════════
def plot_ngram_counts(model_names, counts, filepath):
    apply_style()
    fig, ax = plt.subplots(figsize=(10, 6))

    bars = ax.bar(model_names, counts, color=COLORS, width=0.6,
                  edgecolor='white', linewidth=0.5, zorder=3)

    for bar, val in zip(bars, counts):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + max(counts) * 0.02,
                f'{val:,}', ha='center', va='bottom', fontweight='bold',
                fontsize=10, color=TEXT_COLOR)

    ax.set_title('Unique N-Gram Counts Per Model',
                 fontsize=16, fontweight='bold', pad=20, color='white')
    ax.set_xlabel('Model', fontsize=13, labelpad=10)
    ax.set_ylabel('Number of Unique N-Grams', fontsize=13, labelpad=10)
    ax.grid(axis='y', linestyle='--', alpha=0.3)
    ax.set_axisbelow(True)
    ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: format(int(x), ',')))

    fig.text(0.99, 0.01, 'Hasin Ishrak Labib | ID: 240118',
             ha='right', va='bottom', fontsize=8, color='#888888', style='italic')

    plt.tight_layout()
    plt.savefig(filepath, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"  [SAVED] {filepath}")


# ══════════════════════════════════════════════════════════════════════
#  GRAPH 5: COVERAGE  (Bar + Line Combo)
# ══════════════════════════════════════════════════════════════════════
def plot_coverage(model_names, coverages, filepath):
    apply_style()
    fig, ax = plt.subplots(figsize=(10, 6))

    bars = ax.bar(model_names, coverages, color=COLORS, width=0.6,
                  edgecolor='white', linewidth=0.5, alpha=0.8, zorder=3)

    # Overlay line
    n_vals = range(len(model_names))
    ax.plot(n_vals, coverages, marker='D', markersize=8, linewidth=2.5,
            color='white', markerfacecolor='white', zorder=5)

    for bar, val in zip(bars, coverages):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 1.5,
                f'{val:.1f}%', ha='center', va='bottom', fontweight='bold',
                fontsize=11, color='white')

    ax.set_title('Prediction Coverage (% of Test Contexts with Valid Predictions)',
                 fontsize=14, fontweight='bold', pad=20, color='white')
    ax.set_xlabel('Model', fontsize=13, labelpad=10)
    ax.set_ylabel('Coverage (%)', fontsize=13, labelpad=10)
    ax.set_ylim(0, 110)
    ax.grid(axis='y', linestyle='--', alpha=0.3)
    ax.set_axisbelow(True)

    fig.text(0.99, 0.01, 'Hasin Ishrak Labib | ID: 240118',
             ha='right', va='bottom', fontsize=8, color='#888888', style='italic')

    plt.tight_layout()
    plt.savefig(filepath, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"  [SAVED] {filepath}")


# ══════════════════════════════════════════════════════════════════════
#  TABLE: SUMMARY COMPARISON  (rendered as image)
# ══════════════════════════════════════════════════════════════════════
def plot_summary_table(model_names, perplexities, times, ngram_counts, coverages, filepath):
    apply_style()
    fig, ax = plt.subplots(figsize=(14, 5))
    ax.axis('off')

    col_labels = ['Model', 'N', 'Context\nWindow', 'Unique\nN-Grams',
                  'Training\nTime (s)', 'Perplexity', 'Coverage\n(%)']

    table_data = []
    for i, name in enumerate(model_names):
        n = i + 1
        ctx = f'{n - 1} word{"s" if n - 1 != 1 else ""}'
        table_data.append([
            name,
            str(n),
            ctx,
            f'{ngram_counts[i]:,}',
            f'{times[i]:.2f}',
            f'{perplexities[i]:,.1f}',
            f'{coverages[i]:.1f}%',
        ])

    table = ax.table(cellText=table_data, colLabels=col_labels,
                     cellLoc='center', loc='center')

    # Style the table
    table.auto_set_font_size(False)
    table.set_fontsize(11)
    table.scale(1, 1.8)

    # Header row
    for j in range(len(col_labels)):
        cell = table[0, j]
        cell.set_facecolor('#0a3d62')
        cell.set_text_props(color='white', fontweight='bold', fontsize=11)
        cell.set_edgecolor('#1a1a2e')

    # Data rows with alternating colors
    for i in range(len(table_data)):
        for j in range(len(col_labels)):
            cell = table[i + 1, j]
            if i % 2 == 0:
                cell.set_facecolor('#1e3a5f')
            else:
                cell.set_facecolor('#16213e')
            cell.set_text_props(color=TEXT_COLOR, fontsize=11)
            cell.set_edgecolor('#2a2a4a')

    ax.set_title('N-Gram Model Comparison Summary\nHasin Ishrak Labib | ID: 240118',
                 fontsize=16, fontweight='bold', pad=30, color='white',
                 y=0.95)

    plt.tight_layout()
    plt.savefig(filepath, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"  [SAVED] {filepath}")


# ══════════════════════════════════════════════════════════════════════
#  TABLE 2: SAMPLE PREDICTIONS  (rendered as image)
# ══════════════════════════════════════════════════════════════════════
def plot_prediction_table(models_with_n, sample_inputs, filepath):
    apply_style()

    n_inputs = len(sample_inputs)
    n_models = len(models_with_n)

    fig, ax = plt.subplots(figsize=(16, 3 + n_inputs * 1.2))
    ax.axis('off')

    col_labels = ['Input Text'] + [str(m) for m, _ in models_with_n]
    table_data = []

    for inp in sample_inputs:
        row = [inp]
        for model, n in models_with_n:
            preds = model.predict(inp, top_n=3)
            if preds:
                pred_str = ', '.join([f'{w} ({p:.3f})' for w, p in preds[:3]])
            else:
                pred_str = '-- (needs more context)'
            row.append(pred_str)
        table_data.append(row)

    table = ax.table(cellText=table_data, colLabels=col_labels,
                     cellLoc='center', loc='center')

    table.auto_set_font_size(False)
    table.set_fontsize(9)
    table.scale(1, 2.0)

    # Header
    for j in range(len(col_labels)):
        cell = table[0, j]
        cell.set_facecolor('#0a3d62')
        cell.set_text_props(color='white', fontweight='bold', fontsize=10)
        cell.set_edgecolor('#1a1a2e')

    # Data rows
    for i in range(len(table_data)):
        for j in range(len(col_labels)):
            cell = table[i + 1, j]
            if i % 2 == 0:
                cell.set_facecolor('#1e3a5f')
            else:
                cell.set_facecolor('#16213e')
            cell.set_text_props(color=TEXT_COLOR, fontsize=9)
            cell.set_edgecolor('#2a2a4a')
            if j == 0:
                cell.set_text_props(color='#4FC3F7', fontweight='bold', fontsize=9)

    ax.set_title('Sample Predictions from Each Model\nHasin Ishrak Labib | ID: 240118',
                 fontsize=16, fontweight='bold', pad=30, color='white', y=0.98)

    plt.tight_layout()
    plt.savefig(filepath, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"  [SAVED] {filepath}")


# ══════════════════════════════════════════════════════════════════════
#  GRAPH 6: COMBINED DASHBOARD
# ══════════════════════════════════════════════════════════════════════
def plot_dashboard(model_names, perplexities, times, ngram_counts, coverages, filepath):
    apply_style()
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))

    # -- Plot 1: Perplexity bars --
    ax = axes[0, 0]
    bars = ax.bar(model_names, perplexities, color=COLORS, width=0.6, edgecolor='white', linewidth=0.5, zorder=3)
    for bar, val in zip(bars, perplexities):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + max(perplexities) * 0.02,
                f'{val:,.0f}', ha='center', va='bottom', fontweight='bold', fontsize=9, color=TEXT_COLOR)
    ax.set_title('Perplexity (lower = better)', fontsize=13, fontweight='bold', color='white')
    ax.set_ylabel('Perplexity')
    ax.grid(axis='y', linestyle='--', alpha=0.3)
    ax.set_axisbelow(True)

    # -- Plot 2: Training Time --
    ax = axes[0, 1]
    bars = ax.bar(model_names, times, color=COLORS, width=0.6, edgecolor='white', linewidth=0.5, zorder=3)
    for bar, val in zip(bars, times):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + max(times) * 0.02,
                f'{val:.2f}s', ha='center', va='bottom', fontweight='bold', fontsize=9, color=TEXT_COLOR)
    ax.set_title('Training Time', fontsize=13, fontweight='bold', color='white')
    ax.set_ylabel('Seconds')
    ax.grid(axis='y', linestyle='--', alpha=0.3)
    ax.set_axisbelow(True)

    # -- Plot 3: N-gram counts --
    ax = axes[1, 0]
    bars = ax.bar(model_names, ngram_counts, color=COLORS, width=0.6, edgecolor='white', linewidth=0.5, zorder=3)
    for bar, val in zip(bars, ngram_counts):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + max(ngram_counts) * 0.02,
                f'{val:,}', ha='center', va='bottom', fontweight='bold', fontsize=8, color=TEXT_COLOR)
    ax.set_title('Unique N-Gram Counts', fontsize=13, fontweight='bold', color='white')
    ax.set_ylabel('Count')
    ax.grid(axis='y', linestyle='--', alpha=0.3)
    ax.set_axisbelow(True)
    ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: format(int(x), ',')))

    # -- Plot 4: Coverage --
    ax = axes[1, 1]
    bars = ax.bar(model_names, coverages, color=COLORS, width=0.6, edgecolor='white', linewidth=0.5, zorder=3)
    ax.plot(range(len(model_names)), coverages, marker='D', markersize=6, linewidth=2, color='white', zorder=5)
    for bar, val in zip(bars, coverages):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 1.5,
                f'{val:.1f}%', ha='center', va='bottom', fontweight='bold', fontsize=9, color='white')
    ax.set_title('Coverage (%)', fontsize=13, fontweight='bold', color='white')
    ax.set_ylabel('Coverage (%)')
    ax.set_ylim(0, 115)
    ax.grid(axis='y', linestyle='--', alpha=0.3)
    ax.set_axisbelow(True)

    fig.suptitle('N-Gram Language Model - Complete Analysis Dashboard\nHasin Ishrak Labib | ID: 240118',
                 fontsize=18, fontweight='bold', color='white', y=1.02)

    plt.tight_layout()
    plt.savefig(filepath, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"  [SAVED] {filepath}")


# ══════════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════════
def main():
    print("=" * 65)
    print("  N-GRAM MODEL -- GRAPH & TABLE GENERATOR")
    print("  Student: Hasin Ishrak Labib | ID: 240118")
    print("=" * 65)
    print()

    # 1. Load data
    print("[1/5] Loading Brown Corpus...")
    brown = download_nltk_data()
    sentences = prepare_data(brown)
    total_words = sum(len(s) for s in sentences)
    print(f"      Loaded {len(sentences):,} sentences, {total_words:,} words\n")

    # 2. Train models
    print("[2/5] Training all 5 models...")
    models_with_n = [
        (UnigramModel(), 1),
        (BigramModel(), 2),
        (TrigramModel(), 3),
        (FourgramModel(), 4),
        (FivegramModel(), 5),
    ]

    model_names = []
    training_times = []
    for model, n in models_with_n:
        start = time.time()
        model.train(sentences)
        elapsed = time.time() - start
        training_times.append(elapsed)
        model_names.append(str(model))
        print(f"      {str(model):<25} trained in {elapsed:.2f}s  |  {model.ngram_count():>10,} unique n-grams")

    print()

    # 3. Evaluate
    print("[3/5] Evaluating models...")
    split_idx = int(len(sentences) * 0.9)
    test_sentences = sentences[split_idx:]
    print(f"      Test set: {len(test_sentences):,} sentences\n")

    perplexities = []
    coverages = []
    for model, n in models_with_n:
        pp = calculate_perplexity(model, test_sentences, n)
        cov = calculate_coverage(model, test_sentences, n)
        perplexities.append(pp)
        coverages.append(cov)
        print(f"      {str(model):<25} Perplexity: {pp:>12,.1f}  |  Coverage: {cov:.1f}%")

    ngram_counts = [m.ngram_count() for m, _ in models_with_n]
    print()

    # 4. Generate graphs and tables
    print("[4/5] Generating graphs and tables...\n")

    plot_perplexity_bar(model_names, perplexities,
                        os.path.join(ASSETS_DIR, "graph1_perplexity_comparison.png"))

    plot_perplexity_line(model_names, perplexities,
                         os.path.join(ASSETS_DIR, "graph2_perplexity_trend.png"))

    plot_training_time(model_names, training_times,
                       os.path.join(ASSETS_DIR, "graph3_training_time.png"))

    plot_ngram_counts(model_names, ngram_counts,
                      os.path.join(ASSETS_DIR, "graph4_ngram_counts.png"))

    plot_coverage(model_names, coverages,
                  os.path.join(ASSETS_DIR, "graph5_coverage.png"))

    plot_dashboard(model_names, perplexities, training_times, ngram_counts, coverages,
                   os.path.join(ASSETS_DIR, "graph6_dashboard.png"))

    plot_summary_table(model_names, perplexities, training_times, ngram_counts, coverages,
                       os.path.join(ASSETS_DIR, "table1_summary_comparison.png"))

    # Sample predictions table
    sample_inputs = [
        "the united states",
        "i want to",
        "he said that the",
        "it is a",
        "they have been",
    ]
    plot_prediction_table(models_with_n, sample_inputs,
                          os.path.join(ASSETS_DIR, "table2_sample_predictions.png"))

    print()

    # 5. Summary
    print("[5/5] All assets generated!\n")
    print("  Files saved to:", ASSETS_DIR)
    print()
    print("  Graphs:")
    print("    - graph1_perplexity_comparison.png")
    print("    - graph2_perplexity_trend.png")
    print("    - graph3_training_time.png")
    print("    - graph4_ngram_counts.png")
    print("    - graph5_coverage.png")
    print("    - graph6_dashboard.png (all-in-one)")
    print()
    print("  Tables:")
    print("    - table1_summary_comparison.png")
    print("    - table2_sample_predictions.png")
    print()
    print("=" * 65)
    print("  DONE! Use these in your report and presentation.")
    print("=" * 65)


if __name__ == "__main__":
    main()
