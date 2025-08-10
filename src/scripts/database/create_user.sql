-- SQL script to create a new user and grant privileges

-- Create the user 'demasy' with a secure password
CREATE USER demasy IDENTIFIED BY demasy_password;

-- Grant necessary privileges to the user
GRANT CONNECT, RESOURCE TO demasy;

-- Grant additional privileges to the user
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE TO demasy;

-- Optional: Grant DBA privilege if needed
GRANT DBA TO demasy;
