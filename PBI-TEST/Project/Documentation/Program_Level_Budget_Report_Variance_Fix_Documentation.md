# Program Level Budget Report – Variance "NA" Fix

**Report:** Finance - Key Performance Indicators V1 (11-02-26).pbix
**Page / Visual:** Program Performance – *Program Level Budget Report - Rollup* (Matrix)
**Matrix value field:** `[Program - Matrix Value]`
**Change date:** 2026-11-03
**Scope:** DAX measure expressions only (3 measures)

---

## 1. Purpose of the Change

### Why the change was required

The Variance column in the Program Level Budget Report Rollup Matrix was calculated as `Actual - Budget` without checking whether a Budget value exists. In DAX, subtracting a blank value treats the blank as `0`. For fiscal years and months where no Budget data is loaded, Variance therefore displayed the full Actual amount, which looked like a real variance and was misleading.

### Expected behaviour

| Condition | Variance displays |
|---|---|
| Actual exists **and** Budget is unavailable (blank) | `"NA"` |
| Actual **and** Budget are both available | `Actual - Budget` |

Budget availability is detected dynamically: a Budget is treated as unavailable when the Budget value for that cell evaluates to blank. No fiscal years are hardcoded, so FY2023, FY2024 and any future fiscal years are handled by the same rule.

---

## 2. DAX Changes – Before and After

### 2.1 `Program - 3M Actual Budget Variance`

**Home table:** `Program Column Type`
**Used by:** `[Program - Matrix Value]` (Month columns)

#### Before

```dax
VAR ColumnType =
    SELECTEDVALUE (
        'Program Column Type'[Column Type],
        "Actual"
    )

VAR CurrentColumnYearMonth =
    SELECTEDVALUE ( 'Month'[YEAR_MONTH_NUM] )

VAR CurrentMonthYM =
    [Program - Current Month YM]

VAR IsCurrentMonthColumn =
    NOT ISBLANK ( CurrentMonthYM )
        && CurrentColumnYearMonth = CurrentMonthYM

-- Existing Actual measure
VAR ActualValue =
    [Program - Last 3 Months Actual]

-- Current Month Budget
VAR BudgetValue =
    IF (
        IsCurrentMonthColumn,
        CALCULATE (
            SWITCH (
                SELECTEDVALUE ( ProgramTableMaster[Category] ),
                "Revenue", [Revenue_Budget_Program],
                "Expenses", [Expenses_Budget_Program]
            ),
            REMOVEFILTERS ( DIM_DATE_FINANCE ),
            DIM_DATE_FINANCE[YEAR_MONTH_NUM] = CurrentMonthYM
        )
    )

RETURN
    SWITCH (
        ColumnType,
        "Actual", ActualValue,
        "Budget", BudgetValue,
        "Variance",
            IF (
                IsCurrentMonthColumn,
                ActualValue - BudgetValue
            )
    )
```

#### After

```dax
VAR ColumnType =
    SELECTEDVALUE (
        'Program Column Type'[Column Type],
        "Actual"
    )

VAR CurrentColumnYearMonth =
    SELECTEDVALUE ( 'Month'[YEAR_MONTH_NUM] )

VAR CurrentMonthYM =
    [Program - Current Month YM]

VAR IsCurrentMonthColumn =
    NOT ISBLANK ( CurrentMonthYM )
        && CurrentColumnYearMonth = CurrentMonthYM

-- Existing Actual measure
VAR ActualValue =
    [Program - Last 3 Months Actual]

-- Current Month Budget
VAR BudgetValue =
    IF (
        IsCurrentMonthColumn,
        CALCULATE (
            SWITCH (
                SELECTEDVALUE ( ProgramTableMaster[Category] ),
                "Revenue", [Revenue_Budget_Program],
                "Expenses", [Expenses_Budget_Program]
            ),
            REMOVEFILTERS ( DIM_DATE_FINANCE ),
            DIM_DATE_FINANCE[YEAR_MONTH_NUM] = CurrentMonthYM
        )
    )

RETURN
    SWITCH (
        ColumnType,
        "Actual", ActualValue,
        "Budget", BudgetValue,
        "Variance",
            IF (
                IsCurrentMonthColumn,
                IF (
                    ISBLANK ( BudgetValue ),
                    IF ( NOT ISBLANK ( ActualValue ), "NA" ),
                    ActualValue - BudgetValue
                )
            )
    )
```

### 2.2 `Program - FY Variance`

**Home table:** `Program Column Header`
**Used by:** `[Program - Matrix Value]` (Fiscal Year columns)

#### Before

```dax
    [Program - FY Actual]
        - [Program - FY Budget]
```

#### After

```dax
VAR ActualValue = [Program - FY Actual]

VAR BudgetValue = [Program - FY Budget]

RETURN
    IF (
        ISBLANK ( BudgetValue ),
        IF ( NOT ISBLANK ( ActualValue ), "NA" ),
        ActualValue - BudgetValue
    )
```

