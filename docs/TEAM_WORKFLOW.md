# Team Modeling and Evaluation Workflow Guide

**BIOSTAT 707 Final Project**  
**Author / Data Lead:** Tianyi Lu (`tianyilu666-netizen`)  
**Target Audience:** Haiyi Xiong (Logistic Regression / Elastic Net), Yan Yan (Random Forest), Wenqing Zhao (Decision Tree), Asher Xu (SVM)

---

## 1. Quick Start: Loading Data & Splits

All models must train on the identical split and 5-fold cross-validation folds. Do **not** create your own train/test split or shuffle seeds.

```python
import pandas as pd

# Load clean features and target
df = pd.read_csv("data/processed/wdbc_clean.csv")

# Load unified splits
splits = pd.read_csv("data/processed/splits.csv")

# Merge splits with data
data = df.merge(splits[["id", "split", "cv_fold"]], on="id")

# 1. Development set (N=455) for training & CV tuning
dev_data = data[data["split"] == "development"].copy()

# 2. Test set (N=114) — LOCKED until hyperparameter tuning & threshold selection are complete
test_data = data[data["split"] == "test"].copy()

feature_cols = [c for c in df.columns if c not in ["id", "diagnosis", "target"]]
```

---

## 2. 5-Fold Cross-Validation Workflow

Train your model inside each fold ($k \in \{0, 1, 2, 3, 4\}$). Preprocessing (e.g., `StandardScaler`, Platt calibration) **must be fitted only on the training fold**.

```python
oof_predictions = []

for fold in range(5):
    train_fold = dev_data[dev_data["cv_fold"] != fold]
    val_fold = dev_data[dev_data["cv_fold"] == fold]
    
    X_train, y_train = train_fold[feature_cols], train_fold["target"]
    X_val, y_val = val_fold[feature_cols], val_fold["target"]
    
    # Example: Fit your model / pipeline here
    # pipeline.fit(X_train, y_train)
    # val_probs = pipeline.predict_proba(X_val)[:, 1]
    
    for rec_id, y_true, prob in zip(val_fold["id"], y_val, val_probs):
        oof_predictions.append({
            "id": rec_id,
            "y_true": y_true,
            "model_name": "YOUR_MODEL_NAME",  # e.g., 'Random_Forest'
            "fold": fold,
            "y_prob": prob
        })

oof_df = pd.DataFrame(oof_predictions)
oof_df.to_csv("results/predictions/oof_YOUR_MODEL_NAME.csv", index=False)
```

---

## 3. Threshold Selection on Development OOF

After generating all 455 out-of-fold predictions, lock your decision threshold targeting $\ge 95\%$ sensitivity:

```python
import sys
sys.path.append(".")
from src.metrics import select_threshold_target_sensitivity, evaluate_predictions

threshold, achieved_sens = select_threshold_target_sensitivity(
    oof_df["y_true"], oof_df["y_prob"], target_sens=0.95
)
print(f"Locked threshold: {threshold:.4f} (Achieved OOF Sensitivity: {achieved_sens:.4f})")
```

---

## 4. Final Held-Out Test Prediction (One-Shot)

Once your hyperparameters and decision threshold are finalized:
1. Retrain your final tuned pipeline on the **entire development set** (`dev_data`).
2. Generate predicted probabilities on the **test set** (`test_data`).
3. Save predictions to `results/predictions/test_YOUR_MODEL_NAME.csv`:

```python
test_pred_df = pd.DataFrame({
    "id": test_data["id"],
    "y_true": test_data["target"],
    "model_name": "YOUR_MODEL_NAME",
    "split": "test",
    "y_prob": test_probs
})
test_pred_df.to_csv("results/predictions/test_YOUR_MODEL_NAME.csv", index=False)
```

---

## 5. Master Evaluation

Once your prediction files are saved in `results/predictions/`, run:
```bash
python3 src/evaluate_all.py
```
This automatically updates the comparison tables in `results/tables/` and comparative curves in `results/figures/`.
