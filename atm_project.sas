/* ===================================================== */
/* PROJECT: ATM CASH FORECASTING AND OPTIMIZATION */
/* ===================================================== */


/* ===================================================== */
/* STEP 1: IMPORT DATA */
/* ===================================================== */

filename atmfile "~/ATMS/transactions_in_usd.csv";

/* Import CSV file into SAS */
proc import datafile=atmfile
    out=atm_data
    dbms=csv
    replace;
    guessingrows=max;
run;


/* ===================================================== */
/* STEP 2: CLEAN DATA (KEEP ALL COLUMNS) */
/* ===================================================== */

data atm_master;

    set atm_data;

    /* Create simpler variable names (easier for coding) */
    Date  = 'Transaction Date'n;
    ATM   = 'ATM Name'n;
    Cash  = 'Total amount Withdrawn'n;

    /* Clean text variables (make all uppercase) */
    Weekday_clean      = upcase(Weekday);
    Working_day_clean  = upcase('Working Day'n);
    Festival_clean     = upcase('Festival Religion'n);

run;


/* ===================================================== */
/* STEP 3: SORT DATA */
/* ===================================================== */

proc sort data=atm_master;
    by ATM Date;
run;


/* ===================================================== */
/* STEP 4: CREATE DAILY TOTALS PER ATM */
/* ===================================================== */

proc sql;

    create table atm_daily as

    /* Sum withdrawals per ATM per day */
    select 
        ATM,
        Date,
        sum(Cash) as daily_total

    from atm_master

    group by ATM, Date
    order by ATM, Date;

quit;


/* ===================================================== */
/* STEP 5: ADD BUSINESS VARIABLES (FOR EXPLANATION) */
/* ===================================================== */

proc sql;

    create table atm_final as

    /* Combine totals + weekday + holiday info */
    select 
        a.ATM,
        a.Date,
        a.daily_total,

        b.Weekday_clean,
        b.Working_day_clean,
        b.Festival_clean,
        b.'Holiday Sequence'n as Holiday_seq

    from atm_daily a

    left join atm_master b
    on a.ATM = b.ATM 
    and a.Date = b.Date;

quit;


/* ===================================================== */
/* STEP 6: CHECK DATA */
/* ===================================================== */

proc print data=atm_final (obs=10);
run;


/* ===================================================== */
/* SECTION A: FORECASTING MODEL */
/* ===================================================== */

/* Create lag variable (yesterday's demand) */
data model_data;
    set atm_final;
    lag_cash = lag(daily_total);
run;


/* Build forecasting model using GLM */
proc glm data=model_data;

    /* These are categorical variables */
    class ATM Weekday_clean Working_day_clean Festival_clean;

    /* Model demand using different factors */
    model daily_total =
        lag_cash
        ATM
        Weekday_clean
        Working_day_clean
        Festival_clean;

    /* Save predicted values and errors */
    output out=forecast_out
        p=predicted
        r=residual;

run;
quit;


/* View forecast results */
proc print data=forecast_out (obs=10);
run;


/* ===================================================== */
/* SECTION B: FORECAST MODEL EVALUATION */
/* ===================================================== */

/*
Check model performance using:
- p-values (from PROC GLM output)
- R-square
- residuals (difference between actual and predicted)
*/


/* ===================================================== */
/* SECTION C: INITIAL OPTIMIZATION MODEL */
/* ===================================================== */

%let ATM_CAPACITY = 200000;
%let SAFETY_BUFFER = 20000;

data initial_cash_plan;

    set forecast_out;

    by ATM;

    retain current_cash;

    /* Start each ATM with initial cash */
    if first.ATM then current_cash = 100000;

    /* Use predicted demand */
    demand = predicted;

    /* Reduce cash after withdrawals */
    current_cash = current_cash - demand;

    /* Refill only when below safety buffer */
    if current_cash < &SAFETY_BUFFER then do;

        refill_amount = &ATM_CAPACITY - current_cash;
        current_cash = &ATM_CAPACITY;
        refill_flag = 1;

    end;
    else do;

        refill_amount = 0;
        refill_flag = 0;

    end;

run;


/* Check initial results */
proc print data=initial_cash_plan (obs=20);
run;


/* ===================================================== */
/* SECTION D: INITIAL OPTIMIZATION EVALUATION */
/* ===================================================== */

/* Check if ATM ever runs out of cash */
proc sql;
    select *
    from initial_cash_plan
    where current_cash < 0;
quit;

/* Count number of refills */
proc sql;
    select ATM, sum(refill_flag) as total_refills
    from initial_cash_plan
    group by ATM;
quit;

/* Check average cash level */
proc sql;
    select ATM, mean(current_cash) as avg_cash
    from initial_cash_plan
    group by ATM;
quit;


/* ===================================================== */
/* SECTION E: IMPROVED OPTIMIZATION MODEL */
/* ===================================================== */

data final_cash_plan;

    set forecast_out;

    by ATM;

    retain current_cash;

    /* Reset starting cash */
    if first.ATM then current_cash = 100000;

    /* Remove missing predictions */
    if predicted = . then delete;

    /* Use predicted demand */
    demand = predicted;

    /* Cash reduces due to withdrawals */
    current_cash = current_cash - demand;

    /* Improved refill rule: refill earlier */
    if current_cash < (&SAFETY_BUFFER + 2*demand) then do;

        /* Partial refill (not full tank) */
        refill_amount = (&SAFETY_BUFFER + 3*demand) - current_cash;

        /* Do not exceed capacity */
        if current_cash + refill_amount > &ATM_CAPACITY then
            refill_amount = &ATM_CAPACITY - current_cash;

        current_cash = current_cash + refill_amount;

        refill_flag = 1;

    end;
    else do;

        refill_amount = 0;
        refill_flag = 0;

    end;

run;


/* ===================================================== */
/* SECTION F: FINAL OPTIMIZATION EVALUATION */
/* ===================================================== */

/* Check stockout */
proc sql;
    select *
    from final_cash_plan
    where current_cash < 0;
quit;

/* Total refills */
proc sql;
    select ATM, sum(refill_flag) as total_refills
    from final_cash_plan
    group by ATM;
quit;

/* Average cash level */
proc sql;
    select ATM, mean(current_cash) as avg_cash
    from final_cash_plan
    group by ATM;
quit;


/* ===================================================== */
/* END OF PROJECT */
/* ===================================================== */