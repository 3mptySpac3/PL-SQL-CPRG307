-- @ "C:\Users\thefa\OneDrive\Desktop\Database Prog\Unit 6 LoopingStruc\labs\create_emp.sql"
/*
|| Author: Jean-Pierre
|| Date: 10/10/23
|| Reason: Implementing Employee Salary and Commission Adjustment
||
|| Description: This PL/SQL block adjusts the salaries and commissions of employees in the EMP_EMPLOYEE table
|| according to the following three business rules specified by the company president:
||
||   1. [Rule 1] If an employee's salary exceeds that of the president, it should be adjusted to the lesser of 
||      two calculated amounts: either a 50% reduction or an amount that is 25% less than the president’s salary.
||
||   2. [Rule 2] If an employee earns less than $100, their salary should be boosted by 10%, under the condition that
||      their new salary does not surpass the original average company salary (calculated prior to any adjustments 
||      from Rule 1).
||
||   3. [Rule 3] If an employee’s commission surpasses 22% of their initial salary (before any alterations from Rules 
||      1 and 2), it should be adjusted to match the lowest commission within their department, excluding commissions 
||      that are valued at 0. No changes are applied to employees without a commission (NULL or 0).
*/


SET SERVEROUTPUT ON;

DECLARE

 -- Constants

k_PRESIDENT_TITLE CONSTANT VARCHAR2(10) := 'PRESIDENT';
k_PERCENT_50 CONSTANT NUMBER := 0.5;
k_PERCENT_25 CONSTANT NUMBER := 0.25;
k_100_DOLLARS CONSTANT NUMBER := 100;
k_PERCENT_10 CONSTANT NUMBER := 0.1;
k_PERCENT_22 CONSTANT NUMBER := 0.22;

-- Variables

v_president_salary EMP_EMPLOYEE.SALARY%TYPE;
v_avg_salary EMP_EMPLOYEE.SALARY%TYPE;
v_new_salary_50_percent EMP_EMPLOYEE.SALARY%TYPE;
v_new_salary_25_less_president EMP_EMPLOYEE.SALARY%TYPE;
v_lowest_commission EMP_EMPLOYEE.COMMISSION%TYPE;


 -- Cursor

CURSOR c_employee IS
  SELECT * FROM EMP_EMPLOYEE;

-- Record type variable for cursor data

r_employee c_employee%ROWTYPE;  

BEGIN

-- Retrieve the president's salary and company average salary

SELECT SALARY INTO v_president_salary FROM EMP_EMPLOYEE WHERE JOB = k_PRESIDENT_TITLE;
SELECT AVG(SALARY) INTO v_avg_salary FROM EMP_EMPLOYEE;

DBMS_OUTPUT.PUT_LINE('The president''s salary is: ' || v_president_salary);
DBMS_OUTPUT.PUT_LINE('The average company salary is: ' || v_avg_salary);

-- Loop through employees

OPEN c_employee;
LOOP

FETCH c_employee INTO r_employee;
EXIT WHEN c_employee%NOTFOUND;

-- Calculating reduced salaries

v_new_salary_50_percent := r_employee.SALARY * k_PERCENT_50;
v_new_salary_25_less_president := v_president_salary * (1 - k_PERCENT_25);

IF r_employee.JOB != k_PRESIDENT_TITLE THEN
    
-- Downwards adjustment for those earning more than the president

IF r_employee.SALARY > v_president_salary THEN
DBMS_OUTPUT.PUT_LINE('Adjusting salary downwards for: ' || r_employee.ENAME || ', Old Salary: ' || r_employee.SALARY);
    
-- Choosing the lesser of the two calculated salaries

r_employee.SALARY := LEAST(v_new_salary_50_percent, v_new_salary_25_less_president);
DBMS_OUTPUT.PUT_LINE('New Salary: ' || r_employee.SALARY);
END IF;

-- Upwards adjustment for those earning less than $100 and within 10% of average

IF r_employee.SALARY < k_100_DOLLARS AND r_employee.SALARY * (1 + k_PERCENT_10) <= v_avg_salary THEN
DBMS_OUTPUT.PUT_LINE('Adjusting salary upwards for: ' || r_employee.ENAME || ', Old Salary: ' || r_employee.SALARY);
    
