-- =============================================================================
-- Ecommerce Data Platform — Storage Integration S3 ↔ Snowflake
-- Ejecutar UNA sola vez con rol ACCOUNTADMIN
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;

-- -----------------------------------------------------------------------------
-- 1. Storage Integration (conexión de confianza Snowflake ↔ AWS S3)
--    Permite a Snowflake leer S3 sin credenciales hardcodeadas.
-- -----------------------------------------------------------------------------
CREATE STORAGE INTEGRATION IF NOT EXISTS snowflake_s3_integration
    TYPE                      = EXTERNAL_STAGE
    STORAGE_PROVIDER          = 'S3'
    ENABLED                   = TRUE
    STORAGE_AWS_ROLE_ARN      = 'arn:aws:iam::194644528609:role/snowflake-s3-role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://ecommerce-olist-raw/');

-- -----------------------------------------------------------------------------
-- 2. Obtener los valores para actualizar el Trust Policy en AWS IAM
--    Copiar STORAGE_AWS_IAM_USER_ARN y STORAGE_AWS_EXTERNAL_ID
--    y actualizar el trust policy del rol snowflake-s3-role en AWS.
-- -----------------------------------------------------------------------------
DESC INTEGRATION snowflake_s3_integration;

-- -----------------------------------------------------------------------------
-- 3. Permisos sobre la integración al rol LOADER
-- -----------------------------------------------------------------------------
GRANT USAGE ON INTEGRATION snowflake_s3_integration TO ROLE LOADER;

-- -----------------------------------------------------------------------------
-- 4. External Stage (apunta al bucket S3)
--    Se crea DESPUÉS de actualizar el trust policy en AWS.
-- -----------------------------------------------------------------------------
CREATE STAGE IF NOT EXISTS ECOMMERCE_DB.RAW.s3_stage
    URL                 = 's3://ecommerce-olist-raw/raw/olist/'
    STORAGE_INTEGRATION = snowflake_s3_integration
    FILE_FORMAT         = (
        TYPE                            = CSV
        SKIP_HEADER                     = 1
        FIELD_OPTIONALLY_ENCLOSED_BY    = '"'
        NULL_IF                         = ('', 'NULL', 'null', 'None')
        ERROR_ON_COLUMN_COUNT_MISMATCH  = FALSE
        ENCODING                        = 'UTF-8'
    )
    COMMENT = 'Stage externo apuntando al bucket S3 con los CSVs de Olist';

-- -----------------------------------------------------------------------------
-- 5. Verificar
-- -----------------------------------------------------------------------------
LIST @ECOMMERCE_DB.RAW.s3_stage;
