# Margin Details Matrix – Variance "NA" Fix

**Report:** Finance - Key Performance Indicators V1 (11-02-26).pbix
**Page / Visual:** Program Performance – *Margin Details* (Matrix)
**Matrix value field:** `[Margin - Matrix Value]` (home table `Month`)
**Change date:** 2026-11-03
**Scope:** DAX expression of one measure: `Margin - Matrix Value`

---

## 1. Purpose of the Change

### Why the change was required

The Variance columns in the Margin Details Matrix were calculated as `Actual - Budget` without checking whether a Budget value exists. In DAX, subtracting a blank value treats the blank as `0`. For fiscal years and months with no Margin Budget data loaded, Variance therefore showed the full Actual amount, which looked like a real variance and was misleading.

This is the same issue that was fixed earlier in the Program Level Budget Report - Rollup Matrix, and the same rule is now applied to the Margin Details Matrix.

### Expected behaviour

| Condition | Variance displays |
|---|---|
| Actual exists **and** Budget is unavailable (blank) | `"NA"` |
| Actual **and** Budget are both available | `Actual - Budget` |

Budget availability is detected dynamically: a Budget is treated as unavailable when the Budget value for that cell evaluates to blank. No fiscal years are hardcoded.

### Where the Variance logic lives in the Margin matrix

The Margin Details Matrix does not have a separate monthly variance measure (unlike the Program report's `Program - 3M Actual Budget Variance`). Both variance calculations are evaluated inside `[Margin - Matrix Value]`:

| Variance column | Location in `[Margin - Matrix Value]` |
|---|---|
| Monthly Variance | `"Month"` branch → inline `"Variance"` branch (`ActualValue - BudgetValue`) |
| Fiscal Year Variance | `"Fiscal Year"` branch → `"Variance", [Margin - FY Variance]` |

The Fiscal Year check was placed in the `"Fiscal Year"` branch of `[Margin - Matrix Value]`, not in `[Margin - FY Variance]` itself. `[Margin - FY Variance]` is also used by `[Margin - Matrix Value Total with]` (and through it by `[Margin - Total]` and `[Margin - Matrix Value With Total]`). That measure applies `ABS` and `SUMX` to the result, so a text `"NA"` returned from `[Margin - FY Variance]` would cause errors there. Keeping the change inside the matrix measure leaves `[Margin - FY Variance]` and every measure that depends on it exactly as before.

---

## 2. DAX Changes – Before and After

### `Margin - Matrix Value`

**Home table:** `Month`
**Used by:** the Margin Details Matrix visual (Values field)

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
                SWITCH (
                    ColumnType,
                    "Actual", [Margin - Last 3 Months Actual],

                    "Budget",
                        VAR CurrentColumnYM =
                            SELECTEDVALUE (
                                'Program Column Header'[Header YM]
                            )
                        VAR CurrentMonthYM =
                            [Program - Current Month YM]
                        RETURN
                            IF (
                                CurrentColumnYM = CurrentMonthYM,
                                CALCULATE (
                                    SWITCH (
                                        SELECTEDVALUE (
                                            ProgramTableMasterMargin[Category]
                                        ),
                                        "Direct Margin without Fixed cost",
                                            [Budget_DirectMargin_Program],
                                        "Margin - Revenue Minus Expenses",
                                            [Budget_Margin_Program],
                                        "Revenue Non Operating",
                                            [Budget_RevenueNonOperating_Program],
                                        "Margin Before Overhead Allocations",
                                            [Budget_Margin_BOA_Program],
                                        "Allocations",
                                            [Budget_Allocations_Program],
                                        "Margin After Overhead Allocations",
                                            [Budget_Margin_AOA_Program]
                                    ),
                                    REMOVEFILTERS ( DIM_DATE_FINANCE ),
                                    DIM_DATE_FINANCE[YEAR_MONTH_NUM]
                                        = CurrentMonthYM
                                )
                            ),

                    "Variance",
                        VAR CurrentColumnYM =
                            SELECTEDVALUE (
                                'Program Column Header'[Header YM]
                            )
                        VAR CurrentMonthYM =
                            [Program - Current Month YM]
                        VAR ActualValue =
                            [Margin - Last 3 Months Actual]
                        VAR BudgetValue =
                            CALCULATE (
                                SWITCH (
                                    SELECTEDVALUE (
                                        ProgramTableMasterMargin[Category]
                                    ),
                                    "Direct Margin without Fixed cost",
                                        [Budget_DirectMargin_Program],
                                    "Margin - Revenue Minus Expenses",
                                        [Budget_Margin_Program],
                                    "Revenue Non Operating",
                                        [Budget_RevenueNonOperating_Program],
                                    "Margin Before Overhead Allocations",
                                        [Budget_Margin_BOA_Program],
                                    "Allocations",
                                        [Budget_Allocations_Program],
                                    "Margin After Overhead Allocations",
                                        [Budget_Margin_AOA_Program]
                                ),
                                REMOVEFILTERS ( DIM_DATE_FINANCE ),
                                DIM_DATE_FINANCE[YEAR_MONTH_NUM]
                                    = CurrentMonthYM
                            )
                        RETURN
                            IF (
                                CurrentColumnYM = CurrentMonthYM,
                                ActualValue - BudgetValue
                            )
                ),
                TREATAS (
                    VALUES ( 'Program Column Header'[Header YM] ),
                    'Month'[YEAR_MONTH_NUM]
                )
            ),

        "Fiscal Year",
            IF (
                SELECTEDVALUE (
                    'Program Column Header'[Header FY]
                ) = [Program - Report FY],
                SWITCH (
                    ColumnType,
                    "Actual", [Margin - FY Actual],
                    "Budget", [Margin - FY Budget],
                    "Variance", [Margin - FY Variance]
                )
            )
    )

