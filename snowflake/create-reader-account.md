```sql
-- create a new reader account.
USE ROLE ACCOUNTADMIN;
CREATE MANAGED ACCOUNT A_NON_SF_ACCOUNT TYPE=READER, 
ADMIN_NAME = 'READER_ADMIN', 
ADMIN_PASSWORD='<password_of_your_choice>';
```