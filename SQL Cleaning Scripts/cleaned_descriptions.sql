

-- Drop the existing table if it exists
DROP TABLE IF EXISTS cleaned_description_data;

-- Create a new table with the relevant columns from the existing sales data table
CREATE TABLE cleaned_description_data AS 
    SELECT * FROM ava_building_descriptions_table;

SELECT
    COUNT(*) FILTER (WHERE year_built IS NULL OR year_built IN ('UNKNOWN', 'NA')) AS invalid_year_built,
    COUNT(*) FILTER (WHERE construction_quality IS NULL OR construction_quality IN ('UNKNOWN', 'NA')) AS invalid_construction_quality,
    COUNT(*) FILTER (WHERE building_condition IS NULL OR building_condition IN ('UNKNOWN', 'NA')) AS invalid_building_condition,
    COUNT(*) FILTER (WHERE hvac IS NULL OR hvac IN ('UNKNOWN', 'NA')) AS invalid_hvac,
    COUNT(*) FILTER (WHERE building_type IS NULL OR building_type IN ('UNKNOWN', 'NA')) AS invalid_building_type,
    COUNT(*) FILTER (WHERE gross_building_area IS NULL OR gross_building_area IN ('UNKNOWN', 'NA')) AS invalid_gross_building_area,
    COUNT(*) FILTER (WHERE net_leasable_area IS NULL OR net_leasable_area IN ('UNKNOWN', 'NA')) AS invalid_net_leasable_area
FROM cleaned_description_data;

DELETE FROM cleaned_description_data
    WHERE year_built IS NULL OR year_built IN ('UNKNOWN', 'NA')
       OR construction_quality IS NULL OR construction_quality IN ('UNKNOWN', 'NA')
       OR building_condition IS NULL OR building_condition IN ('UNKNOWN', 'NA')
       OR hvac IS NULL OR hvac IN ('UNKNOWN', 'NA')
       OR building_type IS NULL OR building_type IN ('UNKNOWN', 'NA');

ALTER TABLE cleaned_description_data
    ALTER COLUMN year_built TYPE INTEGER
    USING year_built::INTEGER;

SELECT 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name = 'cleaned_description_data';

-- Optional: If you want to view the cleaned data
SELECT * FROM cleaned_description_data
LIMIT 10; -- Display the first 10 rows of the cleaned data