RETURN
    IF (
        ISBLANK ( Result ),
        BLANK (),
        IF ( ABS ( Result ) < 0.01, 0, Result )
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
                SWITCH (
                    ColumnType,
                    "Actual", [Margin - Last 3 Months Actual],

                    "Budget",
                        VAR CurrentColumnYM =
                            SELECTEDVALUE (
                                'Program Column Header'[Header YM]
                            )
                        VAR CurrentMonthYM =
                            [Program - Current Month YM]
                        RETURN
                            IF (
                                CurrentColumnYM = CurrentMonthYM,
                                CALCULATE (
                                    SWITCH (
                                        SELECTEDVALUE (
                                            ProgramTableMasterMargin[Category]
                                        ),
                                        "Direct Margin without Fixed cost",
                                            [Budget_DirectMargin_Program],
                                        "Margin - Revenue Minus Expenses",
                                            [Budget_Margin_Program],
                                        "Revenue Non Operating",
                                            [Budget_RevenueNonOperating_Program],
                                        "Margin Before Overhead Allocations",
                                            [Budget_Margin_BOA_Program],
                                        "Allocations",
                                            [Budget_Allocations_Program],
                                        "Margin After Overhead Allocations",
                                            [Budget_Margin_AOA_Program]
                                    ),
                                    REMOVEFILTERS ( DIM_DATE_FINANCE ),
                                    DIM_DATE_FINANCE[YEAR_MONTH_NUM]
                                        = CurrentMonthYM
                                )
                            ),

                    "Variance",
                        VAR CurrentColumnYM =
                            SELECTEDVALUE (
                                'Program Column Header'[Header YM]
                            )
                        VAR CurrentMonthYM =
                            [Program - Current Month YM]
                        VAR ActualValue =
                            [Margin - Last 3 Months Actual]
                        VAR BudgetValue =
                            CALCULATE (
                                SWITCH (
                                    SELECTEDVALUE (
                                        ProgramTableMasterMargin[Category]
                                    ),
                                    "Direct Margin without Fixed cost",
                                        [Budget_DirectMargin_Program],
                                    "Margin - Revenue Minus Expenses",
                                        [Budget_Margin_Program],
                                    "Revenue Non Operating",
                                        [Budget_RevenueNonOperating_Program],
                                    "Margin Before Overhead Allocations",
                                        [Budget_Margin_BOA_Program],
                                    "Allocations",
                                        [Budget_Allocations_Program],
                                    "Margin After Overhead Allocations",
                                        [Budget_Margin_AOA_Program]
                                ),
                                REMOVEFILTERS ( DIM_DATE_FINANCE ),
                                DIM_DATE_FINANCE[YEAR_MONTH_NUM]
                                    = CurrentMonthYM
                            )
                        RETURN
                            IF (
                                CurrentColumnYM = CurrentMonthYM,
                                IF (
                                    ISBLANK ( BudgetValue ),
                                    IF ( NOT ISBLANK ( ActualValue ), "NA" ),
                                    ActualValue - BudgetValue
                                )
                            )
                ),
                TREATAS (
                    VALUES ( 'Program Column Header'[Header YM] ),
                    'Month'[YEAR_MONTH_NUM]
                )
            ),

        "Fiscal Year",
            IF (
                SELECTEDVALUE (
                    'Program Column Header'[Header FY]
                ) = [Program - Report FY],
                SWITCH (
                    ColumnType,
                    "Actual", [Margin - FY Actual],
                    "Budget", [Margin - FY Budget],
                    "Variance",
                        VAR FYActualValue = [Margin - FY Actual]
                        VAR FYBudgetValue = [Margin - FY Budget]
                        RETURN
                            IF (
                                ISBLANK ( FYBudgetValue ),
                                IF ( NOT ISBLANK ( FYActualValue ), "NA" ),
                                FYActualValue - FYBudgetValue
                            )
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
            IF ( ABS ( Result ) < 0.01, 0, Result )
        )
    )
