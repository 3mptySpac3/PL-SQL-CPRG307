# PL/SQL Financial Transaction Processing Script with Enhanced Exception Handling

---

> This refined script elevates our fundamental financial transaction system by incorporating comprehensive error-checking mechanisms. It ensures the integrity of financial information and meticulously records any issues, forming an integral component of our accounting infrastructure that facilitates cautious money management and mitigates transactional errors.

### Key Features:

1. **Pre-Transaction Preparation**
   - Opens a cursor to select all entries from the 'new_transactions' table, preparing for transaction processing.

2. **Transactional Processing**
   - Iteratively processes each transaction while preserving financial accuracy:
     - Validates the existence of the transaction number.
     - Verifies the validity of the account number associated with each transaction.
     - Ensures the transaction type complies with accepted norms ('D' for debit, 'C' for credit).
     - Checks that debits and credits are balanced for each transaction.
     - Determines if a transaction has been previously processed to avoid duplication.
     - Fetches the current account balance and the default transaction type for processing alignment.
     - Updates account balances and reflects transactions in the 'account' table.
     - Maintains a historical log by recording transactions in 'transaction_history' and 'transaction_detail'.
     - Cleans up the 'new_transactions' table by removing processed entries.

3. **Exception Handling**
   - Implements robust exception handling to manage error scenarios, such as:
     - Defined exceptions for missing transaction numbers, invalid account numbers, and more.
     - Detailed error logging within the 'wkis_error_log' table.
     - Resilience in transaction processing with a system that continues after logging non-critical errors.
     - A generic catch-all exception handler for unforeseen errors.

4. **Post-Processing**
   - Commits all successful changes, confirming the updated financial state in the database.
   - Displays the updated account balances, offering a snapshot of the financial status post-transactions.

5. **Error Recovery**
   - Communicates any errors encountered and performs a rollback to maintain data integrity and consistency.

---

The script serves as a dependable tool for financial governance, ensuring precise execution of financial transactions while systematically documenting and handling exceptions.
