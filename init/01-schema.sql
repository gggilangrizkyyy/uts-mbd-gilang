CREATE SCHEMA IF NOT EXISTS salam;

CREATE TABLE salam.mahasiswas (
    id          SERIAL PRIMARY KEY,
    nim         VARCHAR(10)  NOT NULL UNIQUE,
    nama        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE,
    semester    INT NOT NULL CHECK (semester BETWEEN 1 AND 14),
    ipk         NUMERIC(3,2) NOT NULL CHECK (ipk BETWEEN 0 AND 4),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);