```

---

## 3. Exact Changes Explained

`[Margin - Matrix Value]` received three changes. In the diffs below, lines starting with `-` were removed and lines starting with `+` were added. Lines without a prefix are unchanged context.

All other parts of the measure are unchanged: the `HeaderType`, `ColumnType` and `Result` variables, the `"Actual"` and `"Budget"` branches, the six Budget source measures in the `SWITCH`, the `REMOVEFILTERS ( DIM_DATE_FINANCE )` / `YEAR_MONTH_NUM` filters, the `TREATAS` mapping of `'Program Column Header'[Header YM]` to `'Month'[YEAR_MONTH_NUM]`, and the `[Program - Report FY]` check.

### 3.1 Monthly Variance (`"Month"` → `"Variance"` branch)

**Original logic**

```dax
                        RETURN
                            IF (
                                CurrentColumnYM = CurrentMonthYM,
                                ActualValue - BudgetValue
                            )
```

**Updated logic**

```dax
                        RETURN
                            IF (
                                CurrentColumnYM = CurrentMonthYM,
                                IF (
                                    ISBLANK ( BudgetValue ),
                                    IF ( NOT ISBLANK ( ActualValue ), "NA" ),
                                    ActualValue - BudgetValue
                                )
                            )
```

**Line-level change**

```diff
                         RETURN
                             IF (
                                 CurrentColumnYM = CurrentMonthYM,
-                                ActualValue - BudgetValue
+                                IF (
+                                    ISBLANK ( BudgetValue ),
+                                    IF ( NOT ISBLANK ( ActualValue ), "NA" ),
+                                    ActualValue - BudgetValue
+                                )
                             )
```

**In simple language**

- `ISBLANK ( BudgetValue )` – checks whether a Margin Budget exists for the current month column.
- `IF ( NOT ISBLANK ( ActualValue ), "NA" )` – if there is no Budget but there is an Actual, return the text `"NA"`. If neither exists, nothing is returned (blank), as before.
- `ActualValue - BudgetValue` – if a Budget exists, Variance is calculated exactly as before.
- The outer `IF ( CurrentColumnYM = CurrentMonthYM, ... )` is unchanged, so Variance still only appears on the current (latest available) month column. `[Program - Current Month YM]`, which holds the dynamic month selection and the 5th-of-the-month rule, is not affected.
- The check reuses the existing `ActualValue` and `BudgetValue` variables, so no additional measure evaluations are introduced.

### 3.2 Fiscal Year Variance (`"Fiscal Year"` → `"Variance"` branch)

**Original logic**

```dax
                    "Variance", [Margin - FY Variance]
```

**Updated logic**

```dax
                    "Variance",
                        VAR FYActualValue = [Margin - FY Actual]
                        VAR FYBudgetValue = [Margin - FY Budget]
                        RETURN
                            IF (
                                ISBLANK ( FYBudgetValue ),
                                IF ( NOT ISBLANK ( FYActualValue ), "NA" ),
                                FYActualValue - FYBudgetValue
                            )
```

**Line-level change**

```diff
-                    "Variance", [Margin - FY Variance]
+                    "Variance",
+                        VAR FYActualValue = [Margin - FY Actual]
+                        VAR FYBudgetValue = [Margin - FY Budget]
+                        RETURN
+                            IF (
+                                ISBLANK ( FYBudgetValue ),
+                                IF ( NOT ISBLANK ( FYActualValue ), "NA" ),
+                                FYActualValue - FYBudgetValue
+                            )
```

**In simple language**

- `VAR FYActualValue` / `VAR FYBudgetValue` – evaluate the existing `[Margin - FY Actual]` and `[Margin - FY Budget]` measures once each. These are the same two measures `[Margin - FY Variance]` subtracts, so the number of evaluations is unchanged.
- `ISBLANK ( FYBudgetValue )` – checks whether the reporting fiscal year has any Margin Budget for the FY period.
- `IF ( NOT ISBLANK ( FYActualValue ), "NA" )` – no Budget but Actual exists: return `"NA"`. Neither exists: return blank.
- `FYActualValue - FYBudgetValue` – Budget exists: returns the same value as `[Margin - FY Actual] - [Margin - FY Budget]`, which is the definition of `[Margin - FY Variance]`.
- The surrounding `IF ( SELECTEDVALUE ( 'Program Column Header'[Header FY] ) = [Program - Report FY], ... )` is unchanged, so Fiscal Year and slicer behaviour is not affected.

### 3.3 Rounding guard (final `RETURN`)

**Original logic**

```dax
RETURN
    IF (
        ISBLANK ( Result ),
        BLANK (),
        IF ( ABS ( Result ) < 0.01, 0, Result )
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
            IF ( ABS ( Result ) < 0.01, 0, Result )
        )
    )
