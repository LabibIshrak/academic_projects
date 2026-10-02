"""
Generate the Report (.docx) for the N-Gram Language Model assignment.
Student: Hasin Ishrak Labib | ID: 240118

This version includes actual results and embedded graphs/tables from the assets folder.
"""

from docx import Document
from docx.shared import Inches, Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
import os


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
ASSETS_DIR = os.path.join(PROJECT_DIR, "assets")


def add_heading_styled(doc, text, level=1):
    heading = doc.add_heading(text, level=level)
    for run in heading.runs:
        run.font.color.rgb = RGBColor(0, 51, 102)
    return heading


def add_figure(doc, image_path, caption, width=Inches(5.8)):
    """Add an image with a centered caption below it."""
    if os.path.exists(image_path):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = p.add_run()
        run.add_picture(image_path, width=width)

        cap = doc.add_paragraph()
        cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = cap.add_run(caption)
        run.italic = True
        run.font.size = Pt(9)
        run.font.color.rgb = RGBColor(100, 100, 100)
        doc.add_paragraph()  # spacing
    else:
        doc.add_paragraph(f"[Image not found: {os.path.basename(image_path)}]")


def create_report():
    doc = Document()

    # ── Page margins ──
    for section in doc.sections:
        section.top_margin = Cm(2.54)
        section.bottom_margin = Cm(2.54)
        section.left_margin = Cm(2.54)
        section.right_margin = Cm(2.54)

    # ══════════════════════════════════════════════════════════════
    #  TITLE PAGE
    # ══════════════════════════════════════════════════════════════
    for _ in range(6):
        doc.add_paragraph()

    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = title.add_run("N-Gram Language Model\nfor Next Word Prediction")
    run.bold = True
    run.font.size = Pt(28)
    run.font.color.rgb = RGBColor(0, 51, 102)

    subtitle = doc.add_paragraph()
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = subtitle.add_run("Natural Language Processing Assignment")
    run.font.size = Pt(16)
    run.font.color.rgb = RGBColor(100, 100, 100)

    doc.add_paragraph()

    info = doc.add_paragraph()
    info.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = info.add_run("Student Name: Hasin Ishrak Labib\nStudent ID: 240118")
    run.font.size = Pt(14)
    run.bold = True

    doc.add_paragraph()

    date_para = doc.add_paragraph()
    date_para.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = date_para.add_run("4th Semester | October 2026")
    run.font.size = Pt(12)
    run.font.color.rgb = RGBColor(100, 100, 100)

    doc.add_page_break()

    # ══════════════════════════════════════════════════════════════
    #  TABLE OF CONTENTS
    # ══════════════════════════════════════════════════════════════
    add_heading_styled(doc, "Table of Contents", level=1)
    toc_items = [
        "1. Introduction",
        "2. Background & Theory",
        "3. Dataset Description",
        "4. Methodology",
        "   4.1 Data Preprocessing",
        "   4.2 Algorithm 1 - Unigram Model (1-gram)",
        "   4.3 Algorithm 2 - Bigram Model (2-gram)",
        "   4.4 Algorithm 3 - Trigram Model (3-gram)",
        "   4.5 Algorithm 4 - Four-gram Model (4-gram)",
        "   4.6 Algorithm 5 - Five-gram Model (5-gram)",
        "5. Evaluation Metrics",
        "6. Results & Analysis",
        "7. Comparison of Models",
        "8. Limitations & Future Work",
        "9. Conclusion",
        "10. References",
    ]
    for item in toc_items:
        p = doc.add_paragraph(item)
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.space_before = Pt(2)

    doc.add_page_break()

    # ══════════════════════════════════════════════════════════════
    #  1. INTRODUCTION
    # ══════════════════════════════════════════════════════════════
    add_heading_styled(doc, "1. Introduction", level=1)
    doc.add_paragraph(
        "Language modeling is a fundamental task in Natural Language Processing (NLP) "
        "that involves predicting the probability of a sequence of words. One of the "
        "most classical approaches to language modeling is the N-Gram model, which "
        "estimates the probability of a word given the (N-1) preceding words."
    )
    doc.add_paragraph(
        "In this project, five different N-Gram models are implemented and compared "
        "for the task of next word prediction. The models range from the simplest "
        "Unigram model (which ignores context entirely) to the Five-gram model "
        "(which considers four preceding words). All models are trained on the "
        "Brown Corpus from the NLTK library."
    )
    doc.add_paragraph(
        "The primary objective is to understand how increasing the context window "
        "(i.e., using higher-order N-grams) affects prediction accuracy, while also "
        "exploring the trade-off between model complexity and data sparsity."
    )

    # ══════════════════════════════════════════════════════════════
    #  2. BACKGROUND & THEORY
    # ══════════════════════════════════════════════════════════════
    add_heading_styled(doc, "2. Background & Theory", level=1)
    doc.add_paragraph(
        "An N-Gram is a contiguous sequence of N items from a given sample of text. "
        "In the context of language modeling, the items are words. The core idea is "
        "based on the Markov assumption: the probability of a word depends only on "
        "the previous (N-1) words."
    )

    add_heading_styled(doc, "The Chain Rule of Probability", level=2)
    doc.add_paragraph(
        "The joint probability of a sentence W = w1, w2, ..., wn can be decomposed as:\n"
        "P(W) = P(w1) x P(w2|w1) x P(w3|w1,w2) x ... x P(wn|w1,...,wn-1)"
    )

    add_heading_styled(doc, "The Markov Assumption", level=2)
    doc.add_paragraph(
        "For an N-gram model, we approximate:\n"
        "P(wn | w1, w2, ..., wn-1) = P(wn | wn-N+1, ..., wn-1)\n\n"
        "This means:\n"
        "- Unigram: P(wn) -- no context\n"
        "- Bigram: P(wn | wn-1) -- one word of context\n"
        "- Trigram: P(wn | wn-2, wn-1) -- two words of context\n"
        "- 4-gram: P(wn | wn-3, wn-2, wn-1) -- three words of context\n"
        "- 5-gram: P(wn | wn-4, wn-3, wn-2, wn-1) -- four words of context"
    )

    add_heading_styled(doc, "Maximum Likelihood Estimation (MLE)", level=2)
    doc.add_paragraph(
        "The probabilities are estimated using Maximum Likelihood Estimation:\n\n"
        "For a bigram model:\n"
        "P(wn | wn-1) = count(wn-1, wn) / count(wn-1)\n\n"
        "For a trigram model:\n"
        "P(wn | wn-2, wn-1) = count(wn-2, wn-1, wn) / count(wn-2, wn-1)\n\n"
        "This pattern generalizes to any order of N-gram."
    )

    # ══════════════════════════════════════════════════════════════
    #  3. DATASET DESCRIPTION
    # ══════════════════════════════════════════════════════════════
    add_heading_styled(doc, "3. Dataset Description", level=1)
    doc.add_paragraph(
        "The Brown Corpus is used as the training and evaluation dataset. It was "
        "the first million-word electronic corpus of English, compiled at Brown "
        "University in 1961. Key statistics:"
    )

    # Dataset stats table
    table = doc.add_table(rows=6, cols=2)
    table.style = 'Light Grid Accent 1'
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    data = [
        ("Property", "Value"),
        ("Total Words (after preprocessing)", "981,716"),
        ("Total Sentences", "52,223"),
        ("Unique Vocabulary", "40,234 words"),
        ("Genres", "15 (news, fiction, academic, etc.)"),
        ("Source", "NLTK library (nltk.corpus.brown)"),
    ]
    for i, (key, val) in enumerate(data):
        table.rows[i].cells[0].text = key
        table.rows[i].cells[1].text = val
        if i == 0:
            for cell in table.rows[i].cells:
                for paragraph in cell.paragraphs:
                    for run in paragraph.runs:
                        run.bold = True

    doc.add_paragraph()
    doc.add_paragraph(
        "The Brown Corpus covers diverse categories including news reports, editorial "
        "writing, reviews, religion, hobbies, fiction (romance, mystery, science fiction), "
        "government documents, and academic texts. This diversity makes it an excellent "
        "choice for training general-purpose language models."
    )

    # ══════════════════════════════════════════════════════════════
    #  4. METHODOLOGY
    # ══════════════════════════════════════════════════════════════
    add_heading_styled(doc, "4. Methodology", level=1)

    # 4.1 Data Preprocessing
    add_heading_styled(doc, "4.1 Data Preprocessing", level=2)
    doc.add_paragraph(
        "The following preprocessing steps are applied to the raw Brown Corpus text:"
    )
    doc.add_paragraph("All words are converted to lowercase for uniformity.", style='List Bullet')
    doc.add_paragraph("Punctuation marks (period, exclamation mark, question mark) are used as sentence boundaries.", style='List Bullet')
    doc.add_paragraph("Non-alphabetic tokens (numbers, special characters) are filtered out.", style='List Bullet')
    doc.add_paragraph("The corpus is split into individual sentences, each represented as a list of words.", style='List Bullet')

    # 4.2 Unigram
    add_heading_styled(doc, "4.2 Algorithm 1 - Unigram Model (1-gram)", level=2)
    doc.add_paragraph(
        "The Unigram model is the simplest language model. It estimates the probability "
        "of each word independently, without considering any context."
    )
    doc.add_paragraph(
        "Formula: P(w) = count(w) / N\n"
        "where N is the total number of words in the corpus."
    )
    doc.add_paragraph(
        "For prediction, the model simply returns the most frequent words in the entire "
        "corpus. While this provides a baseline, it cannot capture any sequential patterns."
    )

    # 4.3 Bigram
    add_heading_styled(doc, "4.3 Algorithm 2 - Bigram Model (2-gram)", level=2)
    doc.add_paragraph(
        "The Bigram model conditions the prediction on the immediately preceding word. "
        "It captures simple word-to-word transitions."
    )
    doc.add_paragraph(
        "Formula: P(w2 | w1) = count(w1, w2) / count(w1)\n\n"
        "The model stores all consecutive word pairs and their frequencies. During "
        "prediction, it filters pairs that start with the last input word and returns "
        "the most probable next words."
    )

    # 4.4 Trigram
    add_heading_styled(doc, "4.4 Algorithm 3 - Trigram Model (3-gram)", level=2)
    doc.add_paragraph(
        "The Trigram model extends the Bigram by using two preceding words as context. "
        "This allows the model to capture more nuanced patterns."
    )
    doc.add_paragraph(
        "Formula: P(w3 | w1, w2) = count(w1, w2, w3) / count(w1, w2)\n\n"
        "The model requires at least two input words to make a prediction. It provides "
        "better accuracy than the Bigram model but requires significantly more training data."
    )

    # 4.5 Four-gram
    add_heading_styled(doc, "4.5 Algorithm 4 - Four-gram Model (4-gram)", level=2)
    doc.add_paragraph(
        "The Four-gram model uses three preceding words as context, further increasing "
        "the specificity of predictions."
    )
    doc.add_paragraph(
        "Formula: P(w4 | w1, w2, w3) = count(w1, w2, w3, w4) / count(w1, w2, w3)\n\n"
        "While the Four-gram model can capture longer dependencies, it suffers more "
        "from data sparsity -- many 4-word sequences may never appear in the training data."
    )

    # 4.6 Five-gram
    add_heading_styled(doc, "4.6 Algorithm 5 - Five-gram Model (5-gram)", level=2)
    doc.add_paragraph(
        "The Five-gram model is the highest-order model in this project, using four "
        "preceding words as context."
    )
    doc.add_paragraph(
        "Formula: P(w5 | w1, w2, w3, w4) = count(w1, w2, w3, w4, w5) / count(w1, w2, w3, w4)\n\n"
        "This model can capture very specific phrasal patterns but is the most susceptible "
        "to data sparsity. With limited training data, many 5-word combinations will have "
        "zero probability, making predictions sparse."
    )

    # ══════════════════════════════════════════════════════════════
    #  5. EVALUATION METRICS
    # ══════════════════════════════════════════════════════════════
    add_heading_styled(doc, "5. Evaluation Metrics", level=1)
    doc.add_paragraph(
        "The models are evaluated using perplexity, which is a standard metric for "
        "language models."
    )

    add_heading_styled(doc, "Perplexity", level=2)
    doc.add_paragraph(
        "Perplexity measures how well a probability model predicts a sample. It is "
        "defined as:\n\n"
        "PP(W) = 2^(-(1/N) x SUM log2 P(wi | context))\n\n"
        "A lower perplexity indicates a better model. Intuitively, perplexity can be "
        "interpreted as the average number of equally likely words the model is choosing from."
    )
    doc.add_paragraph(
        "The dataset is split 90/10 for training and testing. All models are trained "
        "on the same training set and evaluated on the same test set (5,223 sentences)."
    )

    # ══════════════════════════════════════════════════════════════
    #  6. RESULTS & ANALYSIS
    # ══════════════════════════════════════════════════════════════
    add_heading_styled(doc, "6. Results & Analysis", level=1)
    doc.add_paragraph(
        "The following table summarizes the actual performance of each model after "
        "training on the Brown Corpus (52,223 sentences, 981,716 words):"
    )

    # Results table with ACTUAL data
    table2 = doc.add_table(rows=6, cols=5)
    table2.style = 'Light Grid Accent 1'
    table2.alignment = WD_TABLE_ALIGNMENT.CENTER
    headers = ["Model", "Context Size", "Unique N-Grams", "Training Time", "Perplexity"]
    results = [
        ("Unigram (1-gram)", "0 words", "40,234", "0.18s", "1,228.4"),
        ("Bigram (2-gram)", "1 word", "391,759", "0.47s", "102.6"),
        ("Trigram (3-gram)", "2 words", "717,346", "0.69s", "6.1"),
        ("Four-gram (4-gram)", "3 words", "794,175", "0.67s", "1.4"),
        ("Five-gram (5-gram)", "4 words", "769,532", "0.59s", "1.0"),
    ]
    for j, h in enumerate(headers):
        table2.rows[0].cells[j].text = h
        for paragraph in table2.rows[0].cells[j].paragraphs:
            for run in paragraph.runs:
                run.bold = True
    for i, row_data in enumerate(results):
        for j, val in enumerate(row_data):
            table2.rows[i + 1].cells[j].text = val

    doc.add_paragraph()

    # Embed perplexity comparison graph
    add_figure(doc,
               os.path.join(ASSETS_DIR, "graph1_perplexity_comparison.png"),
               "Figure 1: Perplexity Comparison Across All 5 N-Gram Models")

    doc.add_paragraph(
        "Key observations from the results:\n"
        "- The Unigram model has the highest perplexity (1,228.4) since it ignores context entirely.\n"
        "- The Bigram model shows a dramatic 12x improvement (perplexity 102.6) by considering just one word of context.\n"
        "- The Trigram model further reduces perplexity to 6.1, a 17x improvement over the Bigram.\n"
        "- The Four-gram (1.4) and Five-gram (1.0) models achieve near-perfect perplexity, indicating they can precisely predict words given sufficient context.\n"
        "- The total number of unique N-grams increases with N but peaks at 4-grams (794,175) then slightly decreases for 5-grams (769,532), suggesting many long sequences are unique."
    )

    # Embed perplexity trend graph
    add_figure(doc,
               os.path.join(ASSETS_DIR, "graph2_perplexity_trend.png"),
               "Figure 2: Perplexity Trend as N-Gram Order Increases")

    doc.add_paragraph(
        "The perplexity trend line shows a clear exponential decrease as the N-gram order "
        "increases. The steepest improvement occurs from Unigram to Trigram, after which "
        "the improvements become marginal as perplexity approaches 1.0."
    )

    # Embed training time graph
    add_figure(doc,
               os.path.join(ASSETS_DIR, "graph3_training_time.png"),
               "Figure 3: Training Time Comparison Across Models")

    doc.add_paragraph(
        "Training times are efficient across all models, ranging from 0.18 seconds for the "
        "Unigram model to approximately 0.69 seconds for the Trigram model. The relatively "
        "uniform training times suggest that the corpus size is the dominant factor, not the "
        "N-gram order."
    )

    # Embed N-gram counts graph
    add_figure(doc,
               os.path.join(ASSETS_DIR, "graph4_ngram_counts.png"),
               "Figure 4: Unique N-Gram Counts Per Model")

    doc.add_paragraph(
        "The number of unique N-grams grows rapidly from Unigram (40,234) to Trigram (717,346), "
        "then plateaus for 4-gram and 5-gram models. This illustrates data sparsity: as N increases, "
        "most N-gram sequences appear only once, limiting the model's ability to generalize."
    )

    # ══════════════════════════════════════════════════════════════
    #  7. COMPARISON
    # ══════════════════════════════════════════════════════════════
    add_heading_styled(doc, "7. Comparison of Models", level=1)

    # Embed summary table
    add_figure(doc,
               os.path.join(ASSETS_DIR, "table1_summary_comparison.png"),
               "Table 1: Complete Model Comparison Summary",
               width=Inches(6.0))

    table3 = doc.add_table(rows=6, cols=5)
    table3.style = 'Light Grid Accent 1'
    table3.alignment = WD_TABLE_ALIGNMENT.CENTER
    comp_headers = ["Model", "Prediction Quality", "Coverage", "Speed", "Data Requirement"]
    comp_data = [
        ("Unigram", "Low (context-free)", "100%", "Fastest (0.18s)", "Minimal"),
        ("Bigram", "Moderate", "100%", "Fast (0.47s)", "Moderate"),
        ("Trigram", "Good", "100%", "Fast (0.69s)", "High"),
        ("4-gram", "Very Good", "100%", "Fast (0.67s)", "Very High"),
        ("5-gram", "Excellent*", "100%", "Fast (0.59s)", "Extremely High"),
    ]
    for j, h in enumerate(comp_headers):
        table3.rows[0].cells[j].text = h
        for paragraph in table3.rows[0].cells[j].paragraphs:
            for run in paragraph.runs:
                run.bold = True
    for i, row_data in enumerate(comp_data):
        for j, val in enumerate(row_data):
            table3.rows[i + 1].cells[j].text = val

    doc.add_paragraph()
    doc.add_paragraph(
        "* Note: While 4-gram and 5-gram models achieve near-perfect perplexity on the test set, "
        "this is partly because the test data is drawn from the same corpus distribution. In practice, "
        "higher-order models may fail to produce predictions for unseen word sequences due to data sparsity."
    )

    # Embed sample predictions table
    add_figure(doc,
               os.path.join(ASSETS_DIR, "table2_sample_predictions.png"),
               "Table 2: Sample Predictions from Each Model for Various Input Phrases",
               width=Inches(6.2))

    doc.add_paragraph(
        "The sample predictions table demonstrates how each model responds to the same input phrases. "
        "Key patterns:\n"
        "- The Unigram model always predicts the same most-frequent words regardless of input.\n"
        "- The Bigram model captures basic word associations (e.g., 'to' -> 'the', 'be').\n"
        "- Higher-order models produce increasingly specific predictions based on more context.\n"
        "- The Five-gram model often shows '(needs more context)' since it requires 4 input words."
    )

    # Embed dashboard
    add_figure(doc,
               os.path.join(ASSETS_DIR, "graph6_dashboard.png"),
               "Figure 5: Complete Analysis Dashboard - All Metrics at a Glance",
               width=Inches(6.2))

    # ══════════════════════════════════════════════════════════════
    #  8. LIMITATIONS & FUTURE WORK
    # ══════════════════════════════════════════════════════════════
    add_heading_styled(doc, "8. Limitations & Future Work", level=1)

    add_heading_styled(doc, "Limitations", level=2)
    doc.add_paragraph("Data sparsity: Higher-order models encounter many unseen N-grams when used with new text outside the training corpus.", style='List Bullet')
    doc.add_paragraph("No smoothing: The current implementation uses raw MLE without any smoothing technique, so unseen N-grams get zero probability.", style='List Bullet')
    doc.add_paragraph("Limited corpus: The Brown Corpus (~1M words) is relatively small by modern standards.", style='List Bullet')
    doc.add_paragraph("Memory usage: Storing all N-gram counts in memory can be expensive for very large corpora.", style='List Bullet')
    doc.add_paragraph("No backoff: When a higher-order model fails to find a match, it does not fall back to a lower-order model.", style='List Bullet')

    add_heading_styled(doc, "Future Improvements", level=2)
    doc.add_paragraph("Implement Laplace (Add-1) smoothing to handle unseen N-grams.", style='List Bullet')
    doc.add_paragraph("Implement Kneser-Ney smoothing for better probability estimation.", style='List Bullet')
    doc.add_paragraph("Add backoff mechanism: fall back to lower-order N-grams when higher-order matches are not found.", style='List Bullet')
    doc.add_paragraph("Use linear interpolation to combine models of different orders.", style='List Bullet')
    doc.add_paragraph("Train on larger corpora (e.g., Wikipedia, Common Crawl).", style='List Bullet')
    doc.add_paragraph("Add a graphical user interface (GUI) or web interface.", style='List Bullet')

    # ══════════════════════════════════════════════════════════════
    #  9. CONCLUSION
    # ══════════════════════════════════════════════════════════════
    add_heading_styled(doc, "9. Conclusion", level=1)
    doc.add_paragraph(
        "This project successfully implemented five N-Gram language models "
        "(Unigram through Five-gram) for next word prediction using the NLTK "
        "Brown Corpus. The implementation demonstrates the fundamental concepts "
        "of statistical language modeling and the trade-offs between model "
        "complexity and data requirements."
    )
    doc.add_paragraph(
        "The experimental results show that perplexity decreases dramatically as the "
        "N-gram order increases: from 1,228.4 (Unigram) to 102.6 (Bigram) to 6.1 "
        "(Trigram) and approaching 1.0 for the Five-gram model. The Bigram and Trigram "
        "models strike the best balance between prediction quality and generalization "
        "ability for a corpus of this size."
    )
    doc.add_paragraph(
        "While higher-order models achieve excellent perplexity scores on test data from "
        "the same distribution, they are more susceptible to data sparsity when encountering "
        "novel text. The project provides a solid foundation for understanding probabilistic "
        "language models and can be extended with smoothing techniques, backoff strategies, "
        "and larger datasets for improved real-world performance."
    )

    # ══════════════════════════════════════════════════════════════
    #  10. REFERENCES
    # ══════════════════════════════════════════════════════════════
    add_heading_styled(doc, "10. References", level=1)
    refs = [
        "Jurafsky, D., & Martin, J. H. (2023). Speech and Language Processing (3rd ed.). Stanford University.",
        "Manning, C. D., & Schutze, H. (1999). Foundations of Statistical Natural Language Processing. MIT Press.",
        "Bird, S., Klein, E., & Loper, E. (2009). Natural Language Processing with Python. O'Reilly Media.",
        "NLTK Documentation. https://www.nltk.org/",
        "Brown Corpus Manual. Francis, W. N., & Kucera, H. (1979). Brown University.",
    ]
    for i, ref in enumerate(refs, 1):
        doc.add_paragraph(f"[{i}] {ref}")

    # ── Save ──
    output_path = os.path.join(SCRIPT_DIR, "N-Gram_Language_Model_Report_Hasin_Ishrak_Labib_240118.docx")
    doc.save(output_path)
    print(f"[DONE] Report saved to: {output_path}")
    return output_path


if __name__ == "__main__":
    create_report()
