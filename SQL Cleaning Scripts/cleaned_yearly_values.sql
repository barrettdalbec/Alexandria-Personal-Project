
DROP TABLE IF EXISTS cleaned_yearly_value_table;

CREATE TABLE cleaned_yearly_value_table AS
SELECT * FROM ava_yearly_sales_table;

ALTER TABLE cleaned_yearly_value_table
    ADD COLUMN levy_month INT,
    -- ADD COLUMN levy_day INT, There actually is no day in the date
    ADD COLUMN levy_year INT;

SELECT COUNT(*) AS invalid_date_count
FROM cleaned_yearly_value_table
WHERE date IS NULL
   OR TRIM(date) = ''
   OR NOT (
       date ~ '^\d{1,2}/\d{4}$'              -- MM/YYYY
       OR date ~ '^\d{1,2}/\d{1,2}/\d{4}$'   -- MM/DD/YYYY
);

DELETE FROM cleaned_yearly_value_table
WHERE date IS NULL
   OR TRIM(date) = ''
   OR NOT (
       date ~ '^\d{1,2}/\d{4}$'              -- MM/YYYY
       OR date ~ '^\d{1,2}/\d{1,2}/\d{4}$'   -- MM/DD/YYYY
);

SELECT COUNT(*) AS invalid_land_value
    FROM cleaned_yearly_value_table
        WHERE land_value !~ '^\s*\$?\d{1,3}(,\d{3})*(\.\d{2})?\s*$'
            OR building_value !~ '^\s*\$?\d{1,3}(,\d{3})*(\.\d{2})?\s*$'
            OR total_value !~ '^\s*\$?\d{1,3}(,\d{3})*(\.\d{2})?\s*$';

-- The above query checks for invalid land, building, or total values (0 missing values).; 

SELECT COUNT(*) AS invalid_zip_code
    FROM cleaned_yearly_value_table
        WHERE zip_code IS NULL
           OR TRIM(zip_code) = ''
           OR NOT zip_code ~ '^\d{5}$'; -- Assuming US ZIP codes
        
DELETE FROM cleaned_yearly_value_table
    WHERE ZIP_CODE IS NULL
       OR TRIM(zip_code) = ''
       OR NOT zip_code ~ '^\d{5}$'; 

UPDATE cleaned_yearly_value_table
    SET 
        levy_month = EXTRACT(MONTH FROM TO_DATE(date, 'MM/DD/YYYY')),
        levy_year = EXTRACT(DAY FROM TO_DATE(date, 'MM/DD/YYYY')), 
        land_value = TRIM(REPLACE(REPLACE(land_value, '$', ''), ',', '')),
        building_value = TRIM(REPLACE(REPLACE(building_value, '$', ''), ',', '')),
        total_value = TRIM(REPLACE(REPLACE(total_value, '$', ''), ',', ''));

UPDATE cleaned_yearly_value_table
    SET levy_year = levy_year + 2000; -- The 'DD' is actually the year, so '08' is '2008.'

ALTER TABLE cleaned_yearly_value_table
    DROP COLUMN date;

UPDATE cleaned_yearly_value_table
SET 
    building_value = REGEXP_REPLACE(building_value, '\s+', '', 'g'), -- Remove extra spaces (no "0  " errors)
    land_value = REGEXP_REPLACE(land_value, '\s+', '', 'g'),
    total_value = REGEXP_REPLACE(total_value, '\s+', '', 'g');

ALTER TABLE cleaned_yearly_value_table
    ALTER COLUMN building_value TYPE INTEGER
    USING building_value::INTEGER;

ALTER TABLE cleaned_yearly_value_table
    ALTER COLUMN land_value TYPE INTEGER
    USING land_value::INTEGER;

ALTER TABLE cleaned_yearly_value_table
    ALTER COLUMN total_value TYPE INTEGER
    USING total_value::INTEGER;

ALTER TABLE cleaned_yearly_value_table
    ALTER COLUMN zip_code TYPE INTEGER
    USING zip_code::INTEGER;

DELETE FROM cleaned_yearly_value_table
    WHERE zip_code NOT IN (22206, 22301, 22302, 22304, 22305, 22311, 22312, 22314);

SELECT 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name = 'cleaned_yearly_value_table';

-- Optional: If you want to view the cleaned data
SELECT * FROM cleaned_yearly_value_table