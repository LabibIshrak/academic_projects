"""
N-Gram Language Model for Next Word Prediction
===============================================
Student Name: Hasin Ishrak Labib
Student ID  : 240118

This program implements 5 N-Gram algorithms for next word prediction:
    1. Unigram Model  (1-gram)
    2. Bigram Model   (2-gram)
    3. Trigram Model   (3-gram)
    4. Four-gram Model (4-gram)
    5. Five-gram Model (5-gram)

Corpus: NLTK Brown Corpus
"""

import sys
import math
import time
from collections import defaultdict, Counter

import nltk

# ──────────────────────────────────────────────────────────────────────
# Ensure required NLTK data is available
# ──────────────────────────────────────────────────────────────────────
def download_nltk_data():
    """Download the Brown corpus if not already present."""
    try:
        nltk.data.find('corpora/brown')
    except LookupError:
        print("[INFO] Downloading NLTK Brown corpus...")
        nltk.download('brown', quiet=True)
    from nltk.corpus import brown
    return brown


# ══════════════════════════════════════════════════════════════════════
#  DATA PREPARATION
# ══════════════════════════════════════════════════════════════════════
def prepare_data(brown):
    """
    Load and preprocess text from the Brown corpus.
    - All words are lowercased.
    - Punctuation marks (. ! ?) serve as sentence boundaries.
    - Returns a list of sentences, where each sentence is a list of words.
    """
    all_words = []
    for fileid in brown.fileids():
        words = brown.words(fileid)
        all_words.extend(words)

    sentences = []
    current_sentence = []

    for word in all_words:
        if word in [".", "!", "?"]:
            if current_sentence:
                sentences.append(current_sentence)
                current_sentence = []
        else:
            cleaned = word.lower()
            # skip pure punctuation tokens like commas, colons, etc.
            if cleaned.isalpha():
                current_sentence.append(cleaned)

    # Append any remaining sentence
    if current_sentence:
        sentences.append(current_sentence)

    return sentences


# ══════════════════════════════════════════════════════════════════════
#  ALGORITHM 1: UNIGRAM MODEL (1-gram)
# ══════════════════════════════════════════════════════════════════════
class UnigramModel:
    """
    The Unigram model predicts the next word based solely on the overall
    frequency of words in the corpus. It does NOT consider any context.

    P(w) = count(w) / total_word_count
    """

    def __init__(self):
        self.word_counts = Counter()
        self.total_count = 0

    def train(self, sentences):
        """Train the unigram model on a list of sentences."""
        for sentence in sentences:
            for word in sentence:
                self.word_counts[word] += 1
                self.total_count += 1

    def predict(self, input_text, top_n=5):
        """
        Return the top-N most frequent words in the corpus.
        (Unigram ignores context entirely.)
        """
        most_common = self.word_counts.most_common(top_n)
        return [(word, count / self.total_count) for word, count in most_common]

    def get_probability(self, word):
        """Return P(word) under the unigram model."""
        if self.total_count == 0:
            return 0.0
        return self.word_counts[word] / self.total_count

    def __str__(self):
        return "Unigram Model (1-gram)"


# ══════════════════════════════════════════════════════════════════════
#  ALGORITHM 2: BIGRAM MODEL (2-gram)
# ══════════════════════════════════════════════════════════════════════
class BigramModel:
    """
    The Bigram model predicts the next word using the immediately
    preceding word as context.

    P(w2 | w1) = count(w1, w2) / count(w1)
    """

    def __init__(self):
        self.bigram_counts = defaultdict(int)
        self.unigram_counts = defaultdict(int)

    def train(self, sentences):
        """Train the bigram model."""
        for sentence in sentences:
            for i in range(len(sentence)):
                self.unigram_counts[sentence[i]] += 1
                if i < len(sentence) - 1:
                    bigram = (sentence[i], sentence[i + 1])
                    self.bigram_counts[bigram] += 1

    def predict(self, input_text, top_n=5):
        """Predict the next word given the last word of input_text."""
        tokens = input_text.lower().split()
        if not tokens:
            return []

        last_word = tokens[-1]
        candidates = {}

        for bigram, count in self.bigram_counts.items():
            if bigram[0] == last_word:
                prob = count / self.unigram_counts[last_word]
                candidates[bigram[1]] = prob

        sorted_candidates = sorted(candidates.items(), key=lambda x: x[1], reverse=True)
        return sorted_candidates[:top_n]

    def get_probability(self, word, context):
        """Return P(word | context_word)."""
        bigram = (context, word)
        if self.unigram_counts[context] == 0:
            return 0.0
        return self.bigram_counts[bigram] / self.unigram_counts[context]

    def __str__(self):
        return "Bigram Model (2-gram)"


