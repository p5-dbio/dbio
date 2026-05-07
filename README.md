# DBIO

DBI Objects — Relational mapping. Joins itself. Fully native. Everything included.

A modern fork of [DBIx::Class](https://metacpan.org/pod/DBIx::Class).

## Key Differences from DBIx::Class

**Namespace**
- `DBIO::` replaces `DBIx::Class::`

**SQL Generation**
- [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract) replaces `SQL::Abstract::Classic`
- Default `LIMIT/OFFSET` syntax; override `apply_limit` per driver for custom dialects

**Integrated Components**

The following were extracted from DBIx::Class distributions and merged into core:

- [DBIx::Class::TimeStamp](https://metacpan.org/pod/DBIx::Class::TimeStamp) → `DBIO::Schema::DateTime` (automatic `created_at`/`updated_at` columns)
- [DBIx::Class::Helpers](https://metacpan.org/pod/DBIx::Class::Helpers) → merged into core (resultset utilities, cross-request inflate/deflate, multicontext)
- [DBIx::Class::Candy](https://metacpan.org/pod/DBIx::Class::Candy) → [DBIO::Candy](https://metacpan.org/pod/DBIO::Candy) (import-based sugar with `table`, `column`, `primary_key`, `has_many`, etc.)
- [DBIx::Class::ResultDDL](https://metacpan.org/pod/DBIx::Class::ResultDDL) → [DBIO::Cake](https://metacpan.org/pod/DBIO::Cake) (DDL-like DSL with `col id => integer auto_inc`, `varchar(100), null`, etc.)

**New in DBIO**

- **Replicated Storage** — master/slave replication built into core with [DBIO::Replicated](https://metacpan.org/pod/DBIO::Replicated), access brokers for rotating credentials, read/write splitting
- **Change Tracking** — automatic insert/update/delete logging via [DBIO::Schema::ChangeLog](https://metacpan.org/pod/DBIO::Schema::ChangeLog) (new component, not in DBIx::Class)
- **Async Storage Interface** — `all_async`, `first_async`, `count_async`, `create_async` return [Futures](https://metacpan.org/pod/DBIO::Future); async drivers bypass DBI entirely
- **SQL::Translator Removed** — all drivers use native desired-state deployment via test-deploy-and-compare (introspect live DB, deploy to throwaway, diff the two models) using DB-specific modules

## Core Features

**Replicated Storage**
- Master/slave replication via [DBIO::Replicated](https://metacpan.org/pod/DBIO::Replicated)
- [DBIO::AccessBroker::Static](https://metacpan.org/pod/DBIO::AccessBroker::Static) — rotating credentials per-schema
- [DBIO::AccessBroker::Env](https://metacpan.org/pod/DBIO::AccessBroker::Env) — credentials from environment variables
- Read/write split based on operation type

**Change Tracking**
- Automatic logging of insert/update/delete operations via [DBIO::Schema::ChangeLog](https://metacpan.org/pod/DBIO::Schema::ChangeLog)
- Per-table tracking configuration
- [DBIO::ChangeLog::Entry](https://metacpan.org/pod/DBIO::ChangeLog::Entry) — structured change records
- [DBIO::ChangeLog::Set](https://metacpan.org/pod/DBIO::ChangeLog::Set) — batch changes

**Async Interface**
- `all_async`, `first_async`, `count_async`, `create_async` return [Futures](https://metacpan.org/pod/DBIO::Future)
- [DBIO::PostgreSQL::Async](https://metacpan.org/pod/DBIO::PostgreSQL::Async) — async PostgreSQL via [EV::Pg](https://metacpan.org/pod/EV::Pg) (no DBI, libpq direct)

**Deployment**
- All drivers implement native desired-state deployment via test-deploy-and-compare
- No SQL::Translator dependency
- [DBIO::Deploy](https://metacpan.org/pod/DBIO::Deploy) — base deploy interface
- [DBIO::SQL::Util](https://metacpan.org/pod/DBIO::SQL::Util) — shared utilities (`_quote_ident`, `_split_statements`)

## Defining Result Classes

Three ways to define the same result class, from most verbose to most concise:

### Vanilla (no sugar, full control)

```perl
package MyApp::Schema::Result::Artist;
use base 'DBIO::Core';
__PACKAGE__->table('artists');
__PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD', 'artist_id');
1;
```

No import magic. Each column defined explicitly via `add_columns`. Use this when you need maximum control or are migrating from plain DBIx::Class.

### [DBIO::Candy](https://metacpan.org/pod/DBIO::Candy) (keyword-based sugar)

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Candy;
table 'artists';
column id   => { data_type => 'integer', is_auto_increment => 1 };
column name => { data_type => 'varchar', size => 100 };
primary_key 'id';
has_many cds => 'MyApp::Schema::Result::CD', 'artist_id';
1;
```

Imported keywords: `table`, `column`, `primary_key`, `belongs_to`, `has_many`, `has_one`, `might_have`, `many_to_many`, `add_columns`, `inflator`, `deflator`. Drops directly into `use DBIO::Core` namespace.

### [DBIO::Cake](https://metacpan.org/pod/DBIO::Cake) (DDL-like DSL)

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Cake;

table 'artists';
col id     => integer auto_inc;
col name   => varchar(100), null;
col bio    => text null;
col active => boolean default(1);
col tags   => array(text), null;
primary_key 'id';
unique artist_name => ['name'];
has_many cds => 'MyApp::Schema::Result::CD', 'artist_id';
1;
```

DDL-inspired syntax with bareword chains. Note: bareword-to-bareword chains need no comma (`integer auto_inc`, `text null`); after a number or closing paren, Perl needs a comma (`varchar(100), null`).

Cake with PostgreSQL-specific features:

```perl
package MyApp::Schema::Result::User;
use DBIO::Cake -inflate_json;

table 'users';
col id         => uuid;                                        # auto retrieve_on_insert
col name       => varchar(100);
col role       => enum(qw( admin moderator user guest )), null;
col metadata   => jsonb \"{}";
col embedding  => vector(1536);
col tsv        => tsvector null;
col tags       => array(text), null;
col created_at => timestamp;                                   # auto set_on_create
col updated_at => timestamp on_update;                         # auto set_on_create + on_update
col deleted_at => timestamp null;                               # nullable, no auto-set
primary_key 'id';
1;
```

## Migration from DBIx::Class

```perl
# Before                              # After
use DBIx::Class::Schema;              use DBIO::Schema;
use DBIx::Class::Candy;               use DBIO::Candy;
use DBIx::Class::ResultDDL qw/-V2/;   use DBIO::Cake;
```

Most code works with a namespace search-and-replace. Key changes:

**Result class base**: `DBIx::Class::Core` → `DBIO::Core` (or `DBIO::Schema` for schema classes)

**SQL::Abstract**: `SQL::Abstract::Classic` is no longer used; `SQL::Abstract` is the default

**Deployment**: SQL::Translator is removed; drivers use native test-deploy-and-compare. See L<DBIO::Manual::Migration> for detailed migration notes.

See L<DBIO::Manual::Migration> for the full migration guide.

## Database Drivers

Drivers are separate CPAN distributions. DBIO core autodetects DSN patterns and loads the appropriate storage.

### Active Drivers

**PostgreSQL** — L<DBIO::PostgreSQL>
- Introspection via pg_catalog
- Deploy via test-and-compare
- RLS (Row Level Security), indexes (expression, covering, partial), full-text search (TSVECTOR)
- Async via L<DBIO::PostgreSQL::Async> (EV::Pg, no DBI)
- Enum, JSON, JSONB, UUID, ARRAY, HSTORE, VECTOR, INTERVAL types

**MySQL / MariaDB** — L<DBIO::MySQL>
- Supports both L<DBD::mysql> and L<DBD::MariaDB>
- Deploy via test-and-compare
- FULLTEXT indexes, spatial indexes (GIS)

**SQLite** — L<DBIO::SQLite>
- In-memory database testing (`dbi:SQLite::memory:`)
- Deploy via test-and-compare
- JSON support (SQLite 3.38+), FTS5 full-text search

**DuckDB** — L<DBIO::DuckDB>
- Embeddable analytical database
- Deploy via test-and-compare
- Arrow integration, parquet export, native JSON/JSONB

### Extracted Drivers

These drivers were extracted from the DBIx::Class monolith and now have native deploy:

- **DB2** — L<DBIO::DB2> — IBM DB2 (SYSCAT introspection, RLS)
- **Firebird** — L<DBIO::Firebird> — Firebird/InterBase (CHARACTER SET, DATE AT TIME ZONE)
- **Informix** — L<DBIO::Informix> — Informix (SERIAL, BYTE, TEXT types)
- **MSSQL** — L<DBIO::MSSQL> — Microsoft SQL Server (OUTPUT clause, window functions)
- **Oracle** — L<DBIO::Oracle> — Oracle (CONNECT BY, hierarchical queries, 30-char identifiers)
- **Sybase** — L<DBIO::Sybase> — Sybase ASE (temporary databases for deploy, sp_server_info)

All drivers share [DBIO::SQL::Util](https://metacpan.org/pod/DBIO::SQL::Util) for `_quote_ident` and `_split_statements`.

## Testing

```bash
prove -l t/             # Run tests (uses DBIO::Test::Storage, no real DB)
prove -lv t/test/*.t    # Run core tests verbose
```

Core tests use [DBIO::Test::Storage](https://metacpan.org/pod/DBIO::Test::Storage) — a fake/virtual storage that captures SQL and supports mocks. Real database testing belongs in driver distributions.

## Copyright

Copyright (C) 2026 DBIO Authors

Portions Copyright (C) 2005-2025 DBIx::Class Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.