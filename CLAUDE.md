# CLAUDE.md -- DBIO

## Project Vision

DBIO is a fork of DBIx::Class — the Perl ORM. The fork removes all RIBASUSHI dependencies, replaces SQL::Abstract::Classic with SQL::Abstract, and integrates common extensions (TimeStamp, Helpers) into core.

**Status**: Active development. Core rewrite complete, releasing to CPAN.

## Key Differences from DBIx::Class

- Namespace: `DBIO::` replaces `DBIx::Class::`
- No RIBASUSHI dependencies (no namespace::clean from RIBASUSHI)
- SQL::Abstract (not SQL::Abstract::Classic)
- Integrated: DBIx::Class::TimeStamp -> DBIO::Timestamp, DBIx::Class::Helpers -> core
- SQL::Translator is OPTIONAL (only for legacy deploy) — replaced by DB-specific modules

## Architecture

```
DBIO::Schema -> DBIO::ResultSource -> DBIO::ResultSet -> DBIO::Row
DBIO::Storage -> DBIO::Storage::DBI (base for all drivers)
DBIO::SQLMaker (SQL generation)
```

## Database Drivers (separate distributions)

- DBIO-PostgreSQL — most advanced, introspection + deploy via pg_catalog
- DBIO-MySQL — MySQL + MariaDB
- DBIO-SQLite — SQLite
- DBIO-Replicated — master/slave replication (Moose-based)
- DBIO-DB2, DBIO-Firebird, DBIO-Informix, DBIO-MSSQL, DBIO-Oracle, DBIO-Sybase

## Build System

Uses Dist::Zilla with `[@DBIO] core = 1` plus extra plugins (MetaNoIndex, MetaResources). PodWeaver with `=attr` and `=method` collectors via `@DBIO` config.

## Testing

```bash
prove -l t/                           # Run tests (uses DBD::SQLite)
prove -l -I../dbio/lib t/            # From driver directories
DBIOTEST_PG_DSN=... prove -l t/      # PostgreSQL integration tests
```

## Copyright

- Original: DBIx::Class & DBIO Contributors (see AUTHORS file)
- Copyright 2005 (original DBIx::Class start)
- Current maintainer: Torsten Raudssus (GETTY)
