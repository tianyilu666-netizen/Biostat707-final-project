# BIOSTAT 707 Final Project Proposal

## Title

**Does Model Complexity Improve Breast Mass Classification? A Comparison of Discrimination, Calibration, and Decision Thresholds**

**Team:** Tianyi Lu, Haiyi Xiong, Yan Yan, Wenqing Zhao, Asher Xu

## 1. Research question and intended application

We will investigate whether nonlinear classifiers improve prediction of malignant versus benign breast masses compared with logistic regression, and whether any improvement in discrimination is accompanied by reliable probability estimates and fewer false negatives at a common sensitivity target. Our emphasis is a fair, reproducible comparison rather than maximizing a single accuracy score.

The intended application is an educational prototype for supporting review of a breast mass after fine-needle aspiration (FNA) and extraction of image-derived nuclear features. A predicted malignancy probability could hypothetically help prioritize cases for prompt specialist review. It does not predict future cancer onset and is not a population screening tool. This project will not establish clinical utility or support deployment.

Our primary question is whether additional model complexity improves AUROC. Secondary questions concern calibration, sensitivity–specificity tradeoffs, and stability of feature interpretation. We will not infer causal effects from predictive associations.

## 2. Dataset, license, and completed feasibility check

We will use the [Breast Cancer Wisconsin (Diagnostic) dataset from UCI](https://archive.ics.uci.edu/dataset/17/breast+cancer+wisconsin+diagnostic), distributed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). This permits public redistribution and adaptation with attribution. We will retain attribution, link the license, and identify modifications in the repository and report.

The original UCI archive has already been downloaded, extracted, and read during proposal preparation. Direct inspection of `wdbc.data` confirmed:

| Item | Verified result |
|---|---|
| Records | 569 |
| Outcome labels | 212 malignant; 357 benign |
| Predictors | 30 numeric features |
| Columns | ID, diagnosis, and 30 predictors |
| Missing predictor cells | 0 |
| Invalid/nonfinite numeric predictor cells | 0 |
| Unique record IDs | 569 |
| Exact duplicate rows | 0 |

The predictors summarize ten nuclear characteristics using their mean, standard error, and “worst” values. We will retain all records with valid labels and features; the initial check identified no exclusions. Malignancy will be coded as 1 and benign status as 0. ID will be used only for tracking predictions, never as a predictor. A unique record ID does not independently prove that every record is from a distinct patient; we will document this limitation.

These are cross-sectional diagnostic measurements, not longitudinal observations. No additional data source, protected information, or restricted-access database is required.

## 3. Exploratory analysis and preprocessing

We will describe class balance, predictor distributions, outliers, and correlations, including correlations between summaries of the same nuclear characteristic. Initial file validation has covered the full dataset; outcome-related exploratory analysis and modeling choices will use only the development subset after the split is fixed.

We will not remove plausible extreme measurements solely because they are extreme. There are no observed missing values, so imputation is unnecessary. We will document this explicitly rather than introduce artificial missingness into the main analysis. If a revised source reveals missing values, median imputation will be fitted exclusively within the training folds.

Logistic regression and SVM pipelines will standardize features using training-fold means and standard deviations. Tree models will use the original numeric scale. Any later feature selection must occur inside training folds. We will not use oversampling in the primary analysis; sensitivity will instead be examined through training-selected decision thresholds.

## 4. Models and simple baseline

All candidate models will use the same 30 predictors and the same development/test split and cross-validation folds.

| Owner | Model(s) | Planned implementation and tuning | Purpose |
|---|---|---|---|
| Tianyi Lu | Constant-probability baseline | Predict the training-set malignancy proportion | Check improvement over a model without patient-specific predictors |
| Haiyi Xiong | Unpenalized logistic regression; Elastic Net logistic regression | Use scikit-learn pipelines; tune Elastic Net `C` in {0.01, 0.1, 1, 10} and `l1_ratio` in {0.1, 0.5, 0.9, 1.0} | Compare an interpretable linear model with regularized estimation |
| Yan Yan | Random forest | Fix 500 trees; assess 16 combinations of `max_depth` in {3, None}, `min_samples_leaf` in {1, 3, 5, 10}, and `max_features` in {sqrt, 0.5} | Assess nonlinear effects and interactions through bagged trees |
| Wenqing Zhao | Histogram gradient boosting | Assess 16 combinations of `learning_rate` in {0.03, 0.1}, `max_leaf_nodes` in {7, 15}, `min_samples_leaf` in {10, 20}, and `l2_regularization` in {0, 1}; fix 200 iterations and disable early stopping | Compare a second tree ensemble with a different learning mechanism |
| Asher Xu | Linear-kernel SVM; RBF-kernel SVM | Linear: `C` in {0.01, 0.1, 1, 10}; RBF: cross these values with `gamma` in {0.001, 0.01, 0.1, 1} | Test whether a nonlinear margin improves on a linear margin |

For SVM probability estimates, we will use three-fold sigmoid calibration within each model-fitting training subset. During tuning, calibration will not see the fold used to evaluate that candidate. We will not apply a calibration step using the final test labels.

Unpenalized logistic regression may be unstable if classes are separable. We will record convergence and coefficient behavior. If convergence remains inadequate after increasing the iteration limit, it will be reported as an unstable comparator and replaced for probability comparisons by a prespecified ridge logistic model (`C=1`). Elastic Net remains the required regularized model regardless of this contingency. We will describe the actual final model list transparently.

## 5. Validation design and leakage prevention

1. **Reserve a test set:** create one stratified 80% development / 20% test split with random seed 707. Save record IDs and split membership before modeling. The test set will remain unavailable for exploratory model choices, tuning, threshold selection, or recalibration.
2. **Tune on development data:** use identical stratified five-fold cross-validation folds for every model. Select hyperparameters by mean validation AUROC. Every transformation and SVM calibration step will be fitted within the relevant training subset. The grids above cap the main searches at 16 configurations per tuned model variant; runtime will also be reported.
3. **Choose thresholds without test labels:** after selecting hyperparameters, generate development out-of-fold probabilities. For each model, select the highest threshold achieving at least 95% sensitivity on those predictions. This is a prespecified exploratory sensitivity target, not an established clinical standard or a guarantee of future sensitivity. These post-tuning development results will be used for threshold selection, not presented as unbiased final performance estimates.
4. **Fit and evaluate once:** fit each locked model on the full development subset and apply its fixed threshold to test predictions. Evaluate all prespecified models in one final comparison. Identify the preferred model using development results before opening test outcomes; do not revise models to improve test rankings.

Record-level stratification is appropriate for the available cross-sectional structure, subject to the unresolved patient-identity limitation. This dataset does not support temporal or hospital-level external validation.

## 6. Final evaluation and interpretation

**Primary metric:** test-set AUROC. We will report paired differences between nonlinear models and the stable full-feature logistic comparator, rather than focus solely on a leaderboard.

**Secondary metrics:** AUPRC, Brier score, log loss, and a calibration plot using approximately five equal-frequency bins. We will also report mean predicted versus observed malignancy frequency. The constant-probability baseline will be evaluated using the same appropriate probability metrics.

**Threshold evaluation:** at each training-selected sensitivity threshold, report the test confusion matrix, sensitivity, specificity, positive predictive value, and negative predictive value. We will report the achieved test sensitivity even if it falls below 95%. A threshold of 0.5 will be a secondary reference. We will discuss false negatives as missed malignant cases and false positives as potentially unnecessary escalations, without assigning unsupported clinical costs.

**Uncertainty:** use 2,000 paired, class-stratified bootstrap resamples of the held-out records for approximate 95% confidence intervals for AUROC, Brier score, and their model differences. Pairing preserves comparisons on the same records. These intervals condition on the fitted models and the chosen split; they do not capture full training or model-selection variability. We will also report test denominators because the test set is small.

**Interpretability:** examine standardized logistic coefficients and permutation importance on development validation predictions, not on the final test set for feature selection. Compare consistency of broad feature families, recognizing that correlated predictors can redistribute apparent importance. Each model owner will prepare their own interpretation; the team will synthesize agreements and disagreements.

We will interpret small or uncertain differences cautiously and discuss performance alongside calibration, complexity, runtime, and interpretability. The study is not powered or designed to establish equivalence or noninferiority.

## 7. Detailed division of responsibilities

### Tianyi Lu — Data preparation and final evaluation

**Analysis:** maintain the source download script and data dictionary; verify coding, IDs, numerical validity, and exclusions; create development/test identifiers and shared folds; prepare development-set descriptive summaries; implement shared metric functions and the constant baseline. After models and thresholds are locked, run or coordinate the single final test evaluation and assemble the comparison tables and plots.

**Application and follow-up:** explain what the dataset represents, translate confusion matrices into missed malignant cases and unnecessary escalations, and document the limits of applying the models to a different setting. Write the data/cohort and common evaluation sections.

**Boundary:** this member will not tune, repair, or write the methods for all other models. Model owners must submit tested code and standardized outputs.

### Haiyi Xiong — Logistic regression and Elastic Net

**Analysis:** implement scaling pipelines, fit both regression variants, complete the specified search, diagnose convergence/separation, generate development out-of-fold probabilities and a locked threshold, and provide final fitted models. Examine coefficient direction and stability across development folds.

**Application and follow-up:** assess whether a relatively interpretable probability model is sufficient for the proposed review-prioritization setting; discuss how regularization changes stability, calibration, and errors. Write this model group's methods, results, and limitations.

### Yan Yan — Random forest

**Analysis:** implement and tune the forest, inspect training–validation gaps, summarize the effect of leaf size and depth, generate development out-of-fold probabilities and a locked threshold, and provide final fitted models. Prepare development-based permutation importance and runtime summaries.

**Application and follow-up:** examine whether capturing interactions reduces false negatives or unnecessary escalations relative to the linear comparator, and whether probability reliability offsets any discrimination gain. Write the forest's methods, results, and limitations.

### Wenqing Zhao — Gradient boosting

**Analysis:** implement the specified boosting search, assess overfitting and model complexity, generate development out-of-fold probabilities and a locked threshold, and provide final fitted models. Compare development-based feature-family importance with regression and forest findings.

**Application and follow-up:** evaluate whether boosting offers a useful sensitivity–specificity tradeoff at the prespecified operating target, while accounting for calibration and additional tuning complexity. Write the boosting methods, results, and limitations.

### Asher Xu — Linear and RBF SVM

**Analysis:** implement scaling and training-only probability calibration, tune both kernels, compare their development performance and runtime, generate out-of-fold probabilities and locked thresholds, and provide final fitted models. Verify that all probability fitting remains inside the training pipeline.

**Application and follow-up:** assess whether a nonlinear margin improves case prioritization sufficiently to justify reduced interpretability and probability-calibration complexity. Write the SVM methods, results, and limitations.

### Shared deliverables and workload control

Each model owner will independently run the common evaluation functions and submit executable training code, selected settings, runtime, development out-of-fold predictions, fixed thresholds, and model-specific interpretation. Prediction tables will contain record ID, true label where authorized, model name, fold identifier when applicable, and predicted probability. Tianyi Lu will verify and combine outputs rather than redo modeling work.

All five members will write and present their own sections, review another member's code, and jointly write the discussion and conclusions. More extensive data/evaluation work is balanced against Tianyi Lu having no complex model search. The team will review effort after the first working pipeline and redistribute supporting documentation or plotting tasks if needed.

## 8. Expected findings and limitations

We hypothesize that linear or regularized models may already discriminate well, leaving limited gains for more complex classifiers. Nonlinear methods might improve discrimination without improving calibration, and the model with the largest AUROC may not offer the best operating-point tradeoff. These are hypotheses, not results; no predictive model has been fitted for this proposal.

Limitations include the small historical dataset, correlated predictors, limited test precision, incomplete information for verifying patient independence, and no independent contemporary validation cohort. Available fields do not support a meaningful demographic fairness audit. We cannot estimate treatment benefit, prospective workflow effects, or performance in a screening population. A real application would require external validation, clinically justified thresholds, and prospective evaluation.

## 9. Reproducibility and submission

We will create one new GitHub repository for this final project, add all five members as collaborators, and add the instructor and teaching assistants if it is private. Each member will commit from their own account and submit an individual contribution statement. This proposal will be placed at the repository root as `707-proposal.md`, and the repository URL will be submitted in Canvas.

The repository will contain the original-source download script, README with attribution and license, data checks, saved split/fold identifiers, model pipelines, evaluation code, figures, and a versioned environment file. The small data files may be included with the required attribution; the download script will be retained regardless. Fixed seeds and shared configurations will allow the analysis to be rerun from the source data. Repository creation and Canvas submission remain team actions; they have not been performed during proposal preparation.

## References

Wolberg, W., Mangasarian, O., Street, N., & Street, W. (1993). *Breast Cancer Wisconsin (Diagnostic)* [Dataset]. UCI Machine Learning Repository. [https://doi.org/10.24432/C5DW2B](https://doi.org/10.24432/C5DW2B).

UCI Machine Learning Repository. *Breast Cancer Wisconsin (Diagnostic): dataset page and accompanying `wdbc.names` documentation.* [Dataset and download](https://archive.ics.uci.edu/dataset/17/breast+cancer+wisconsin+diagnostic).

Creative Commons. *Attribution 4.0 International.* [License](https://creativecommons.org/licenses/by/4.0/).

