/* *********************************************************************
**  Title:       lab7.sql
**  Author:      Jean-Pierre
**  Created:     Renassiance
**  Description: This script is for Lab 7. It creates triggers for the 
**               library database. One trigger manages book reservations and 
**               another handles loan entries.
********************************************************************* */


--@"C:\Users\thefa\OneDrive\Desktop\Database Prog\Unit 10 StoredDataTriggers\WGL\create_wgl.sql"
--@"C:\Users\thefa\OneDrive\Desktop\Database Prog\Unit 10 StoredDataTriggers\WGL\constraints_wgl.sql"
--@"C:\Users\thefa\OneDrive\Desktop\Database Prog\Unit 10 StoredDataTriggers\WGL\load_wgl.sql"
--@"C:\Users\thefa\OneDrive\Desktop\Database Prog\Unit 10 StoredDataTriggers\WGL\new_books.sql"
--@"C:\Users\thefa\OneDrive\Desktop\Database Prog\Unit 10 StoredDataTriggers\WGL\newbookserrorlog.sql"

--@"C:\Users\thefa\OneDrive\Desktop\Database Prog\Unit 10 StoredDataTriggers\WGL\Lab7JP.sql"

DROP TRIGGER Im_bloody_triggerEdddd_reservelist;
DROP TRIGGER Im_bloody_triggerEdddd_loan;


Set serveroutput on;

-- Trigger for wgl_reserve_list table
CREATE OR REPLACE TRIGGER Im_bloody_triggerEdddd_reservelist
BEFORE INSERT ON wgl_reserve_list
FOR EACH ROW
DECLARE
    v_book_status VARCHAR2(2);
BEGIN
    -- Check the status of the book in the wgl_accession_register table
    SELECT status INTO v_book_status
    FROM wgl_accession_register
    WHERE isbn = :NEW.isbn
    AND branch_number = :NEW.branch_reserved_at;

    -- If the book is on the shelf, prevent insertion
    IF v_book_status = 'OS' THEN
        RAISE_APPLICATION_ERROR(-20001, 'We already have this book on the shelf... why are you reserving it?');
    ELSE
        -- If the book is not on the shelf, set the reservation date to the current date
        :NEW.date_reserved := SYSDATE;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Book or branch not found');
END;
/

-- Trigger for wgl_loan table
CREATE OR REPLACE TRIGGER Why_is_are_you_running_loan
BEFORE INSERT ON wgl_loan
FOR EACH ROW
DECLARE
    v_loan_period NUMBER;
BEGIN
    -- Generate loan number from sequence
    SELECT wgl_loan_seq.NEXTVAL INTO :NEW.loan_number FROM dual;

    -- Set loan date to current date
    :NEW.loan_date := SYSDATE;

    -- Retrieve loan period from wgl_accession_register
    SELECT loan_period INTO v_loan_period
    FROM wgl_accession_register
    WHERE accession_number = :NEW.accession_number;

    -- Calculate due date
    :NEW.due_date := :NEW.loan_date + v_loan_period;

    -- Update the accession register table
    UPDATE wgl_accession_register
    SET status = 'OL', due_date = :NEW.due_date
    WHERE accession_number = :NEW.accession_number;

    -- Update the patron's books on loan count
    UPDATE wgl_patron
    SET books_on_loan = books_on_loan + 1
    WHERE patron_number = :NEW.patron_number;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Accession number not found');
END;
/


SELECT * FROM wgl_reserve_list;   


--- TRIGER TEST ---
--3. Test and fire your trigger with the following two triggering INSERT statements:

INSERT INTO wgl_reserve_list
(patron_number, isbn, branch_reserved_at, pick_up_branch)
VALUES (2, '0-566-03538-3', 1, 2);

INSERT INTO wgl_reserve_list
(patron_number, isbn, branch_reserved_at, pick_up_branch)
VALUES (10, '0-88830-100-6', 1, 1);


--5. Test and fire your trigger with the following two triggering insert statements (remember the
--trigger should deal with the other columns not listed in the INSERTs below):

INSERT INTO wgl_loan
(patron_number, accession_number, loan_type)
VALUES(13, 25, 'O');

INSERT INTO wgl_loan
(patron_number, accession_number, loan_type)
VALUES (15, 2, 'O');



SELECT * FROM wgl_loan;