### 2.3 `Program - Matrix Value`

**Home table:** `Program Column Header`
**Used by:** the Rollup Matrix visual (Values field)

#### Before

```dax
VAR HeaderType =
    SELECTEDVALUE ( 'Program Column Header'[Header Type] )

VAR ColumnType =
    SELECTEDVALUE (
        'Program Column Type'[Column Type],
        "Actual"
    )

VAR Result =
    SWITCH (
        HeaderType,

        "Month",
            CALCULATE (
                [Program - 3M Actual Budget Variance],
                TREATAS (
                    VALUES ( 'Program Column Header'[Header YM] ),
                    'Month'[YEAR_MONTH_NUM]
                )
            ),

        "Fiscal Year",
            IF (
                SELECTEDVALUE ( 'Program Column Header'[Header FY] )
                    = [Program - Report FY],

                SWITCH (
                    ColumnType,
                    "Actual", [Program - FY Actual],
                    "Budget", [Program - FY Budget],
                    "Variance", [Program - FY Variance]
                )
            )
    )

RETURN
    IF (
        ISBLANK ( Result ),
        BLANK (),
        IF (
            ABS ( Result ) < 0.01,
            0,
            Result
        )
    )
```

#### After

```dax
VAR HeaderType =
    SELECTEDVALUE ( 'Program Column Header'[Header Type] )

VAR ColumnType =
    SELECTEDVALUE (
        'Program Column Type'[Column Type],
        "Actual"
    )

VAR Result =
    SWITCH (
        HeaderType,

        "Month",
            CALCULATE (
                [Program - 3M Actual Budget Variance],
                TREATAS (
                    VALUES ( 'Program Column Header'[Header YM] ),
                    'Month'[YEAR_MONTH_NUM]
                )
            ),

        "Fiscal Year",
            IF (
                SELECTEDVALUE ( 'Program Column Header'[Header FY] )
                    = [Program - Report FY],

                SWITCH (
                    ColumnType,
                    "Actual", [Program - FY Actual],
                    "Budget", [Program - FY Budget],
                    "Variance", [Program - FY Variance]
                )
            )
    )

RETURN
    IF (
        ISBLANK ( Result ),
        BLANK (),
        IF (
            ISTEXT ( Result ),
            Result,
            IF (
                ABS ( Result ) < 0.01,
                0,
                Result
            )
        )
    )
```

---

## 3. Exact Changes Explained

In the diffs below, lines starting with `-` were removed and lines starting with `+` were added. Lines without a prefix are unchanged context.

### 3.1 `Program - 3M Actual Budget Variance`

**What changed:** only the `"Variance"` branch of the final `SWITCH`. All variables (`ColumnType`, `CurrentColumnYearMonth`, `CurrentMonthYM`, `IsCurrentMonthColumn`, `ActualValue`, `BudgetValue`) and the `"Actual"` and `"Budget"` branches are unchanged.

**Original logic**

```dax
        "Variance",
            IF (
                IsCurrentMonthColumn,
                ActualValue - BudgetValue
            )
```

**Updated logic**

```dax
        "Variance",
            IF (
                IsCurrentMonthColumn,
                IF (
                    ISBLANK ( BudgetValue ),
                    IF ( NOT ISBLANK ( ActualValue ), "NA" ),
                    ActualValue - BudgetValue
                )
            )
```

**Line-level change**

```diff
         "Variance",
             IF (
                 IsCurrentMonthColumn,
-                ActualValue - BudgetValue
+                IF (
+                    ISBLANK ( BudgetValue ),
+                    IF ( NOT ISBLANK ( ActualValue ), "NA" ),
+                    ActualValue - BudgetValue
+                )
             )
```

**In simple language**

- `ISBLANK ( BudgetValue )` – checks whether a Budget exists for the current month column.
- `IF ( NOT ISBLANK ( ActualValue ), "NA" )` – if there is no Budget but there is an Actual, return the text `"NA"`. If neither exists, nothing is returned (blank), as before.
- `ActualValue - BudgetValue` – if a Budget exists, Variance is calculated exactly as before.
- The outer `IF ( IsCurrentMonthColumn, ... )` is unchanged, so Variance still only appears on the current (latest available) month column. The existing month-selection logic and 5th-of-the-month rule (both inside `[Program - Current Month YM]`) are not affected.
- The check reuses the `ActualValue` and `BudgetValue` variables the measure already computes, so no additional measure evaluations are introduced.

### 3.2 `Program - FY Variance`

**What changed:** the single subtraction expression was replaced with two variables and a Budget availability check. The measure still uses the same two source measures, `[Program - FY Actual]` and `[Program - FY Budget]`.

**Original logic**

```dax
    [Program - FY Actual]
        - [Program - FY Budget]
```

**Updated logic**

