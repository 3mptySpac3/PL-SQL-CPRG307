SET SERVEROUTPUT ON;
SET LINESIZE 200;
SET PAGESIZE 100;


DECLARE
    CURSOR transactions_cursor IS
        SELECT nt.transaction_no, nt.transaction_date, nt.description, nt.account_no, nt.transaction_type, nt.transaction_amount
        FROM new_transactions nt;

    v_trans_rec transactions_cursor%ROWTYPE;
    v_account_balance NUMBER;
    v_default_trans_type CHAR(1);
    v_error_msg VARCHAR2(200);
    v_error_log_count NUMBER;
    v_total_debits NUMBER;
    v_total_credits NUMBER;
    

    -- Custom Exceptions
    e_missing_transaction_number EXCEPTION;
    e_invalid_account_number EXCEPTION;
    e_unbalanced_transaction EXCEPTION;
    e_invalid_transaction_type EXCEPTION;
    e_unique_constraint_violated EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_missing_transaction_number, -20001);
    PRAGMA EXCEPTION_INIT(e_invalid_account_number, -20002);
    PRAGMA EXCEPTION_INIT(e_unbalanced_transaction, -20003);
    PRAGMA EXCEPTION_INIT(e_invalid_transaction_type, -20004);
    PRAGMA EXCEPTION_INIT(e_unique_constraint_violated, -00001);

