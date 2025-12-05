-- Example: Longitudinal Viral Load extraction (MySQL 5.7 compatible)
-- Change the VL concept id and table/database names to match your instance.

SET @vl_concept_id = 856; -- adjust as needed

-- 1) Overall most recent VL per patient
CREATE OR REPLACE VIEW vl_overall AS
SELECT
  o.person_id AS patient_id,
  o.value_numeric AS last_vl_value,
  DATE(o.obs_datetime) AS last_vl_date
FROM obs o
WHERE o.concept_id = @vl_concept_id
  AND o.obs_datetime = (
    SELECT MAX(o2.obs_datetime)
    FROM obs o2
    WHERE o2.person_id = o.person_id
      AND o2.concept_id = @vl_concept_id
  );

-- 2) Year-specific most recent VL per patient (example for 2021-2024)
CREATE OR REPLACE VIEW vl_2021 AS
SELECT o.person_id AS patient_id, o.value_numeric AS vl_2021_value, DATE(o.obs_datetime) AS vl_2021_date
FROM obs o
WHERE o.concept_id = @vl_concept_id
  AND YEAR(o.obs_datetime) = 2021
  AND o.obs_datetime = (
    SELECT MAX(o2.obs_datetime)
    FROM obs o2
    WHERE o2.person_id = o.person_id
      AND o2.concept_id = @vl_concept_id
      AND YEAR(o2.obs_datetime) = 2021
  );

CREATE OR REPLACE VIEW vl_2022 AS
SELECT o.person_id AS patient_id, o.value_numeric AS vl_2022_value, DATE(o.obs_datetime) AS vl_2022_date
FROM obs o
WHERE o.concept_id = @vl_concept_id
  AND YEAR(o.obs_datetime) = 2022
  AND o.obs_datetime = (
    SELECT MAX(o2.obs_datetime)
    FROM obs o2
    WHERE o2.person_id = o.person_id
      AND o2.concept_id = @vl_concept_id
      AND YEAR(o2.obs_datetime) = 2022
  );

CREATE OR REPLACE VIEW vl_2023 AS
SELECT o.person_id AS patient_id, o.value_numeric AS vl_2023_value, DATE(o.obs_datetime) AS vl_2023_date
FROM obs o
WHERE o.concept_id = @vl_concept_id
  AND YEAR(o.obs_datetime) = 2023
  AND o.obs_datetime = (
    SELECT MAX(o2.obs_datetime)
    FROM obs o2
    WHERE o2.person_id = o.person_id
      AND o2.concept_id = @vl_concept_id
      AND YEAR(o2.obs_datetime) = 2023
  );

CREATE OR REPLACE VIEW vl_2024 AS
SELECT o.person_id AS patient_id, o.value_numeric AS vl_2024_value, DATE(o.obs_datetime) AS vl_2024_date
FROM obs o
WHERE o.concept_id = @vl_concept_id
  AND YEAR(o.obs_datetime) = 2024
  AND o.obs_datetime = (
    SELECT MAX(o2.obs_datetime)
    FROM obs o2
    WHERE o2.person_id = o.person_id
      AND o2.concept_id = @vl_concept_id
      AND YEAR(o2.obs_datetime) = 2024
  );

-- 3) Join together with patient identifiers and basic demographics
SELECT
  p.person_id AS patient_id,
  pid.identifier AS primary_identifier,
  p.gender,
  CASE
    WHEN TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) < 1 THEN CONCAT(TIMESTAMPDIFF(MONTH, p.birthdate, CURDATE()), 'm')
    ELSE TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE())
  END AS age,
  vo.last_vl_value,
  vo.last_vl_date,
  v21.vl_2021_value,
  v21.vl_2021_date,
  v22.vl_2022_value,
  v22.vl_2022_date,
  v23.vl_2023_value,
  v23.vl_2023_date,
  v24.vl_2024_value,
  v24.vl_2024_date
FROM person p
LEFT JOIN patient_identifier pid ON pid.patient_id = p.person_id
LEFT JOIN vl_overall vo ON vo.patient_id = p.person_id
LEFT JOIN vl_2021 v21 ON v21.patient_id = p.person_id
LEFT JOIN vl_2022 v22 ON v22.patient_id = p.person_id
LEFT JOIN vl_2023 v23 ON v23.patient_id = p.person_id
LEFT JOIN vl_2024 v24 ON v24.patient_id = p.person_id
WHERE pid.identifier IS NOT NULL
LIMIT 100; -- remove or change limit for full dataset

-- Cleanup: drop the views if you prefer not to keep them
-- DROP VIEW IF EXISTS vl_overall, vl_2021, vl_2022, vl_2023, vl_2024;
