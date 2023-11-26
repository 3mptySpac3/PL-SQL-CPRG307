SET SERVEROUTPUT ON;

DECLARE

    -- Define constants for this block:
    -- 1. Job title for the president.
    -- 2. Percentage value for salary reduction.
    -- 3. Minimum threshold for salary.
    -- 4. Percentage value for salary increment.

    k_CONST_PRESIDENT_JOB_TITLE VARCHAR2(10) := 'PRESIDENT';
    k_CONST_25_PERCENT NUMBER := 0.25;
    k_CONST_100_DOLLARS NUMBER := 100;
    k_CONST_10_PERCENT NUMBER := 0.1;

    -- Variables to hold intermediate and final results:
    -- 1. The current salary of the president.
    -- 2. The average salary of all employees before any modifications.
    -- 3. The average salary of all employees after applying the salary rules.

    v_president_salary EMP_EMPLOYEE.SALARY%TYPE;
    v_pre_adjustment_average_salary NUMBER;
    v_post_adjustment_average_salary NUMBER;

BEGIN

    -- Retrieve the salary of the employee with the job title "PRESIDENT"

    SELECT SALARY INTO v_president_salary
    FROM EMP_EMPLOYEE
    WHERE JOB = k_CONST_PRESIDENT_JOB_TITLE;

    -- Calculate the current average salary for all employees.

    SELECT AVG(SALARY) INTO v_pre_adjustment_average_salary
    FROM EMP_EMPLOYEE;

    -- Rule 1: If an employee earns more than the president, their salary is reduced.
    -- The new salary becomes a certain percentage (75%) of the president's salary.

    UPDATE EMP_EMPLOYEE
    SET SALARY = v_president_salary * (1 - k_CONST_25_PERCENT)
    WHERE SALARY > v_president_salary
    AND JOB != k_CONST_PRESIDENT_JOB_TITLE;

    -- Rule 2: Employees earning below a certain threshold ($100) get a raise.
    -- The raise is a percentage increment of their current salary, but it shouldn't exceed the company's average salary.

    UPDATE EMP_EMPLOYEE
    SET SALARY = SALARY * (1 + k_CONST_10_PERCENT)
    WHERE SALARY < k_CONST_100_DOLLARS
    AND JOB != k_CONST_PRESIDENT_JOB_TITLE
    AND v_pre_adjustment_average_salary > SALARY * (1 + k_CONST_10_PERCENT);

    -- Recompute the average salary after applying the above salary rules.

    SELECT AVG(SALARY) INTO v_post_adjustment_average_salary
    FROM EMP_EMPLOYEE;

    -- Output the relevant details: The president's salary, and the average salaries before and after adjustments.

    DBMS_OUTPUT.PUT_LINE('President Salary: ' || ROUND(v_president_salary, 2));
    DBMS_OUTPUT.PUT_LINE('Pre-Adjustment Average Salary: ' || ROUND(v_pre_adjustment_average_salary, 2));
    DBMS_OUTPUT.PUT_LINE('Post-Adjustment Average Salary: ' || ROUND(v_post_adjustment_average_salary, 2));

END;
/
