/*
|| Author: Jean-Pierre
|| Date: 1/11/23
|| Reason: Implementing 

|| Description: This PL/SQL block is designed to adjust the salaries and commissions of employees in the EMP_EMPLOYEE table
|| according to four business rules specified by the company president:

||   1. [Rule 1] If an employee's salary is higher than the president's, their salary is reduced by either 50% or to a value 
||      that is 25% less than the president's salary, whichever results in a lower salary.

||   2. [Rule 2] Employees earning less than $100 have their salary increased by 10%, provided that the raised salary does not 
||      exceed the original average salary of the company (calculated before any adjustments from Rule 1).

||   3. [Rule 3] If an employee's commission is more than 22% of their original salary (before adjustments from Rules 1 and 2),
||      their commission is adjusted to the lowest non-zero commission within their department.

||   4. [Rule 4] If an employee's department has no manager, an error is raised, and any changes resulting from applying Rules 1-3 
||      are rolled back for that employee. However, this rule does not prevent other employees from being processed.

|| The code uses a cursor to iterate over employees, applies the specified rules, and maintains transactional integrity with 
|| appropriate COMMIT and ROLLBACK statements. It also handles exceptions and ensures that the process continues even if 
|| individual employees do not meet the criteria for adjustment.
*/

-- @ "C:\Users\thefa\OneDrive\Desktop\Database Prog\Unit 6 LoopingStruc\labs\create_emp.sql"

SET SERVEROUTPUT ON;

DECLARE
    -- Constants as per the problem statement
    k_CONST_PRESIDENT_JOB_TITLE CONSTANT VARCHAR2(10) := 'PRESIDENT';
    k_CONST_MANAGER_JOB_TITLE CONSTANT VARCHAR2(10) := 'MANAGER';
    k_CONST_50_PERCENT CONSTANT NUMBER := 0.5;
    k_CONST_25_PERCENT CONSTANT NUMBER := 0.25;
    k_CONST_100_DOLLARS CONSTANT NUMBER := 100;
    k_CONST_10_PERCENT CONSTANT NUMBER := 0.1;
    k_CONST_22_PERCENT CONSTANT NUMBER := 0.22;

    -- Variables to hold intermediate and final results
    v_president_salary EMP_EMPLOYEE.SALARY%TYPE;
    v_original_average_salary NUMBER;
    v_lowest_commission EMP_EMPLOYEE.COMMISSION%TYPE;
    v_has_manager NUMBER;

    -- Cursor to iterate over employees
    CURSOR employee_cursor IS
        SELECT EMPNO, SALARY, COMMISSION, DEPTNO
        FROM EMP_EMPLOYEE
        WHERE JOB != k_CONST_PRESIDENT_JOB_TITLE;

BEGIN
    -- Retrieve the president's salary
    SELECT SALARY INTO v_president_salary
    FROM EMP_EMPLOYEE
    WHERE JOB = k_CONST_PRESIDENT_JOB_TITLE;

    -- Calculate the original average salary for all employees
    SELECT AVG(SALARY) INTO v_original_average_salary
    FROM EMP_EMPLOYEE;

    -- Display the president's salary and original average salary
    DBMS_OUTPUT.PUT_LINE('President Salary: ' || v_president_salary);
    DBMS_OUTPUT.PUT_LINE('Original Average Salary: ' || v_original_average_salary || CHR(10));

    -- Loop through each employee
    FOR employee_rec IN employee_cursor LOOP
        -- Check if the employee's department has a manager
        -- This is done by counting the number of employees in the same department
        -- who have the job title of 'MANAGER'
        SELECT COUNT(*)
        INTO v_has_manager
        FROM EMP_EMPLOYEE
        WHERE DEPTNO = employee_rec.DEPTNO  -- Filter by the current employee's department number
        AND JOB = k_CONST_MANAGER_JOB_TITLE;  -- Filter by the job title 'MANAGER'

        -- If the department has no manager, raise an error and continue with the next employee
        IF v_has_manager = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Employee ' || employee_rec.EMPNO || ' has no manager. Changes rolled back.' || CHR(10));
            DBMS_OUTPUT.NEW_LINE;
            CONTINUE;
        END IF;

        -- Rule 1: Reduce salary if it's higher than the president's
        IF employee_rec.SALARY > v_president_salary THEN
            UPDATE EMP_EMPLOYEE
            SET SALARY = LEAST(employee_rec.SALARY * k_CONST_50_PERCENT, v_president_salary * (1 - k_CONST_25_PERCENT))
            WHERE EMPNO = employee_rec.EMPNO;
            DBMS_OUTPUT.PUT_LINE('Salary reduced for employee ' || employee_rec.EMPNO || ' to ' || LEAST(employee_rec.SALARY * k_CONST_50_PERCENT, v_president_salary * (1 - k_CONST_25_PERCENT)));
            DBMS_OUTPUT.NEW_LINE;
        END IF;

        -- Rule 2: Increase salary if it's less than $100
        IF employee_rec.SALARY < k_CONST_100_DOLLARS AND v_original_average_salary > employee_rec.SALARY * (1 + k_CONST_10_PERCENT) THEN
            UPDATE EMP_EMPLOYEE
            SET SALARY = employee_rec.SALARY * (1 + k_CONST_10_PERCENT)
            WHERE EMPNO = employee_rec.EMPNO;
            DBMS_OUTPUT.PUT_LINE('Salary increased for employee ' || employee_rec.EMPNO || ' to ' || employee_rec.SALARY * (1 + k_CONST_10_PERCENT));
            DBMS_OUTPUT.NEW_LINE;
        END IF;

        -- Rule 3: Adjust commission if it's more than 22% of the original salary
        IF employee_rec.COMMISSION > employee_rec.SALARY * k_CONST_22_PERCENT THEN
            -- Get the lowest non-zero commission in the department
            SELECT MIN(COMMISSION)
            INTO v_lowest_commission
            FROM EMP_EMPLOYEE
            WHERE DEPTNO = employee_rec.DEPTNO
            AND COMMISSION > 0;

            -- Update the commission
            UPDATE EMP_EMPLOYEE
            SET COMMISSION = v_lowest_commission
            WHERE EMPNO = employee_rec.EMPNO;
            DBMS_OUTPUT.PUT_LINE('Commission adjusted for employee ' || employee_rec.EMPNO || ' to ' || v_lowest_commission || CHR(10));
            DBMS_OUTPUT.NEW_LINE;
        END IF;

        -- Display the updated salary for the current employee
        DBMS_OUTPUT.PUT_LINE('Updated salary for employee ' || employee_rec.EMPNO || ': ' || employee_rec.SALARY);
        DBMS_OUTPUT.NEW_LINE;

        -- Display the updated commission for the current employee
        DBMS_OUTPUT.PUT_LINE('Updated commission for employee ' || employee_rec.EMPNO || ': ' || employee_rec.COMMISSION || CHR(10));
        DBMS_OUTPUT.NEW_LINE;
    END LOOP;

    -- Commit the changes at the end of processing all employees
    COMMIT;

    -- Display a message indicating the completion of the process
    DBMS_OUTPUT.PUT_LINE('Salary adjustment process completed.');
    DBMS_OUTPUT.NEW_LINE;

EXCEPTION
    WHEN OTHERS THEN
        -- In case of any exception, roll back the changes and display an error message
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