```dax
VAR ActualValue = [Program - FY Actual]

VAR BudgetValue = [Program - FY Budget]

RETURN
    IF (
        ISBLANK ( BudgetValue ),
        IF ( NOT ISBLANK ( ActualValue ), "NA" ),
        ActualValue - BudgetValue
    )
```

**Line-level change**

```diff
-    [Program - FY Actual]
-        - [Program - FY Budget]
+VAR ActualValue = [Program - FY Actual]
+
+VAR BudgetValue = [Program - FY Budget]
+
+RETURN
+    IF (
+        ISBLANK ( BudgetValue ),
+        IF ( NOT ISBLANK ( ActualValue ), "NA" ),
+        ActualValue - BudgetValue
+    )
```

**In simple language**

- `VAR ActualValue` / `VAR BudgetValue` – store the FY Actual and FY Budget once, so each is evaluated a single time (the same number of evaluations as the original expression).
- `ISBLANK ( BudgetValue )` – checks whether the selected fiscal year has any Budget for the FY period.
- `IF ( NOT ISBLANK ( ActualValue ), "NA" )` – no Budget but Actual exists: return `"NA"`. Neither exists: return blank.
- `ActualValue - BudgetValue` – Budget exists: Variance is calculated as before.

### 3.3 `Program - Matrix Value`

**What changed:** only the final `RETURN` expression. An `ISTEXT` check was wrapped around the existing small-value rounding rule. The `HeaderType`, `ColumnType` and `Result` variables, including the Month / Fiscal Year routing, are unchanged.

**Original logic**

```dax
RETURN
    IF (
        ISBLANK ( Result ),
        BLANK (),
        IF (
            ABS ( Result ) < 0.01,
            0,
            Result
        )
    )
```

**Updated logic**

```dax
RETURN
    IF (
        ISBLANK ( Result ),
        BLANK (),
        IF (
            ISTEXT ( Result ),
            Result,
            IF (
                ABS ( Result ) < 0.01,
                0,
                Result
            )
        )
    )
```

**Line-level change**

```diff
 RETURN
     IF (
         ISBLANK ( Result ),
         BLANK (),
         IF (
-            ABS ( Result ) < 0.01,
-            0,
-            Result
+            ISTEXT ( Result ),
+            Result,
+            IF (
+                ABS ( Result ) < 0.01,
+                0,
+                Result
+            )
         )
     )
```

**In simple language**

- After the two variance measures were changed, `Result` can now be the text `"NA"` for Variance cells.
- `ABS ( Result )` only works on numbers, so `ABS ( "NA" )` would cause an error.
- `ISTEXT ( Result ), Result` – if the value is text (`"NA"`), pass it straight through to the matrix.
- Numeric values continue through the original `ABS ( Result ) < 0.01` rule unchanged, so very small values are still shown as `0`.

---

## 4. Measures Not Changed

The following related measures were reviewed and left exactly as they were:

| Measure | Home table | Role in the matrix |
|---|---|---|
| `Revenue_Budget_Program` | Metrics | Revenue Budget source measure |
| `Expenses_Budget_Program` | Metrics | Expenses Budget source measure |
| `Revenue_Actual_Program` | Metrics | Revenue Actual source measure |
| `Expenses_Actual_Program` | Metrics | Expenses Actual source measure |
| `Program - FY Actual` | Program Column Header | FY Actual column |
| `Program - FY Budget` | Program Column Header | FY Budget column |
| `Program - FY Period End` | Program Column Header | FY period end date (includes the 5th-of-the-month rule) |
| `Program - Report FY` | Program Column Header | Determines the reporting fiscal year from the slicers |
| `Program - Current Month YM` | Program Column Type | Dynamic month selection and 5th-of-the-month availability rule |
| `Program - Last 3 Months Actual` | Month | Monthly Actual values for the last three months |

No tables, columns, relationships, format strings or report visuals were changed. The Matrix column structure (`'Program Column Header'[Column Header]` → `'Program Column Type'[Column Type]`) and row hierarchy are unchanged.

---

## 5. Summary of Changes

| # | Measure | Modification |
|---|---|---|
| 1 | `Program - 3M Actual Budget Variance` | `"Variance"` branch now returns `"NA"` when the current month Budget is blank and Actual exists; otherwise `ActualValue - BudgetValue`. |
| 2 | `Program - FY Variance` | Returns `"NA"` when the FY Budget is blank and FY Actual exists; otherwise `[Program - FY Actual] - [Program - FY Budget]`. |
| 3 | `Program - Matrix Value` | `ISTEXT` check added so `"NA"` passes through the existing small-value rounding rule without error. |

**Why:** Variance previously treated a missing Budget as zero, so it displayed the full Actual amount for periods with no Budget. The change makes Variance show `"NA"` whenever Budget is unavailable, and keeps `Actual - Budget` wherever Budget exists. Budget availability is detected dynamically from the data, with no hardcoded fiscal years.

**Note:** because `"NA"` is text, all three modified measures now return the Variant data type (number or text) instead of a pure numeric type.
