
/* The following SQL script is designed to clean and transform a sales data table.
   It extracts relevant columns, creates a new table, and adds additional date-related columns. */

-- Drop the existing table if it exists
DROP TABLE IF EXISTS cleaned_sales_data;

-- Create a new table with the relevant columns from the existing sales data table
CREATE TABLE cleaned_sales_data AS 
    SELECT
        num,
        sale_year,
        sale_price
    FROM ava_sales_table;

-- Add new columns for month, day, and year extracted from sale_year
ALTER TABLE cleaned_sales_data
    ADD COLUMN sale_month INT,
    ADD COLUMN sale_day INT,
    ADD COLUMN sale_years INT;

-- Find the number of invalid sale_year entries 
SELECT COUNT(*) AS invalid_sale_year
    FROM cleaned_sales_data
        WHERE sale_year !~ '^\d{1,2}/\d{1,2}/\d{4}$'; -- This regex checks for the format MM/DD/YYYY 

-- Delete invalid sale_year entries not in the format MM/DD/YYYY 
DELETE FROM cleaned_sales_data
    WHERE sale_year !~ '^\d{1,2}/\d{1,2}/\d{4}$';

-- Update the sale_month, sale_day, and sale_years columns based on the cleaned sale_year
UPDATE cleaned_sales_data
    SET
        sale_month = EXTRACT(MONTH FROM TO_DATE(sale_year, 'MM/DD/YYYY')),
        sale_day = EXTRACT(DAY FROM TO_DATE(sale_year, 'MM/DD/YYYY')),
        sale_years = EXTRACT(YEAR FROM TO_DATE(sale_year, 'MM/DD/YYYY')); 

-- Remove the original sale_year column as it is no longer needed
ALTER TABLE cleaned_sales_data
    DROP COLUMN sale_year;

SELECT COUNT(*) AS invalid_sale_price
FROM cleaned_sales_data
WHERE sale_price !~ '^\s*\$?\d{1,3}(,\d{3})*(\.\d{2})?\s*$'; -- This regex checks for valid currency format

-- Delete invalid sale_price entries not in the valid currency format
DELETE FROM cleaned_sales_data
    WHERE sale_price !~ '^\s*\$?\d{1,3}(,\d{3})*(\.\d{2})?\s*$';

UPDATE cleaned_sales_data
    SET 
        sale_price = REPLACE(REPLACE(sale_price, '$', ''), ',', ''); -- Remove dollar signs and commas from sale_price

ALTER TABLE cleaned_sales_data
    ALTER COLUMN sale_price TYPE INTEGER
    USING sale_price::INTEGER; -- Convert sale_price to INTEGER type

SELECT 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name = 'cleaned_sales_data';

-- Optional: If you want to view the cleaned data
SELECT * FROM cleaned_sales_data
LIMIT 10; -- Display the first 10 rows of the cleaned data