```

**Line-level change**

```diff
 RETURN
     IF (
         ISBLANK ( Result ),
         BLANK (),
-        IF ( ABS ( Result ) < 0.01, 0, Result )
+        IF (
+            ISTEXT ( Result ),
+            Result,
+            IF ( ABS ( Result ) < 0.01, 0, Result )
+        )
     )
```

**In simple language**

- `Result` can now be the text `"NA"` for Variance cells.
- `ABS ( Result )` only works on numbers, so `ABS ( "NA" )` would cause an error.
- `ISTEXT ( Result ), Result` – if the value is text (`"NA"`), pass it straight through to the matrix with no numeric rounding.
- Numeric values continue through the original `ABS ( Result ) < 0.01` rule unchanged, so very small values are still shown as `0`.

---

## 4. Measures Not Changed

The following related measures were inspected and left exactly as they were:

| Measure | Home table | Role |
|---|---|---|
| `Margin - FY Variance` | Month | FY Actual - FY Budget (still used by `Margin - Matrix Value Total with`) |
| `Margin - FY Actual` | Month | FY Margin Actual |
| `Margin - FY Budget` | Month | FY Margin Budget |
| `Margin - Last 3 Months Actual` | Month | Monthly Margin Actual for the last three months |
| `Margin - Matrix Value Total with` | Month | Alternative matrix value with total handling (not used by the Margin Details visual) |
| `Margin - Total` | Month | Sum of `Margin - Matrix Value Total with` across categories |
| `Margin - Matrix Value With Total` | Month | Row-based variant of `Margin - Matrix Value Total with` |
| `Budget_DirectMargin_Program` | Metrics | Margin Budget source measure |
| `Budget_Margin_Program` | Metrics | Margin Budget source measure |
| `Budget_RevenueNonOperating_Program` | Metrics | Margin Budget source measure |
| `Budget_Margin_BOA_Program` | Metrics | Margin Budget source measure |
| `Budget_Allocations_Program` | Metrics | Margin Budget source measure |
| `Budget_Margin_AOA_Program` | Metrics | Margin Budget source measure |
| `Actual_DirectMargin_Program` | Metrics | Margin Actual source measure |
| `Actual_Margin_Program` | Metrics | Margin Actual source measure |
| `Actual_RevenueNonOperating_Program` | Metrics | Margin Actual source measure |
| `Actual_Margin_BOA_Program` | Metrics | Margin Actual source measure |
| `Actual_Allocations_Program` | Metrics | Margin Actual source measure |
| `Actual_Margin_AOA_Program` | Metrics | Margin Actual source measure |
| `Program - Current Month YM` | Program Column Type | Dynamic month selection and 5th-of-the-month availability rule |
| `Program - Report FY` | Program Column Header | Reporting fiscal year from the Fiscal Year / Month slicers |
| `Program - FY Period End` | Program Column Header | FY period end date (includes the 5th-of-the-month rule) |
| `Program - 3M Actual Budget Variance` | Program Column Type | Program report measure – previously completed, not modified |
| `Program - FY Variance` | Program Column Header | Program report measure – previously completed, not modified |
| `Program - Matrix Value` | Program Column Header | Program report measure – previously completed, not modified |

No tables, columns, relationships, format strings or report visuals were changed. The Margin Details Matrix rows (`ProgramTableMasterMargin[Category]`), columns (`'Program Column Header'[Column Header]` → `'Program Column Type'[Column Type]`) and layout are unchanged.

---

## 5. Summary of Changes

| # | Measure | Location | Modification |
|---|---|---|---|
| 1 | `Margin - Matrix Value` | `"Month"` → `"Variance"` branch | Returns `"NA"` when the current month Budget is blank and Actual exists; otherwise `ActualValue - BudgetValue`. |
| 2 | `Margin - Matrix Value` | `"Fiscal Year"` → `"Variance"` branch | Returns `"NA"` when the FY Budget is blank and FY Actual exists; otherwise `[Margin - FY Actual] - [Margin - FY Budget]`. |
| 3 | `Margin - Matrix Value` | Final `RETURN` | `ISTEXT` check added so `"NA"` passes through without numeric rounding. |

**Why:** Variance previously treated a missing Margin Budget as zero, so it displayed the full Actual amount for periods with no Budget. The change makes Variance show `"NA"` whenever Budget is unavailable and keeps `Actual - Budget` wherever Budget exists. Budget availability is detected dynamically from the data.

**Only one measure was modified:** `Margin - Matrix Value`. Because it can now return `"NA"`, its data type changed from Double to Variant (number or text). All other measures, including `Margin - FY Variance`, are unchanged.
