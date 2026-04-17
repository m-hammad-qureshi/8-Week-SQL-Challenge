# Data Bank — Data Profiling Report
**Week 4 | 8 Week SQL Challenge**

> **Goal:** Identify anomalies, placeholders, and data distribution across all three tables prior to ELT (Extract, Load, Transform). This step ensures analytical accuracy and prevents silent errors in downstream queries.

---

## Profiling Summary

| Table | Total Records | Unique Customers | Duplicates | NULLs | Key Finding |
|---|---|---|---|---|---|
| `customer_nodes` | 3,500 | 500 | 0 | 0 | 500 sentinel dates (`9999-12-31`) detected |
| `customer_transactions` | 5,868 | 500 | 0 | 0 | 1 zero-amount deposit found (customer_id = 32) |
| `regions` | 5 | — | 0 | 0 | Clean passthrough. No action required |

---

## Table 1: customer_nodes

### Checks Performed

| # | Check | Method | Result |
|---|---|---|---|
| 1 | Exact Duplicates | `ROW_NUMBER()` partitioned by all columns | ✅ 0 duplicates |
| 2 | NULL / Blank Audit | `SUM(CASE WHEN IS NULL)` per column | ✅ 0 nulls |
| 3 | Temporal Boundary | `MIN/MAX` on start_date and end_date | ⚠️ Sentinel value detected |
| 4 | Granularity & Scale | `COUNT(*)` and `COUNT(DISTINCT)` | ✅ 3,500 rows, 500 customers |
| 5 | Logical Date Contradictions | `WHERE start_date > end_date` | ✅ 100% chronological integrity |
| 6 | Categorical Distribution | `DISTINCT` on region_id and node_id | ✅ 5 regions, 5 nodes |
| 7 | Schema Validation | `DESCRIBE` + `INFORMATION_SCHEMA` | ✅ Data types confirmed |

### Key Finding — Sentinel Value (`9999-12-31`)

- **500 records** have `end_date = '9999-12-31'`
- This is a **High Date / Sentinel Value** representing currently active node assignments
- It prevents NULLs in the `end_date` column but requires special handling in `DATEDIFF` calculations
- **Recommendation:** Filter with `WHERE end_date != '9999-12-31'` for duration calculations, or replace with `CURRENT_DATE` using `COALESCE` for active record inclusion

### Dataset Insight
> 3,500 total records for 500 unique customers means on average each customer has been reassigned across **7 different nodes** — consistent with Data Bank's security-first node rotation model.

---

## Table 2: customer_transactions

### Checks Performed

| # | Check | Method | Result |
|---|---|---|---|
| 1 | Scale & Granularity | `COUNT(*)` and `COUNT(DISTINCT)` | ✅ 5,868 transactions, 500 customers |
| 2 | Exact Duplicates | `ROW_NUMBER()` partitioned by all columns | ✅ 0 duplicates |
| 3 | Schema Validation | `DESCRIBE` + `INFORMATION_SCHEMA` | ✅ `txn_amount` confirmed as numeric |
| 4 | NULL / Blank Audit | `SUM(CASE WHEN IS NULL OR = '')` per column | ✅ 0 corrupted values |
| 5 | Temporal Boundary | `MIN/MAX` on txn_date | ✅ 2020-01-01 to 2020-04-28 |
| 6 | Categorical Distribution | `DISTINCT txn_type` | ✅ 3 types: deposit, withdrawal, purchase |
| 7 | Unexpected Values | `WHERE txn_amount = 0` | ⚠️ 1 zero-amount record found |

### Key Finding — Zero Amount Transaction

- **1 record** found with `txn_amount = 0` for `txn_type = 'deposit'` (customer_id = 32)
- Possible causes: failed transaction, system test record, or promotional account opening
- **Recommendation:** Filter with `WHERE txn_amount > 0` in aggregation queries. Document as known data quality exception.

---

## Table 3: regions

### Result: Clean Passthrough ✅

- 5 records, 2 columns (`region_id`, `region_name`)
- No duplicates, nulls, or inconsistent casing detected
- No action required

---

## Cross-Table Referential Integrity

| Relationship | Check | Result |
|---|---|---|
| `customer_nodes` ↔ `customer_transactions` | Unique customer count match | ✅ 500 customers in both tables |
| `customer_nodes` ↔ `regions` | Unique region count match | ✅ 5 regions in both tables |

> **Conclusion:** 100% referential integrity confirmed across all tables. No orphan records detected.

---

## Action Items Before Analysis

| Priority | Action | Reason |
|---|---|---|
| 🔴 High | Filter `end_date != '9999-12-31'` in duration queries | Prevents inflated DATEDIFF results |
| 🟡 Medium | Filter `txn_amount > 0` in aggregation queries | Removes likely data entry error |
| 🟢 Low | No action needed for `regions` table | Clean passthrough confirmed |

---

## Files

| File | Description |
|---|---|
| `Table_1_Customer_Nodes.sql` | Full profiling queries for customer_nodes table |
| `Table_2_Customer_Transactions.sql` | Full profiling queries for customer_transactions table |
| `Table_3_Regions.sql` | Profiling and referential integrity checks |
