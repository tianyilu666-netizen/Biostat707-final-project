# BIOSTAT 707 Final Project

## Breast Mass Classification Model Comparison

We will compare logistic regression, regularized logistic regression, random forest, decision tree, and support vector machines for classifying breast masses as malignant or benign. The analysis will evaluate discrimination, probability calibration, and sensitivity–specificity tradeoffs using a common validation design.

The intended application is an educational investigation of classification after fine-needle aspiration and extraction of nuclear image features. The project does not predict future cancer onset, establish clinical utility, or provide a tool for clinical deployment.

## Team and responsibilities

| Team member | Primary responsibility |
|---|---|
| Tianyi Lu | Data preparation, shared splits, constant-probability baseline, and final evaluation |
| Haiyi Xiong | Logistic regression and Elastic Net logistic regression |
| Yan Yan | Random forest |
| Wenqing Zhao | Decision tree |
| Asher Xu | Linear-kernel and RBF-kernel SVM |

Each model owner will implement training and tuning, produce standardized prediction outputs, interpret their model, and write the corresponding report section. All members will contribute to code review, discussion, and presentation. Each member will commit their own work from their own GitHub account and submit an individual contribution statement as required by the course.

### Wenqing Zhao: Planned decision tree analysis

The decision tree will be tuned using the shared stratified five-fold cross-validation folds. We will test 12 combinations of `max_depth` (`3`, `5`, `7`, `None`) and `min_samples_leaf` (`5`, `10`, `20`), selecting settings by mean validation AUROC. We will check for overfitting, generate development out-of-fold probabilities, and select a fixed threshold targeting at least 95% development sensitivity. We will also examine feature importance and compare the decision tree with other models using discrimination, calibration, sensitivity, and specificity. The final test set will not be used for tuning or threshold selection.


## Proposal

The project proposal is located at the repository root as [707-proposal.md](707-proposal.md). It describes the research question, cohort and outcome, models, validation design, expected findings, and detailed division of responsibilities.

## Data source and license

- **Dataset:** Breast Cancer Wisconsin (Diagnostic), also known as WDBC.
- **Dataset source (UCI Machine Learning Repository):** [Breast Cancer Wisconsin (Diagnostic), DOI: 10.24432/C5DW2B](https://doi.org/10.24432/C5DW2B).
- **License:** Creative Commons. Attribution 4.0 International (CC BY 4.0). https://creativecommons.org/licenses/by/4.0/.

The dataset license permits sharing and adaptation with appropriate credit, a license link, and an indication of modifications. This license applies to the UCI dataset; it does not automatically license our project code.

### Required dataset citation

Wolberg, W., Mangasarian, O., Street, N., & Street, W. (1993). *Breast Cancer Wisconsin (Diagnostic)* [Dataset]. UCI Machine Learning Repository. https://doi.org/10.24432/C5DW2B.

### Dataset structure and initial checks

The original data contain 569 records, with 212 malignant and 357 benign labels, and 30 numeric predictors derived from cell nuclei in digitized fine-needle aspiration images. The original file has no header: column 1 is the record ID, column 2 is the diagnosis (`M` or `B`), and columns 3–32 are predictors. The accompanying `wdbc.names` file explains feature order and definitions.

During proposal preparation, the source archive was downloaded and read. Checks found no missing predictor cells, invalid or nonfinite numeric predictor cells, or exact duplicate rows. There are 569 unique record IDs. These checks establish file-level feasibility, not independent verification of patient identity.

The supplied download script preserves the original `wdbc.data` and `wdbc.names` contents. It additionally creates a separate `data-audit.json` file with validation results and a SHA-256 checksum. Future transformed datasets and any changes will be documented separately. Malignancy will be encoded as 1 and benign status as 0 in analysis; ID will not be a predictor.

## Download and check the original data

Place `download-and-check-data.ps1` at the repository root alongside this README. On Windows, run the following from the repository root in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File ./download-and-check-data.ps1 -Destination ./data/raw
```

The script requires internet access to UCI. It downloads and extracts the source archive, checks the data, and writes `data/raw/data-audit.json`. It does not fit models or create the formal development/test split.

Alternatively, access the UCI dataset through the DOI link above, download the original archive, and extract it into `data/raw/`. The small original data files may also be included in this repository under the dataset license, retaining this attribution and the source documentation. The download script provides access to the original source even when raw data are not committed.

## Repository organization

The proposal-stage files should be arranged as follows. The `data/raw/` directory is generated by the download script or populated by extracting the original archive.

```text
.
|-- 707-proposal.md
|-- README.md
|-- download-and-check-data.ps1
`-- data/
    `-- raw/
        |-- wdbc.zip
        |-- wdbc.data
        |-- wdbc.names
        `-- data-audit.json
```

Model scripts, saved split identifiers, environment specifications, and results will be added as the analysis progresses. Their presence is not implied by this proposal-stage layout. Word translations are for review; the course proposal is the root-level Markdown file.

## Planned analysis and reproducibility

We will reserve a stratified 20% test set and use the remaining 80% for development, with random seed 707 and shared stratified five-fold cross-validation. All preprocessing, tuning, and SVM probability calibration will occur within the relevant training subsets. Test labels will not be used for model selection, threshold selection, or recalibration.

Primary evaluation will use test AUROC. Secondary evaluation will include AUPRC, Brier score, log loss, calibration plots, and classification metrics at development-selected thresholds. A development sensitivity target of 95% is exploratory, not a clinical standard or a guarantee of test sensitivity. The proposal specifies uncertainty estimates and interpretation limits.

Modeling is planned in Python using scikit-learn. Exact package versions, runnable analysis commands, and fixed split identifiers will be recorded when implementation begins. At the proposal stage, data checks have been completed; predictive model performance has not yet been estimated.
