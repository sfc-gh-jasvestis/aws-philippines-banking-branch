-- Validate the producer contract before building downstream objects.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

EXECUTE IMMEDIATE $$
DECLARE
  violations INTEGER;
  invalid_source EXCEPTION (-20001, 'Synthetic source failed grain or measure validation');
BEGIN
  SELECT COUNT(*) INTO :violations FROM (
    SELECT ENTITY_ID, EVENT_DATE
    FROM RAW.BRANCH_DAILY
    GROUP BY ENTITY_ID, EVENT_DATE HAVING COUNT(*) <> 1
    UNION ALL
    SELECT observation.ENTITY_ID, observation.EVENT_DATE
    FROM RAW.BRANCH_DAILY observation
    LEFT JOIN RAW.BRANCHES branch ON branch.ID = observation.ENTITY_ID
    WHERE branch.ID IS NULL OR observation.TXN_COUNT < 0
       OR observation.VALUE_PHP < 0
       OR observation.FAILED_COUNT < 0 OR observation.FAILED_COUNT > observation.INCIDENT_COUNT
       OR observation.INCIDENT_COUNT > observation.TXN_COUNT
       OR observation.SLA_BREACHED > observation.FAILED_COUNT
       OR observation.AUDIT_COMPLETED > observation.AUDIT_DUE
  );
  IF (violations > 0) THEN
    RAISE invalid_source;
  END IF;
END;
$$;
