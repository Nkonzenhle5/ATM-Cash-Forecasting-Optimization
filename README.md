# ATM Cash Forecasting and Optimization (SAS)

## Project Overview

This project focuses on forecasting ATM cash withdrawals and optimizing refill decisions using SAS.

The main objectives are:
- Avoid ATM cash shortages
- Use cash efficiently
- Reduce operational costs

---

## Data Description

The dataset used in this project contains historical ATM transaction data.

Key variables include:
- Transaction Date
- ATM Name (location of ATM)
- Total Amount Withdrawn
- Weekday
- Working Day indicator
- Festival / Holiday information

The dataset represents daily withdrawal activity across multiple ATM locations.

Note: The raw dataset is not included in this repository.

---

## Methodology

### 1. Data Preparation
- Cleaned raw ATM transaction data
- Aggregated withdrawals by ATM and date
- Created daily total cash demand
- Added contextual variables such as weekday, working day, and festival indicators

---

### 2. Forecasting Model

A General Linear Model (GLM) was used to predict ATM demand.

Variables included:
- Lagged demand (previous day's withdrawals)
- ATM location
- Weekday
- Working day indicator
- Festival indicator

Results:
- All variables were statistically significant (p < 0.05)
- R-square approximately 0.50, indicating moderate model fit

---

### 3. Initial Optimization Model

An initial cash management strategy was implemented using the forecasted demand.

Rule:
- Refill ATM to full capacity when cash falls below a safety buffer

Results:
- No cash shortages observed
- High average cash levels (approximately 112,000)
- Low refill frequency

Limitation:
- Excess cash held in ATMs, leading to inefficiency

---

### 4. Improved Optimization Model

The optimization strategy was improved using:

- Proactive refill trigger based on predicted demand
- Partial refill amounts instead of full capacity refills

Results:
- No cash shortages observed
- Reduced average cash levels (approximately 40,000 to 60,000)
- Increased refill frequency

---

## Key Insight

There is a trade-off between:
- Holding more cash (fewer refills but inefficient use of money)
- Holding less cash (more refills but better cash utilization)

The improved model provides a better balance between these two factors.

---

## Files

- `atm_project_final.sas` → SAS code for the full project

---

## Conclusion

The project demonstrates how forecasting and optimization can be combined to improve ATM cash management.

The final model ensures reliable cash availability while improving efficiency and reducing excess cash holding.
