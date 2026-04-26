-- ============================================================
-- RECRUITMENT FUNNEL ANALYSIS — SQL QUERIES
-- Author: Anannya Anesweta Rout
-- Project: HR Recruitment Analytics | Business Analyst Portfolio
-- ============================================================

-- ============================================================
-- SECTION 1: FUNNEL OVERVIEW — How many candidates at each stage?
-- ============================================================

-- Q1. Total candidates at each stage (funnel drop-off)
SELECT
    final_stage,
    COUNT(*) AS total_candidates,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM recruitment_data
GROUP BY final_stage
ORDER BY
    CASE final_stage
        WHEN 'Applied'            THEN 1
        WHEN 'Screened'           THEN 2
        WHEN 'Interview Round 1'  THEN 3
        WHEN 'Interview Round 2'  THEN 4
        WHEN 'HR Round'           THEN 5
        WHEN 'Offer Made'         THEN 6
        WHEN 'Hired'              THEN 7
    END;


-- Q2. Overall hire rate and offer acceptance rate
SELECT
    COUNT(*)                                        AS total_applicants,
    SUM(offer_made)                                 AS total_offers,
    SUM(hired)                                      AS total_hired,
    ROUND(SUM(hired) * 100.0 / COUNT(*), 1)         AS overall_hire_rate_pct,
    ROUND(SUM(hired) * 100.0 / NULLIF(SUM(offer_made), 0), 1) AS offer_acceptance_rate_pct
FROM recruitment_data;


-- ============================================================
-- SECTION 2: SOURCE EFFECTIVENESS — Which channel brings the best hires?
-- ============================================================

-- Q3. Hire rate by recruitment source
SELECT
    source,
    COUNT(*)                                                AS total_applicants,
    SUM(hired)                                              AS hired,
    ROUND(SUM(hired) * 100.0 / COUNT(*), 1)                 AS hire_rate_pct,
    ROUND(AVG(CASE WHEN hired = 1 THEN time_to_hire_days END), 1) AS avg_days_to_hire
FROM recruitment_data
GROUP BY source
ORDER BY hire_rate_pct DESC;


-- Q4. Cost-efficiency proxy: which source needs fewest candidates per hire?
SELECT
    source,
    COUNT(*)                                    AS applicants,
    SUM(hired)                                  AS hires,
    ROUND(COUNT(*) * 1.0 / NULLIF(SUM(hired), 0), 1) AS applicants_per_hire
FROM recruitment_data
GROUP BY source
ORDER BY applicants_per_hire ASC;


-- ============================================================
-- SECTION 3: DEPARTMENT ANALYSIS — Where is hiring hardest?
-- ============================================================

-- Q5. Hiring performance by department
SELECT
    department,
    COUNT(*)                                    AS total_applicants,
    SUM(hired)                                  AS total_hired,
    ROUND(SUM(hired) * 100.0 / COUNT(*), 1)     AS hire_rate_pct,
    ROUND(AVG(CASE WHEN hired = 1 THEN time_to_hire_days END), 0) AS avg_days_to_hire
FROM recruitment_data
GROUP BY department
ORDER BY hire_rate_pct DESC;


-- Q6. Which department has the most drop-off at screening?
SELECT
    department,
    COUNT(*) AS applied,
    SUM(CASE WHEN final_stage = 'Applied' THEN 1 ELSE 0 END) AS dropped_at_application,
    ROUND(SUM(CASE WHEN final_stage = 'Applied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1) AS early_dropoff_pct
FROM recruitment_data
GROUP BY department
ORDER BY early_dropoff_pct DESC;


-- ============================================================
-- SECTION 4: TIME TO HIRE — Where are the delays?
-- ============================================================

-- Q7. Average time to hire overall and by department
SELECT
    department,
    ROUND(AVG(CASE WHEN hired = 1 THEN time_to_hire_days END), 0) AS avg_days_to_hire,
    MIN(CASE WHEN hired = 1 THEN time_to_hire_days END)            AS fastest_hire,
    MAX(CASE WHEN hired = 1 THEN time_to_hire_days END)            AS slowest_hire
FROM recruitment_data
GROUP BY department
ORDER BY avg_days_to_hire DESC;


-- Q8. Time to hire by source — are referrals faster?
SELECT
    source,
    ROUND(AVG(CASE WHEN hired = 1 THEN time_to_hire_days END), 0) AS avg_days_to_hire,
    SUM(hired) AS total_hires
FROM recruitment_data
GROUP BY source
HAVING SUM(hired) > 0
ORDER BY avg_days_to_hire ASC;


-- ============================================================
-- SECTION 5: REJECTION ANALYSIS — Why are candidates dropping out?
-- ============================================================

-- Q9. Top rejection reasons overall
SELECT
    rejection_reason,
    COUNT(*) AS frequency,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM recruitment_data
WHERE rejection_reason != 'N/A'
GROUP BY rejection_reason
ORDER BY frequency DESC;


-- Q10. Rejection reasons by stage — where does each problem appear?
SELECT
    final_stage,
    rejection_reason,
    COUNT(*) AS count
FROM recruitment_data
WHERE rejection_reason NOT IN ('N/A')
GROUP BY final_stage, rejection_reason
ORDER BY final_stage, count DESC;


-- ============================================================
-- SECTION 6: MONTHLY TRENDS — Is hiring improving over time?
-- ============================================================

-- Q11. Monthly applications and hires trend
SELECT
    apply_month,
    COUNT(*)            AS applications,
    SUM(hired)          AS hires,
    ROUND(SUM(hired) * 100.0 / COUNT(*), 1) AS hire_rate_pct
FROM recruitment_data
GROUP BY apply_month, apply_quarter
ORDER BY MIN(apply_date);


-- Q12. Quarterly hiring summary
SELECT
    apply_quarter,
    COUNT(*)            AS total_applicants,
    SUM(hired)          AS total_hired,
    ROUND(SUM(hired) * 100.0 / COUNT(*), 1) AS hire_rate_pct,
    ROUND(AVG(CASE WHEN hired = 1 THEN time_to_hire_days END), 0) AS avg_days_to_hire
FROM recruitment_data
GROUP BY apply_quarter
ORDER BY apply_quarter;


-- ============================================================
-- SECTION 7: SALARY INSIGHTS
-- ============================================================

-- Q13. Average expected salary of hired vs rejected candidates
SELECT
    CASE WHEN hired = 1 THEN 'Hired' ELSE 'Not Hired' END AS outcome,
    ROUND(AVG(expected_salary_lpa), 1)  AS avg_expected_salary_lpa,
    ROUND(MIN(expected_salary_lpa), 1)  AS min_salary,
    ROUND(MAX(expected_salary_lpa), 1)  AS max_salary
FROM recruitment_data
GROUP BY hired;


-- Q14. Salary expectation vs hire rate by department
SELECT
    department,
    ROUND(AVG(expected_salary_lpa), 1)                          AS avg_expected_salary_lpa,
    ROUND(AVG(CASE WHEN hired = 1 THEN expected_salary_lpa END), 1) AS avg_salary_hired,
    SUM(hired)                                                   AS hires
FROM recruitment_data
GROUP BY department
ORDER BY avg_expected_salary_lpa DESC;
