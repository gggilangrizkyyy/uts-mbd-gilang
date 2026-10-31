-- Buat user
CREATE ROLE backend_dev   LOGIN PASSWORD 'backend123';
CREATE ROLE bi_dev        LOGIN PASSWORD 'bi123';
CREATE ROLE data_engineer LOGIN PASSWORD 'de123';

-- Akses dasar
GRANT CONNECT ON DATABASE uts_mbd TO backend_dev, bi_dev, data_engineer;
GRANT USAGE ON SCHEMA salam TO backend_dev, bi_dev;

-- backend_dev: CRUD semua tabel
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA salam TO backend_dev;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA salam TO backend_dev;

-- bi_dev: read only
GRANT SELECT ON ALL TABLES IN SCHEMA salam TO bi_dev;

-- data_engineer: DDL + CRUD (jadikan owner supaya bisa ALTER/DROP)
ALTER SCHEMA salam OWNER TO data_engineer;
ALTER TABLE salam.mahasiswas OWNER TO data_engineer;
ALTER SEQUENCE salam.mahasiswas_id_seq OWNER TO data_engineer;

-- Biar objek baru otomatis ikut ter-grant
ALTER DEFAULT PRIVILEGES FOR ROLE data_engineer IN SCHEMA salam
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO backend_dev;
ALTER DEFAULT PRIVILEGES FOR ROLE data_engineer IN SCHEMA salam
  GRANT SELECT ON TABLES TO bi_dev;