-- *********************************************************************

-- @"C:\Users\thefa\OneDrive\Desktop\Database Prog\Labs\Lab6\create_ata.sql"
-- @"C:\Users\thefa\OneDrive\Desktop\Database Prog\Labs\Lab6\constraints_ata.sql"
-- @"C:\Users\thefa\OneDrive\Desktop\Database Prog\Labs\Lab6\load_ata.sql"

-- *********************************************************************

/* *********************************************************************
**  Title:       lab6.sql
**  Author:      Jean-Pierre Nde-Forgwang
**  Created:     November 15, 2023
**  Description: This program attempts to complete the requirements for Lab 5.
**               It calculates the total fee for performances based on the 
**               performance duration, event type, and additional fees for 
**               performances on Mondays or Fridays.
********************************************************************* */

SET SERVEROUTPUT ON;

/*
-- Creates a function named func_performance_hours to calculate the total duration of performances for a given contract.
-- Input: contract_num (NUMBER) - The unique identifier for a contract.
-- Output: total_performance_duration (NUMBER) - The total duration of all performances associated with the contract.
-- The function iterates through each performance linked to the contract, calculates its duration (in hours), and sums these durations.
-- If no performance data is found for the contract, the function returns 0.
-- Any other exceptions encountered during execution are raised for further handling.
*/

CREATE OR REPLACE FUNCTION func_performance_hours(contract_num IN NUMBER)
RETURN NUMBER IS
    total_performance_duration NUMBER := 0;
BEGIN
    FOR rec IN (SELECT (stop_time - start_time) * 24 as duration
                FROM ata_performance
                WHERE contract_number = contract_num)
    LOOP
        total_performance_duration := total_performance_duration + ROUND(rec.duration, 2);
    END LOOP;

    RETURN total_performance_duration;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE;
END;
/

/*
-- Defines a function called func_hourly_rate to determine the hourly rate based on the event type.
-- Input: event_type (VARCHAR2) - The type of the event.
-- Output: hourly_rate (NUMBER) - The hourly rate associated with the event type.
-- The function uses a CASE statement to set the hourly_rate based on the event_type:
--   'Childrens Party' -> $335.00
--   'Concert' -> $1,000.00
--   'Divorce Party' -> $170.00
--   'Wedding' -> $300.00
--   Any other event type -> $100.00
-- Returns the determined hourly rate.
-- If any unexpected errors occur, they are raised for further handling.
*/

CREATE OR REPLACE FUNCTION func_hourly_rate(event_type IN VARCHAR2)
RETURN NUMBER IS
    hourly_rate NUMBER;
BEGIN
    CASE event_type
        WHEN 'Childrens Party' THEN hourly_rate := 335.00;
        WHEN 'Concert' THEN hourly_rate := 1000.00;
        WHEN 'Divorce Party' THEN hourly_rate := 170.00;
        WHEN 'Wedding' THEN hourly_rate := 300.00;
        ELSE hourly_rate := 100.00;
    END CASE;

    RETURN hourly_rate;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
/

/*
-- Creates a function named func_admin_fee to determine the administrative fee based on the performance date.
-- Input: performance_date (DATE) - The date of the performance.
-- Output: admin_fee (NUMBER) - The administrative fee, if applicable.
-- The function extracts the day of the week from the performance date.
-- If the performance is on a Monday ('MON') or Friday ('FRI'), an administrative fee of $100 is applied.
-- In all other cases, the admin fee is $0.
-- The function returns the calculated admin fee.
-- Any unexpected errors encountered during execution are raised for further handling.
*/

CREATE OR REPLACE FUNCTION func_admin_fee(performance_date IN DATE)
RETURN NUMBER IS
    day_of_week VARCHAR2(3);
    admin_fee NUMBER := 0;
BEGIN
    SELECT TO_CHAR(performance_date, 'DY')
    INTO day_of_week
    FROM DUAL;

    IF day_of_week IN ('MON', 'FRI') THEN
        admin_fee := 100;
    END IF;

    RETURN admin_fee;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
/

/*
-- Defines a function named func_total_fee to calculate the total fee for a given contract.
-- Input: contract_num (NUMBER) - The identifier for a specific contract.
-- Output: total_fee (NUMBER) - The total fee calculated for the contract.
-- The function iterates through each performance record associated with the contract.
-- For each performance, it:
--   Retrieves the hourly rate based on the event type using func_hourly_rate.
--   Calculates the performance duration in hours.
--   Determines the administrative fee, if applicable, for the performance date using func_admin_fee.
-- The total fee is calculated by summing the product of performance hours and hourly rate, plus any admin fees, for all performances.
-- The function returns the total fee calculated for the contract.
-- Any exceptions encountered during execution are raised for further handling.
*/
CREATE OR REPLACE FUNCTION func_total_fee(contract_num IN NUMBER)
RETURN NUMBER IS
    total_fee NUMBER := 0;
    hourly_rate NUMBER;
    performance_hours NUMBER;
    admin_fee NUMBER;
    performance_date DATE;
    event_type VARCHAR2(20);