r_employee.SALARY := r_employee.SALARY * (1 + k_PERCENT_10);
DBMS_OUTPUT.PUT_LINE('New Salary: ' || r_employee.SALARY);
END IF;

-- Rule 3: Adjusting commissions

IF r_employee.COMMISSION IS NOT NULL AND r_employee.COMMISSION > 0 AND 
r_employee.COMMISSION > r_employee.SALARY * k_PERCENT_22 THEN

-- Find the lowest non-zero commission within the department

SELECT MIN(COMMISSION) 
INTO v_lowest_commission 
FROM EMP_EMPLOYEE 
WHERE DEPTNO = r_employee.DEPTNO AND COMMISSION > 0;
   
DBMS_OUTPUT.PUT_LINE('Lowest Commission in Department ' || r_employee.DEPTNO || ': ' || v_lowest_commission);
   
-- Adjusting the employee's commission

r_employee.COMMISSION := v_lowest_commission;

-- Update statement

UPDATE EMP_EMPLOYEE
SET SALARY = r_employee.SALARY, COMMISSION = r_employee.COMMISSION
WHERE EMPNO = r_employee.EMPNO;

END IF;

END IF;

END LOOP;
CLOSE c_employee;

-- Commit the transaction

COMMIT;
    
END;
/


SET SERVEROUTPUT ON
 DECLARE      -- Constants      k_president_job CONSTANT VARCHAR2(10) := 'PRESIDENT';      k_salary_reduction CONSTANT NUMBER := 0.25;      k_salary_reduction2 CONSTANT NUMBER := 0.5;      k_salary_increase CONSTANT NUMBER := 1.10;      k_max_commission_percent CONSTANT NUMBER := 0.22;      -- Variables to hold calculated salaries
      v_president_salary NUMBER;
      v_average_salary NUMBER;
      v_lowest_salary NUMBER;
      v_lowest_commission NUMBER;
      v_department_name VARCHAR2(50);
      v_emp_total NUMBER;
      v_emp_total2 NUMBER;
  BEGIN
      -- Get the average salary of the company
      SELECT AVG(salary) INTO v_average_salary FROM EMP_EMPLOYEE;

      -- Get the president's salary
      SELECT salary INTO v_president_salary FROM EMP_EMPLOYEE  WHERE job = k_president_job;

      -- Display average salary and president's salary
      DBMS_OUTPUT.PUT_LINE('Average Company Salary: ' || TO_CHAR(v_average_salary));
      DBMS_OUTPUT.PUT_LINE('President''s Salary: ' || TO_CHAR(v_president_salary));

      -- Iterate over each employee
      FOR v_emp IN (SELECT * FROM EMP_EMPLOYEE  FOR UPDATE) LOOP
          -- Calculate new salaries based on conditions
          IF v_emp.salary > v_president_salary THEN
              v_emp_total := v_emp.salary * k_salary_reduction;
              v_emp_total2 := v_emp.salary * k_salary_reduction2;
              v_emp.salary := LEAST(v_emp_total, v_emp_total2);

              IF v_emp.salary < 100 AND v_average_salary > v_emp.salary THEN
                  v_lowest_salary := v_emp.salary * k_salary_increase;
                  v_emp.salary := v_lowest_salary;
              END IF;
          END IF;

         IF v_emp.commission > (v_emp.salary * k_max_commission_percent) THEN
             SELECT MIN(commission) INTO v_lowest_commission
             FROM emp_employee
             WHERE commission IS NOT NULL
             AND commission > 0
             AND deptno = v_emp.deptno;
             IF v_lowest_commission IS NOT NULL THEN
                 v_emp.commission := v_lowest_commission;
             END IF;
         END IF;

          -- Display the updated salary
          DBMS_OUTPUT.PUT_LINE('Updated salary for employee ' || v_emp.empno || ': ' || TO_CHAR(v_emp.salary));
          DBMS_OUTPUT.PUT_LINE('Updated commission for employee ' || v_emp.ename || ': ' || TO_CHAR(v_emp.commission));

          -- Update the employee's salary
          UPDATE emp_employee
          SET salary = v_emp.salary
          WHERE empno = v_emp.empno;

      END LOOP;

      -- Commit the transaction once after the loop to apply all changes
      COMMIT;
  END;
  /