BEGIN

    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('NEW TRANSACTIONS BEFORE PROCESSING:');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');

    OPEN transactions_cursor;
    LOOP
        FETCH transactions_cursor INTO v_trans_rec;
        EXIT WHEN transactions_cursor%NOTFOUND;

         v_error_msg := NULL;

        BEGIN
            -- Check for NULL transaction number
            IF v_trans_rec.transaction_no IS NULL THEN
                v_error_msg := 'Missing transaction number';
                -- Log the error and skip further processing for this row
                INSERT INTO wkis_error_log (transaction_no, transaction_date, description, error_msg)
                VALUES (v_trans_rec.transaction_no, SYSDATE, v_trans_rec.description, v_error_msg);
                CONTINUE;
            END IF;

                -- Check for invalid account number
                SELECT COUNT(*) INTO v_error_log_count FROM account WHERE account_no = v_trans_rec.account_no;
                IF v_error_log_count = 0 THEN
                    v_error_msg := 'Invalid account number: ' || TO_CHAR(v_trans_rec.account_no);
                    INSERT INTO wkis_error_log (transaction_no, transaction_date, description, error_msg)
                    VALUES (v_trans_rec.transaction_no, SYSDATE, v_trans_rec.description, v_error_msg);
                    CONTINUE;
                END IF;

                    -- Check for invalid transaction type
            IF v_trans_rec.transaction_type NOT IN ('D', 'C') THEN
                v_error_msg := 'Invalid transaction type: ' || v_trans_rec.transaction_type;
                -- Log the error and skip further processing for this row
                INSERT INTO wkis_error_log (transaction_no, transaction_date, description, error_msg)
                VALUES (v_trans_rec.transaction_no, SYSDATE, v_trans_rec.description, v_error_msg);
                CONTINUE;
            END IF;

            IF v_total_debits <> v_total_credits THEN
                -- Log error for unbalanced transaction
                v_error_msg := 'Debits and credits not equal for new transaction no: ' || TO_CHAR(v_trans_rec.transaction_no);
                INSERT INTO wkis_error_log (transaction_no, transaction_date, description, error_msg)
                VALUES (v_trans_rec.transaction_no, SYSDATE, v_trans_rec.description, v_error_msg);
                CONTINUE;
            END IF;

            -- Check if transaction has already been processed
            SELECT COUNT(*) INTO v_error_log_count FROM transaction_history WHERE transaction_no = v_trans_rec.transaction_no;
            IF v_error_log_count > 0 THEN
                -- Transaction already processed, skip to next
                CONTINUE;
            END IF;

            -- Fetch the current account balance and default transaction type
            SELECT a.account_balance, at.default_trans_type INTO v_account_balance, v_default_trans_type
            FROM account a
            JOIN account_type at ON a.account_type_code = at.account_type_code
            WHERE a.account_no = v_trans_rec.account_no;

            -- Check if account number exists
            SELECT COUNT(*) INTO v_error_log_count FROM account WHERE account_no = v_trans_rec.account_no;
            IF v_error_log_count = 0 THEN
                -- If no account is found, raise the custom exception
                RAISE e_invalid_account_number;
            END IF;

            -- Check debits and credits are equal
            SELECT SUM(CASE WHEN transaction_type = 'D' THEN transaction_amount ELSE 0 END),
                   SUM(CASE WHEN transaction_type = 'C' THEN transaction_amount ELSE 0 END)
            INTO v_total_debits, v_total_credits
            FROM new_transactions
            WHERE transaction_no = v_trans_rec.transaction_no;

            IF v_total_debits <> v_total_credits THEN
                RAISE e_unbalanced_transaction;
            END IF;

            -- Insert into TRANSACTION_HISTORY and TRANSACTION_DETAIL
            INSERT INTO transaction_history (transaction_no, transaction_date, description)
            VALUES (v_trans_rec.transaction_no, v_trans_rec.transaction_date, v_trans_rec.description);

            INSERT INTO transaction_detail (account_no, transaction_no, transaction_type, transaction_amount)
            VALUES (v_trans_rec.account_no, v_trans_rec.transaction_no, v_trans_rec.transaction_type, v_trans_rec.transaction_amount);

            -- Update account balances based on transaction type and default transaction type
            IF v_trans_rec.transaction_type = v_default_trans_type THEN
                v_account_balance := v_account_balance + v_trans_rec.transaction_amount;
            ELSE
                v_account_balance := v_account_balance - v_trans_rec.transaction_amount;
            END IF;

            -- Update the account record
            UPDATE account SET account_balance = v_account_balance
            WHERE account_no = v_trans_rec.account_no;

            DBMS_OUTPUT.PUT_LINE('Processed Transaction No: ' || v_trans_rec.transaction_no);

            DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
            DBMS_OUTPUT.PUT_LINE('Processing Transaction: ');
            DBMS_OUTPUT.PUT_LINE('Transaction No: ' || v_trans_rec.transaction_no);
            DBMS_OUTPUT.PUT_LINE('Description: ' || v_trans_rec.description);
            DBMS_OUTPUT.PUT_LINE('Account No: ' || v_trans_rec.account_no);
            DBMS_OUTPUT.PUT_LINE('Amount: ' || v_trans_rec.transaction_amount);
            DBMS_OUTPUT.PUT_LINE('------------------------------------------------');

            -- Delete the processed transaction from new_transactions
            DELETE FROM new_transactions WHERE transaction_no = v_trans_rec.transaction_no;

        EXCEPTION
            -- Missing transaction number for account
            WHEN e_missing_transaction_number THEN
                v_error_msg := 'Missing transaction number for account ' || v_trans_rec.account_no;
                INSERT INTO wkis_error_log (transaction_no, transaction_date, description, error_msg)
                VALUES (v_trans_rec.transaction_no, SYSDATE, 'Missing transaction number', v_error_msg);
            -- Invalid account number

            WHEN e_invalid_account_number THEN
                v_error_msg := 'Invalid account number: ' || v_trans_rec.account_no;
                INSERT INTO wkis_error_log (transaction_no, transaction_date, description, error_msg)
                VALUES (v_trans_rec.transaction_no, SYSDATE, 'Invalid account number', v_error_msg);
            
            -- Invalid transaction type
            WHEN e_invalid_transaction_type THEN
                v_error_msg := 'Invalid transaction type for transaction no: ' || v_trans_rec.transaction_no;
                INSERT INTO wkis_error_log (transaction_no, transaction_date, description, error_msg)
                VALUES (v_trans_rec.transaction_no, SYSDATE, 'Invalid transaction type', v_error_msg);

            -- Unique constraint violated
            WHEN e_unique_constraint_violated THEN
                v_error_msg := 'Unique constraint violated for transaction no: ' || v_trans_rec.transaction_no;
                INSERT INTO wkis_error_log (transaction_no, transaction_date, description, error_msg)
                VALUES (v_trans_rec.transaction_no, SYSDATE, 'Unique constraint violated', v_error_msg);

            -- Unexpected error
            WHEN OTHERS THEN
                v_error_msg := 'Unexpected error for transaction no: ' || v_trans_rec.transaction_no || ' - ' || SQLERRM;
                INSERT INTO wkis_error_log (transaction_no, transaction_date, description, error_msg)
                VALUES (v_trans_rec.transaction_no, SYSDATE, 'Unexpected error', v_error_msg);
        END; 

    END LOOP;
    CLOSE transactions_cursor;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('UPDATED ACCOUNT BALANCES:');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');

    FOR rec IN (SELECT * FROM account ORDER BY account_no) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Account No: ' || rec.account_no || 
            ' | Account Name: ' || rec.account_name ||
            ' | Balance: ' || rec.account_balance
        );
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error occurred: ' || SQLERRM);
        ROLLBACK;
END;
/

COLUMN transaction_no FORMAT 9999 
COLUMN transaction_date FORMAT A20 HEADING 'Transaction Date'
COLUMN description FORMAT A45 TRUNCATED HEADING 'Description'
COLUMN error_msg FORMAT A75 TRUNCATED HEADING 'Error Message'
SELECT * FROM transaction_detail;
SELECT * FROM transaction_history;
SELECT account_no, account_name, account_balance FROM account;
SELECT * FROM wkis_error_log;