BEGIN
    -- Loop through each performance record for the given contract number
    FOR rec IN (SELECT p.performance_date, p.start_time, p.stop_time, c.event_type
                FROM ata_performance p
                JOIN ata_contract c ON p.contract_number = c.contract_number
                WHERE c.contract_number = contract_num)
    LOOP
        -- Get the hourly rate
        hourly_rate := func_hourly_rate(rec.event_type);

        -- Calculate performance hours for this record
        performance_hours := (rec.stop_time - rec.start_time) * 24;

        -- Calculate admin fee for this record
        admin_fee := func_admin_fee(rec.performance_date);

        -- Add to total fee
        total_fee := total_fee + (performance_hours * hourly_rate) + admin_fee;
    END LOOP;

    RETURN total_fee;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
/

/*
-- Defines a procedure named proc_calculate_fee to update the total fees for all contracts in the ata_contract table.
-- The procedure uses two custom types: 
--   - contract_info_rec: A RECORD type to store a contract's number and its calculated total fee.
--   - contract_info_tbl: A TABLE type to hold multiple contract_info_rec records, indexed by contract number.
-- The procedure consists of two main parts:
--   1. Collection Phase: It loops through each contract in the ata_contract table, calculates the total fee for each using func_total_fee, and stores this data in the contract_info_tbl collection.
--   2. Update Phase: It then loops through the contract_info_tbl collection and updates the fee for each contract in the ata_contract table with the calculated total fee.
-- After updating all contracts, the procedure commits the changes to the database.
-- If any exception occurs during execution, the procedure rolls back any changes made and re-raises the exception for further handling.
*/

CREATE OR REPLACE PROCEDURE proc_calculate_fee IS
    TYPE contract_info_rec IS RECORD (
        contract_number ata_contract.contract_number%TYPE, 
        total_fee NUMBER
    );
    TYPE contract_info_tbl IS TABLE OF contract_info_rec INDEX BY PLS_INTEGER;
    contract_info contract_info_tbl;
BEGIN
    -- Collect contract numbers and calculate fees first
    FOR rec IN (SELECT contract_number FROM ata_contract)
    LOOP
        contract_info(rec.contract_number).contract_number := rec.contract_number;
        contract_info(rec.contract_number).total_fee := func_total_fee(rec.contract_number);
    END LOOP;

    -- Then update using the collected data
    FOR i IN 1 .. contract_info.COUNT LOOP
        UPDATE ata_contract
        SET fee = contract_info(i).total_fee
        WHERE contract_number = contract_info(i).contract_number;
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/



DECLARE
    hours NUMBER;
    hourly_rate NUMBER;
    admin_fee NUMBER;
    total_fee NUMBER;

BEGIN
    -- Loop through each distinct contract number
    FOR rec_contract IN (SELECT DISTINCT contract_number FROM ata_performance)
    LOOP
        -- Call the func_performance_hours function for each contract number
        hours := func_performance_hours(rec_contract.contract_number);

        -- Display the result
        DBMS_OUTPUT.PUT_LINE('Performance duration for contract [' || rec_contract.contract_number || ']: ' || hours || ' hours');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    -- Loop through each distinct event type
    FOR rec_event IN (SELECT DISTINCT event_type FROM ata_contract)
    LOOP
        -- Call the func_hourly_rate function for each event type
        hourly_rate := func_hourly_rate(rec_event.event_type);

        -- Display the result
        DBMS_OUTPUT.PUT_LINE('Hourly rate for event type [' || rec_event.event_type || ' = ' || hourly_rate || ']');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    FOR rec IN (SELECT DISTINCT performance_date FROM ata_performance)
    LOOP
        -- Call the func_admin_fee function for each performance date
        admin_fee := func_admin_fee(rec.performance_date);

        -- Display the result
        DBMS_OUTPUT.PUT_LINE('Admin fee for performance date [' || rec.performance_date || '] Admin fee  = ' || admin_fee || '');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    -- Loop through each distinct contract number
    FOR rec IN (SELECT DISTINCT contract_number FROM ata_contract)
    LOOP
        -- Call the func_total_fee function for each contract number
        total_fee := func_total_fee(rec.contract_number);

        -- Display the result
        DBMS_OUTPUT.PUT_LINE('Total fee for contract [' || rec.contract_number || '] = ' || total_fee);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    proc_calculate_fee;
    FOR rec IN (SELECT contract_number, fee FROM ata_contract)
    LOOP
        DBMS_OUTPUT.PUT_LINE('Updated total fee for contract [' || rec.contract_number || '] = ' || rec.fee);
    END LOOP;
END;
/
