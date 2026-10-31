-- =====================================================================
-- FITUR TAMBAHAN (pembeda) - UTS Manajemen Basis Data
-- Simpan sebagai init/03-fitur-tambahan.sql
-- Dijalankan sebagai postgres, setelah 01-schema.sql dan 02-roles.sql
-- =====================================================================

-- Biar objek baru milik data_engineer otomatis bisa dipakai backend_dev
-- (tabel/view sudah ditangani default privileges di 02-roles.sql;
--  sequence belum, jadi ditambah di sini)
ALTER DEFAULT PRIVILEGES FOR ROLE data_engineer IN SCHEMA salam
  GRANT USAGE, SELECT ON SEQUENCES TO backend_dev;

-- Semua objek baru dibuat oleh data_engineer (sesuai aturan owner = DDL)
SET ROLE data_engineer;

-- ---------------------------------------------------------------------
-- 1) Tabel tambahan dengan foreign key ke mahasiswas
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS salam.matkul (
    id    SERIAL PRIMARY KEY,
    kode  VARCHAR(10)  NOT NULL UNIQUE,
    nama  VARCHAR(100) NOT NULL,
    sks   INT NOT NULL CHECK (sks BETWEEN 1 AND 6)
);

CREATE TABLE IF NOT EXISTS salam.krs (
    id              SERIAL PRIMARY KEY,
    mahasiswa_id    INT NOT NULL REFERENCES salam.mahasiswas(id) ON DELETE CASCADE,
    matkul_id       INT NOT NULL REFERENCES salam.matkul(id)     ON DELETE RESTRICT,
    tahun_akademik  VARCHAR(9) NOT NULL,
    nilai           VARCHAR(2) CHECK (nilai IN ('A','AB','B','BC','C','D','E')),
    UNIQUE (mahasiswa_id, matkul_id, tahun_akademik)
);

-- ---------------------------------------------------------------------
-- 2) Audit log + trigger pada mahasiswas (INSERT / UPDATE / DELETE)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS salam.audit_log (
    id          BIGSERIAL PRIMARY KEY,
    tabel       VARCHAR(50) NOT NULL,
    aksi        VARCHAR(10) NOT NULL,
    data_lama   JSONB,
    data_baru   JSONB,
    oleh        TEXT      NOT NULL DEFAULT current_user,
    waktu       TIMESTAMP NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION salam.fn_audit_mahasiswas()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO salam.audit_log (tabel, aksi, data_baru)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO salam.audit_log (tabel, aksi, data_lama, data_baru)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSE
        INSERT INTO salam.audit_log (tabel, aksi, data_lama)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD));
        RETURN OLD;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_mahasiswas ON salam.mahasiswas;
CREATE TRIGGER trg_audit_mahasiswas
AFTER INSERT OR UPDATE OR DELETE ON salam.mahasiswas
FOR EACH ROW EXECUTE FUNCTION salam.fn_audit_mahasiswas();

-- ---------------------------------------------------------------------
-- 3) View
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW salam.v_mahasiswa_cumlaude AS
SELECT nim, nama, semester, ipk
FROM salam.mahasiswas
WHERE ipk >= 3.5;

CREATE OR REPLACE VIEW salam.v_ringkasan_sks AS
SELECT m.nim,
       m.nama,
       k.tahun_akademik,
       COUNT(*)     AS jumlah_matkul,
       SUM(mk.sks)  AS total_sks
FROM salam.mahasiswas m
JOIN salam.krs    k  ON k.mahasiswa_id = m.id
JOIN salam.matkul mk ON mk.id = k.matkul_id
GROUP BY m.nim, m.nama, k.tahun_akademik;

-- Akses eksplisit (selain default privileges)
GRANT SELECT ON salam.v_mahasiswa_cumlaude, salam.v_ringkasan_sks TO bi_dev;

RESET ROLE;

-- ---------------------------------------------------------------------
-- 4) Seed data (ganti dengan data milikmu sendiri)
-- ---------------------------------------------------------------------
INSERT INTO salam.mahasiswas (nim, nama, email, semester, ipk) VALUES
    ('1247050049', 'Tuan Gilang',    'gilang@mail.com',  5, 3.75),
    ('1247050101', 'Contoh Satu',    'satu@mail.com',    5, 3.20),
    ('1247050102', 'Contoh Dua',     'dua@mail.com',     5, 3.55)
ON CONFLICT (nim) DO NOTHING;

INSERT INTO salam.matkul (kode, nama, sks) VALUES
    ('MBD',      'Manajemen Basis Data',          3),
    ('RPL',      'Rekayasa Perangkat Lunak',      3),
    ('ALGO',     'Analisis Algoritma',            3),
    ('PROBSTAT', 'Probabilitas dan Statistika',   3),
    ('SISTER',   'Sistem Terdistribusi',          3)
ON CONFLICT (kode) DO NOTHING;

INSERT INTO salam.krs (mahasiswa_id, matkul_id, tahun_akademik)
SELECT m.id, k.id, '2026/2027'
FROM salam.mahasiswas m
CROSS JOIN salam.matkul k
WHERE m.nim = '1247050049'
  AND k.kode IN ('MBD', 'RPL', 'ALGO')
ON CONFLICT DO NOTHING;