# ══════════════════════════════════════════════════════════════════════
#  ALGORITHM 3: TRIGRAM MODEL (3-gram)
# ══════════════════════════════════════════════════════════════════════
class TrigramModel:
    """
    The Trigram model predicts the next word using the two preceding
    words as context.

    P(w3 | w1, w2) = count(w1, w2, w3) / count(w1, w2)
    """

    def __init__(self):
        self.trigram_counts = defaultdict(int)
        self.bigram_counts = defaultdict(int)

    def train(self, sentences):
        """Train the trigram model."""
        for sentence in sentences:
            for i in range(len(sentence) - 2):
                trigram = (sentence[i], sentence[i + 1], sentence[i + 2])
                self.trigram_counts[trigram] += 1
                self.bigram_counts[(sentence[i], sentence[i + 1])] += 1

    def predict(self, input_text, top_n=5):
        """Predict the next word given the last two words of input_text."""
        tokens = input_text.lower().split()
        if len(tokens) < 2:
            return []

        context = (tokens[-2], tokens[-1])
        candidates = {}

        for trigram, count in self.trigram_counts.items():
            if (trigram[0], trigram[1]) == context:
                prob = count / self.bigram_counts[context]
                candidates[trigram[2]] = prob

        sorted_candidates = sorted(candidates.items(), key=lambda x: x[1], reverse=True)
        return sorted_candidates[:top_n]

    def get_probability(self, word, context):
        """Return P(word | context_pair)."""
        trigram = (context[0], context[1], word)
        if self.bigram_counts[context] == 0:
            return 0.0
        return self.trigram_counts[trigram] / self.bigram_counts[context]

    def __str__(self):
        return "Trigram Model (3-gram)"


# ══════════════════════════════════════════════════════════════════════
#  ALGORITHM 4: FOUR-GRAM MODEL (4-gram)
# ══════════════════════════════════════════════════════════════════════
class FourgramModel:
    """
    The Four-gram model predicts the next word using the three preceding
    words as context.

    P(w4 | w1, w2, w3) = count(w1, w2, w3, w4) / count(w1, w2, w3)
    """

    def __init__(self):
        self.fourgram_counts = defaultdict(int)
        self.trigram_counts = defaultdict(int)

    def train(self, sentences):
        """Train the 4-gram model."""
        for sentence in sentences:
            for i in range(len(sentence) - 3):
                fourgram = (sentence[i], sentence[i + 1], sentence[i + 2], sentence[i + 3])
                self.fourgram_counts[fourgram] += 1
                self.trigram_counts[(sentence[i], sentence[i + 1], sentence[i + 2])] += 1

    def predict(self, input_text, top_n=5):
        """Predict the next word given the last three words of input_text."""
        tokens = input_text.lower().split()
        if len(tokens) < 3:
            return []

        context = (tokens[-3], tokens[-2], tokens[-1])
        candidates = {}

        for fourgram, count in self.fourgram_counts.items():
            if (fourgram[0], fourgram[1], fourgram[2]) == context:
                prob = count / self.trigram_counts[context]
                candidates[fourgram[3]] = prob

        sorted_candidates = sorted(candidates.items(), key=lambda x: x[1], reverse=True)
        return sorted_candidates[:top_n]

    def get_probability(self, word, context):
        """Return P(word | context_triple)."""
        fourgram = (context[0], context[1], context[2], word)
        if self.trigram_counts[context] == 0:
            return 0.0
        return self.fourgram_counts[fourgram] / self.trigram_counts[context]

    def __str__(self):
        return "Four-gram Model (4-gram)"


# ══════════════════════════════════════════════════════════════════════
#  ALGORITHM 5: FIVE-GRAM MODEL (5-gram)
# ══════════════════════════════════════════════════════════════════════
class FivegramModel:
    """
    The Five-gram model predicts the next word using the four preceding
    words as context.

    P(w5 | w1, w2, w3, w4) = count(w1, w2, w3, w4, w5) / count(w1, w2, w3, w4)
    """

    def __init__(self):
        self.fivegram_counts = defaultdict(int)
        self.fourgram_counts = defaultdict(int)

    def train(self, sentences):
        """Train the 5-gram model."""
        for sentence in sentences:
            for i in range(len(sentence) - 4):
                fivegram = (sentence[i], sentence[i + 1], sentence[i + 2],
                            sentence[i + 3], sentence[i + 4])
                self.fivegram_counts[fivegram] += 1
                self.fourgram_counts[(sentence[i], sentence[i + 1],
                                      sentence[i + 2], sentence[i + 3])] += 1

    def predict(self, input_text, top_n=5):
        """Predict the next word given the last four words of input_text."""
        tokens = input_text.lower().split()
        if len(tokens) < 4:
            return []

        context = (tokens[-4], tokens[-3], tokens[-2], tokens[-1])
        candidates = {}

        for fivegram, count in self.fivegram_counts.items():
            if (fivegram[0], fivegram[1], fivegram[2], fivegram[3]) == context:
                prob = count / self.fourgram_counts[context]
                candidates[fivegram[4]] = prob

        sorted_candidates = sorted(candidates.items(), key=lambda x: x[1], reverse=True)
        return sorted_candidates[:top_n]

    def get_probability(self, word, context):
        """Return P(word | context_quad)."""
        fivegram = (context[0], context[1], context[2], context[3], word)
        if self.fourgram_counts[context] == 0:
            return 0.0
        return self.fivegram_counts[fivegram] / self.fourgram_counts[context]

    def __str__(self):
        return "Five-gram Model (5-gram)"


