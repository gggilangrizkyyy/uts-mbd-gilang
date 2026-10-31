# UTS Manajemen Basis Data

Proyek 1 / UTS Manajemen Basis Data

- **Nama:** Gilang Rizky Ramadhan
- **NIM:** 1247050049

## Isi Proyek

Menjalankan PostgreSQL dan pgAdmin 4 sebagai container Docker, lalu membuat schema `salam`, tabel `mahasiswas` beserta constraint-nya, dan tiga user dengan hak akses berbeda.

```
.
├── docker-compose.yml
├── .env.example          # template variabel
├── .gitignore            # .env tidak ikut di-commit, hanya .env.example yang di-commit
└── init/                 # dijalankan otomatis saat volume masih kosong
    ├── 01-schema.sql     # schema salam + tabel mahasiswas
    ├── 02-roles.sql      # user backend_dev, bi_dev, data_engineer
    └── 03-fitur-tambahan.sql
```

## Service

| Service | Container | Image | Port host | Port container |
|---|---|---|---|---|
| PostgreSQL | `postgres_gilang` | `postgres:15` | `22049` | `5432` |
| pgAdmin 4 | `pgadmin_gilang` | `dpage/pgadmin4` | `44049` | `80` |

Username dan password tidak ditulis di `docker-compose.yml`, melainkan dibaca dari file `.env`.

## Cara Menjalankan

1. Pastikan Docker Desktop sudah berjalan (Engine running).
2. Salin template environment, lalu isi nilainya:
   ```bash
   copy .env.example .env      # Windows
   # cp .env.example .env      # Linux / macOS
   ```
3. Jalankan container:
   ```bash
   docker compose up -d
   docker compose ps
   ```
4. Reset total (hapus data dan jalankan ulang script `init/`):
   ```bash
   docker compose down -v
   docker compose up -d
   ```

## Akses

| Dari | Host | Port | Keterangan |
|---|---|---|---|
| pgAdmin 4 (internal Docker) | `postgres` | `5432` | Buka `http://localhost:44049`, lalu Register > Server |
| DBeaver (eksternal Docker) | `localhost` | `22049` | Database `uts_mbd` |

pgAdmin berada di jaringan Docker yang sama dengan PostgreSQL sehingga memakai nama service dan port asli. DBeaver berjalan di luar Docker sehingga memakai port yang di-publish ke host.

## Schema dan Constraint

Tabel `salam.mahasiswas` memiliki:

- **PRIMARY KEY** pada `id`
- **UNIQUE** pada `nim` dan `email`
- **CHECK** `semester` antara 1 dan 14, serta `ipk` antara 0 dan 4

## User dan Hak Akses

| User | Hak akses |
|---|---|
| `backend_dev` | CRUD (SELECT, INSERT, UPDATE, DELETE) semua tabel |
| `bi_dev` | Hanya SELECT pada semua tabel dan view |
| `data_engineer` | CREATE, ALTER, DROP semua objek di schema `salam`, plus CRUD semua tabel |

Detail GRANT ada di `init/02-roles.sql`.

## Fitur Tambahan

Ada di `init/03-fitur-tambahan.sql`:

- Tabel `matkul` dan `krs` dengan foreign key ke `mahasiswas`
- Tabel `audit_log` dan trigger `trg_audit_mahasiswas` yang mencatat INSERT, UPDATE, dan DELETE pada `mahasiswas`
- View `v_mahasiswa_cumlaude` (IPK >= 3.5) dan `v_ringkasan_sks` (total SKS per mahasiswa), dapat dibaca oleh `bi_dev`
- Seed data

## Catatan

- File di `init/` hanya dieksekusi saat volume `pgdata` masih kosong. Jika script diubah, jalankan `docker compose down -v` lalu `docker compose up -d`.
- `.env` sengaja tidak di-commit. Gunakan `.env.example` sebagai acuan.
