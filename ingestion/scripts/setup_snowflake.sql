-- =============================================================================
-- Ecommerce Data Platform — Setup inicial de Snowflake
-- Ejecutar UNA sola vez con un usuario ACCOUNTADMIN
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Warehouse (motor de cómputo)
-- -----------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60          -- se apaga después de 60 segundos sin uso
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse principal del proyecto ecommerce';

-- -----------------------------------------------------------------------------
-- 2. Database
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS ECOMMERCE_DB
    COMMENT = 'Base de datos principal — plataforma Olist Brasil';

-- -----------------------------------------------------------------------------
-- 3. Schemas (las 3 capas de datos)
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DB.RAW
    COMMENT = 'Capa raw: tablas 1:1 con los CSVs de Olist sin transformar';

CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DB.STAGING
    COMMENT = 'Capa staging: limpieza, tipado, renaming y deduplicación';

CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DB.MARTS
    COMMENT = 'Capa marts: modelos dimensionales listos para BI';

-- -----------------------------------------------------------------------------
-- 4. Roles
-- -----------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS TRANSFORMER
    COMMENT = 'Rol usado por dbt para leer RAW y escribir STAGING y MARTS';

CREATE ROLE IF NOT EXISTS LOADER
    COMMENT = 'Rol usado por los scripts de ingesta para escribir en RAW';

CREATE ROLE IF NOT EXISTS REPORTER
    COMMENT = 'Rol de solo lectura en MARTS para herramientas de BI';

-- -----------------------------------------------------------------------------
-- 5. Usuario de servicio (reemplaza los valores antes de ejecutar)
-- -----------------------------------------------------------------------------
CREATE USER IF NOT EXISTS DBT_USER
    PASSWORD = 'CHANGE_ME'
    DEFAULT_ROLE = TRANSFORMER
    DEFAULT_WAREHOUSE = COMPUTE_WH
    COMMENT = 'Usuario de servicio para dbt';

CREATE USER IF NOT EXISTS LOADER_USER
    PASSWORD = 'CHANGE_ME'
    DEFAULT_ROLE = LOADER
    DEFAULT_WAREHOUSE = COMPUTE_WH
    COMMENT = 'Usuario de servicio para scripts de ingesta';

-- -----------------------------------------------------------------------------
-- 6. Permisos — LOADER (escribe en RAW)
-- -----------------------------------------------------------------------------
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE LOADER;
GRANT USAGE ON DATABASE ECOMMERCE_DB TO ROLE LOADER;
GRANT USAGE ON SCHEMA ECOMMERCE_DB.RAW TO ROLE LOADER;
GRANT CREATE TABLE ON SCHEMA ECOMMERCE_DB.RAW TO ROLE LOADER;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ECOMMERCE_DB.RAW TO ROLE LOADER;
GRANT INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA ECOMMERCE_DB.RAW TO ROLE LOADER;

-- -----------------------------------------------------------------------------
-- 7. Permisos — TRANSFORMER (lee RAW, escribe STAGING y MARTS)
-- -----------------------------------------------------------------------------
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORMER;
GRANT USAGE ON DATABASE ECOMMERCE_DB TO ROLE TRANSFORMER;

-- Leer RAW
GRANT USAGE ON SCHEMA ECOMMERCE_DB.RAW TO ROLE TRANSFORMER;
GRANT SELECT ON ALL TABLES IN SCHEMA ECOMMERCE_DB.RAW TO ROLE TRANSFORMER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA ECOMMERCE_DB.RAW TO ROLE TRANSFORMER;

-- Escribir STAGING
GRANT USAGE ON SCHEMA ECOMMERCE_DB.STAGING TO ROLE TRANSFORMER;
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA ECOMMERCE_DB.STAGING TO ROLE TRANSFORMER;
GRANT ALL ON ALL TABLES IN SCHEMA ECOMMERCE_DB.STAGING TO ROLE TRANSFORMER;
GRANT ALL ON FUTURE TABLES IN SCHEMA ECOMMERCE_DB.STAGING TO ROLE TRANSFORMER;

-- Escribir MARTS
GRANT USAGE ON SCHEMA ECOMMERCE_DB.MARTS TO ROLE TRANSFORMER;
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA ECOMMERCE_DB.MARTS TO ROLE TRANSFORMER;
GRANT ALL ON ALL TABLES IN SCHEMA ECOMMERCE_DB.MARTS TO ROLE TRANSFORMER;
GRANT ALL ON FUTURE TABLES IN SCHEMA ECOMMERCE_DB.MARTS TO ROLE TRANSFORMER;

-- -----------------------------------------------------------------------------
-- 8. Permisos — REPORTER (solo lectura en MARTS)
-- -----------------------------------------------------------------------------
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE REPORTER;
GRANT USAGE ON DATABASE ECOMMERCE_DB TO ROLE REPORTER;
GRANT USAGE ON SCHEMA ECOMMERCE_DB.MARTS TO ROLE REPORTER;
GRANT SELECT ON ALL TABLES IN SCHEMA ECOMMERCE_DB.MARTS TO ROLE REPORTER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA ECOMMERCE_DB.MARTS TO ROLE REPORTER;

-- -----------------------------------------------------------------------------
-- 9. Asignar roles a usuarios
-- -----------------------------------------------------------------------------
GRANT ROLE TRANSFORMER TO USER DBT_USER;
GRANT ROLE LOADER TO USER LOADER_USER;

-- -----------------------------------------------------------------------------
-- 10. Verificar setup
-- -----------------------------------------------------------------------------
SHOW SCHEMAS IN DATABASE ECOMMERCE_DB;
SHOW ROLES;
SHOW WAREHOUSES;