# ══════════════════════════════════════════════════════════════════════
#  EVALUATION METRICS
# ══════════════════════════════════════════════════════════════════════
def calculate_perplexity(model, test_sentences, n):
    """
    Calculate perplexity of an n-gram model on test data.
    Perplexity = 2^(-1/N * sum(log2(P(wi | context))))
    Lower perplexity = better model.
    """
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
                log_prob_sum += -20  # penalty for zero probability

            word_count += 1

    if word_count == 0:
        return float('inf')

    avg_log_prob = log_prob_sum / word_count
    perplexity = 2 ** (-avg_log_prob)
    return perplexity


# ══════════════════════════════════════════════════════════════════════
#  DISPLAY UTILITIES
# ══════════════════════════════════════════════════════════════════════
def print_header():
    """Print the program header."""
    print("=" * 70)
    print("   N-GRAM LANGUAGE MODEL FOR NEXT WORD PREDICTION")
    print("   Student: Hasin Ishrak Labib | ID: 240118")
    print("=" * 70)
    print()


def print_separator():
    print("-" * 70)


def display_predictions(model_name, predictions):
    """Display predictions from a model in a formatted table."""
    if not predictions:
        print(f"  {model_name}: <No prediction available>")
        return

    print(f"\n  ┌─ {model_name}")
    print(f"  │  {'Rank':<6} {'Predicted Word':<25} {'Probability':<15}")
    print(f"  │  {'─' * 6} {'─' * 25} {'─' * 15}")
    for rank, (word, prob) in enumerate(predictions, 1):
        print(f"  │  {rank:<6} {word:<25} {prob:.6f}")
    print(f"  └{'─' * 55}")


# ══════════════════════════════════════════════════════════════════════
#  MAIN PROGRAM
# ══════════════════════════════════════════════════════════════════════
def main():
    print_header()

    # Step 1: Load corpus
    print("[1/3] Loading NLTK Brown Corpus...")
    brown = download_nltk_data()
    sentences = prepare_data(brown)
    total_words = sum(len(s) for s in sentences)
    print(f"      ✓ Loaded {len(sentences):,} sentences, {total_words:,} words\n")

    # Step 2: Train all models
    print("[2/3] Training all 5 N-Gram models...")

    models = [
        (UnigramModel(), 1),
        (BigramModel(), 2),
        (TrigramModel(), 3),
        (FourgramModel(), 4),
        (FivegramModel(), 5),
    ]

    for model, n in models:
        start = time.time()
        model.train(sentences)
        elapsed = time.time() - start
        print(f"      ✓ {str(model):<30} trained in {elapsed:.2f}s")

    print()

    # Step 3: Evaluate models (using last 10% of sentences as test)
    print("[3/3] Evaluating models (perplexity on test set)...")
    split_idx = int(len(sentences) * 0.9)
    test_sentences = sentences[split_idx:]

    print(f"      Training set: {split_idx:,} sentences")
    print(f"      Test set:     {len(test_sentences):,} sentences\n")

    for model, n in models:
        pp = calculate_perplexity(model, test_sentences, n)
        print(f"      {str(model):<30} Perplexity: {pp:,.2f}")

    print()
    print_separator()
    print("  All models trained and ready! Enter text to get predictions.")
    print("  Type 'quit' or 'exit' to stop.")
    print_separator()
    print()

    # Interactive prediction loop
    while True:
        try:
            user_input = input(">>> Enter text: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye!")
            break

        if not user_input:
            continue
        if user_input.lower() in ("quit", "exit"):
            print("Goodbye!")
            break

        print_separator()
        print(f"  Input: \"{user_input}\"")
        print_separator()

        for model, n in models:
            predictions = model.predict(user_input, top_n=5)
            display_predictions(str(model), predictions)

        print()


if __name__ == "__main__":
    main()
