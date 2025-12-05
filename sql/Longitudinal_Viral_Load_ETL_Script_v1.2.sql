use openmrs;
SET @lga :=    (SELECT global_property.property_value FROM global_property WHERE property = 'partner_reporting_lga_code');
SET @endDate := '2025-06-30';
SELECT
    (SELECT `state_province`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) AS State,
   (SELECT `name`  FROM  `address_hierarchy_entry` WHERE `user_generated_id` = @lga  LIMIT 1 ) LGA,
   (SELECT global_property.property_value FROM global_property WHERE	property = 'Facility_Datim_Code' LIMIT 1) AS Datim_Code,
  (SELECT global_property.property_value FROM global_property WHERE property='Facility_Name' LIMIT 1) AS FacilityName,
      pid.identifier as PEPFAR_ID,
    -- pivoted_data.person_id as Patient_ID,
    person.gender as Sex,
    IF(TIMESTAMPDIFF(YEAR,person.birthdate,CURDATE())>=5,TIMESTAMPDIFF(YEAR,person.birthdate,CURDATE()),NULL) AS `Current_Age`,
	IF(TIMESTAMPDIFF(YEAR,person.birthdate,CURDATE())<5,TIMESTAMPDIFF(MONTH,person.birthdate,CURDATE()),NULL) AS `CurrentAge_Months`,
    IF(DATE_ADD(MAX(IF(obs.concept_id=165708,DATE_FORMAT(enc.encounter_datetime,'%Y-%m-%d'),NULL)) ,INTERVAL (MAX(IF(obs.concept_id=159368,obs.value_numeric,NULL)) + 28) DAY) >= @endDate ,"Active","LTFU") AS `CurrentARTStatus_Pharmacy`,

  

    -- Overall Most Recent VL
    MAX(CASE WHEN pivoted_data.Result_Type = 'Overall_Most_Recent' THEN DATE_FORMAT(pivoted_data.obs_datetime, '%d/%m/%Y') END) AS `Current_VL_Date`,
    MAX(CASE WHEN pivoted_data.Result_Type = 'Overall_Most_Recent' THEN pivoted_data.Viral_Load END) AS `Current_Viral_Load`,

    -- 2024 Most Recent VL
    MAX(CASE WHEN pivoted_data.Result_Type = '2024_Most_Recent' THEN DATE_FORMAT(pivoted_data.obs_datetime, '%d/%m/%Y') END) AS `VL_Date_2024`,
    MAX(CASE WHEN pivoted_data.Result_Type = '2024_Most_Recent' THEN pivoted_data.Viral_Load END) AS `VL_Result_2024`,

    -- 2023 Most Recent VL
    MAX(CASE WHEN pivoted_data.Result_Type = '2023_Most_Recent' THEN DATE_FORMAT(pivoted_data.obs_datetime, '%d/%m/%Y') END) AS `VL_Date_2023`,
    MAX(CASE WHEN pivoted_data.Result_Type = '2023_Most_Recent' THEN pivoted_data.Viral_Load END) AS `VL_Result_2023`,

    -- 2022 Most Recent VL
    MAX(CASE WHEN pivoted_data.Result_Type = '2022_Most_Recent' THEN DATE_FORMAT(pivoted_data.obs_datetime, '%d/%m/%Y') END) AS `VL_Date_2022`,
    MAX(CASE WHEN pivoted_data.Result_Type = '2022_Most_Recent' THEN pivoted_data.Viral_Load END) AS `VL_Result_2022`,

    -- 2021 Most Recent VL
    MAX(CASE WHEN pivoted_data.Result_Type = '2021_Most_Recent' THEN DATE_FORMAT(pivoted_data.obs_datetime, '%d/%m/%Y') END) AS `VL_Date_2021`,
    MAX(CASE WHEN pivoted_data.Result_Type = '2021_Most_Recent' THEN pivoted_data.Viral_Load END) AS `VL_Result_2021`

FROM
    patient_identifier pid
    JOIN person on pid.patient_id = person.person_id

INNER JOIN
    -- This entire subquery (aliased as 'pivoted_data') replaces your temporary 'vl_trend_data' table
    (
        -- *** 1. Overall Most Recent ***
        SELECT
            o.person_id, o.obs_datetime, o.value_numeric AS Viral_Load, o.encounter_id, 'Overall_Most_Recent' AS Result_Type
        FROM obs o
        INNER JOIN (
            SELECT person_id, MAX(obs_datetime) AS max_date FROM obs WHERE concept_id = '856' GROUP BY person_id
        ) AS latest_obs ON o.person_id = latest_obs.person_id AND o.obs_datetime = latest_obs.max_date
        WHERE o.concept_id = '856' AND o.voided = 0

        UNION ALL

        -- *** 2. Most Recent in Year 2024 ***
        SELECT
            o.person_id, o.obs_datetime, o.value_numeric AS Viral_Load, o.encounter_id, '2024_Most_Recent' AS Result_Type
        FROM obs o
        INNER JOIN (
            SELECT person_id, MAX(obs_datetime) AS max_date FROM obs WHERE concept_id = '856' AND YEAR(obs_datetime) = 2024 GROUP BY person_id
        ) AS latest_obs ON o.person_id = latest_obs.person_id AND o.obs_datetime = latest_obs.max_date
        WHERE o.concept_id = '856' AND o.voided = 0

        UNION ALL

        -- *** 3. Most Recent in Year 2023 ***
        SELECT
            o.person_id, o.obs_datetime, o.value_numeric AS Viral_Load, o.encounter_id, '2023_Most_Recent' AS Result_Type
        FROM obs o
        INNER JOIN (
            SELECT person_id, MAX(obs_datetime) AS max_date FROM obs WHERE concept_id = '856' AND YEAR(obs_datetime) = 2023 GROUP BY person_id
        ) AS latest_obs ON o.person_id = latest_obs.person_id AND o.obs_datetime = latest_obs.max_date
        WHERE o.concept_id = '856' AND o.voided = 0

        UNION ALL

        -- *** 4. Most Recent in Year 2022 ***
        SELECT
            o.person_id, o.obs_datetime, o.value_numeric AS Viral_Load, o.encounter_id, '2022_Most_Recent' AS Result_Type
        FROM obs o
        INNER JOIN (
            SELECT person_id, MAX(obs_datetime) AS max_date FROM obs WHERE concept_id = '856' AND YEAR(obs_datetime) = 2022 GROUP BY person_id
        ) AS latest_obs ON o.person_id = latest_obs.person_id AND o.obs_datetime = latest_obs.max_date
        WHERE o.concept_id = '856' AND o.voided = 0

        UNION ALL

        -- *** 5. Most Recent in Year 2021 ***
        SELECT
            o.person_id, o.obs_datetime, o.value_numeric AS Viral_Load, o.encounter_id, '2021_Most_Recent' AS Result_Type
        FROM obs o
        INNER JOIN (
            SELECT person_id, MAX(obs_datetime) AS max_date FROM obs WHERE concept_id = '856' AND YEAR(obs_datetime) = 2021 GROUP BY person_id
        ) AS latest_obs ON o.person_id = latest_obs.person_id AND o.obs_datetime = latest_obs.max_date
        WHERE o.concept_id = '856' AND o.voided = 0
    ) AS pivoted_data 
    on (pid.patient_id = pivoted_data.person_id AND pid.identifier_type = 4 AND pid.voided = 0)
    JOIN obs on obs.person_id = pid.patient_id
    JOIN encounter enc on enc.encounter_id = obs.encounter_id

GROUP BY
    pivoted_data.person_id,
    pid.identifier
ORDER BY
    pid.identifier;