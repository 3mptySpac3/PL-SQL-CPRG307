/*
  PL/SQL Financial Transaction Processing Script
  ----------------------------------------------
This script is made to handle and process financial transactions smoothly.
It plays a key role in the accounting system by carrying out a set of clear 
steps that make sure all financial information is correct and trustworthy.

  1. Enumerates all new transactions, providing a clear list of financial activities 
  that have not yet been processed for transparency and verification purposes.
  2. Iterates over each unprocessed transaction from the 'new_transactions' table, 
  performing the following actions for each:
  
     a. Retrieves the current balance for the associated account to ensure accurate 
     financial reporting.

     b. Adjusts account balances based on the transaction type: debiting (increasing) 
     the balance for 'D' type transactions and crediting (decreasing) for 'C' type 
     transactions, reflecting the financial impact of each transaction.

     c. Updates the account balances in the 'account' table to reflect the new transaction
     effects, ensuring that all financial records are up-to-date.

     d. Outputs detailed information about each transaction being processed to provide a transaction 
     log for auditing and record-keeping.

     e. Removes the processed transaction from the 'new_transactions' table to prevent reprocessing 
     and maintain the integrity of the transaction workflow.

  3. Upon successful processing of all transactions, commits the changes to the database to persist the updated financial state.
  4. In case of any errors during the transaction processing, catches exceptions, outputs the error information, and rolls back 
  any changes to maintain database consistency and integrity.
  5. Displays the updated balances for all accounts at the end of the script to provide an immediate view of the financial state post-transaction processing.

*/

@"C:\Users\thefa\OneDrive\Desktop\Database Prog\Assignment2\A2 Scripts\create_wkis.sql"
@"C:\Users\thefa\OneDrive\Desktop\Database Prog\Assignment2\A2 Scripts\constraints_wkis.sql"
@"C:\Users\thefa\OneDrive\Desktop\Database Prog\Assignment2\A2 Scripts\load_wkis.sql"
@"C:\Users\thefa\OneDrive\Desktop\Database Prog\Assignment2\A2 Scripts\A2_test dataset_1 - Clean.sql"


SET SERVEROUTPUT ON;
SET LINESIZE 100;
SET PAGESIZE 75;



DECLARE
    CURSOR transactions_cursor IS
        SELECT nt.transaction_no, nt.transaction_date, nt.description, nt.account_no, nt.transaction_type, nt.transaction_amount
        FROM new_transactions nt;

    v_trans_rec transactions_cursor%ROWTYPE;
    v_account_rec account%ROWTYPE;
    v_count NUMBER;

BEGIN
    -- Output new transactions before processing
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('NEW TRANSACTIONS BEFORE PROCESSING:');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
    FOR rec IN (SELECT * FROM new_transactions ORDER BY transaction_no DESC) LOOP
        DBMS_OUTPUT.PUT_LINE('Transaction No: ' || rec.transaction_no ||
                             ' Description: ' || rec.description);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');

    -- Process all transactions from new_transactions
    OPEN transactions_cursor;
    LOOP
        -- Fetch the next transaction
        FETCH transactions_cursor INTO v_trans_rec;
        EXIT WHEN transactions_cursor%NOTFOUND;

        -- Fetch the current account balance
        SELECT account_balance INTO v_account_rec.account_balance 
        FROM account WHERE account_no = v_trans_rec.account_no;

        -- Update account balances based on transactions
        IF v_trans_rec.transaction_type = 'D' THEN
            v_account_rec.account_balance := v_account_rec.account_balance + v_trans_rec.transaction_amount;
        ELSIF v_trans_rec.transaction_type = 'C' THEN
            v_account_rec.account_balance := v_account_rec.account_balance - v_trans_rec.transaction_amount;
        END IF;

        -- Check if transaction exists in transaction_history
        SELECT COUNT(*) INTO v_count FROM transaction_history WHERE transaction_no = v_trans_rec.transaction_no;


        -- If transaction does not exist in transaction_history, insert it
        IF v_count = 0 THEN
            -- Insert into TRANSACTION_HISTORY
            INSERT INTO transaction_history (transaction_no, transaction_date, description)
            VALUES (v_trans_rec.transaction_no, v_trans_rec.transaction_date, v_trans_rec.description);
        END IF;

        -- Insert into TRANSACTION_DETAIL
        INSERT INTO transaction_detail (account_no, transaction_no, transaction_type, transaction_amount)
        VALUES (v_trans_rec.account_no, v_trans_rec.transaction_no, v_trans_rec.transaction_type, v_trans_rec.transaction_amount);


        -- Update the account record
        UPDATE account SET account_balance = v_account_rec.account_balance
        WHERE account_no = v_trans_rec.account_no;

        -- Output transaction details
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Processing Transaction: ');
        DBMS_OUTPUT.PUT_LINE('Transaction No: ' || v_trans_rec.transaction_no);
        DBMS_OUTPUT.PUT_LINE('Description: ' || v_trans_rec.description);
        DBMS_OUTPUT.PUT_LINE('Account No: ' || v_trans_rec.account_no);
        DBMS_OUTPUT.PUT_LINE('Amount: ' || v_trans_rec.transaction_amount);
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------');

        -- Delete the processed transaction from new_transactions
        DELETE FROM new_transactions WHERE transaction_no = v_trans_rec.transaction_no;

    END LOOP;
    CLOSE transactions_cursor;

    COMMIT;

    -- Output the updated account balances after all transactions are processed
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
    FOR rec IN (SELECT * FROM account ORDER BY account_no) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Account No: ' || rec.account_no || 
            ' | Account Name: ' || rec.account_name ||
            ' __ Balance: ' || rec.account_balance
        );
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');


    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
        ROLLBACK; 
END;
/



COLUMN transaction_no FORMAT 9999;

SELECT * FROM transaction_detail;
SELECT * FROM transaction_history;
SELECT account_no, account_name, account_balance FROM account;