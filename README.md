# DBIO

DBI Objects — Relational mapping. Joins itself. Fully native. Everything included.

A modern fork of [DBIx::Class](https://metacpan.org/pod/DBIx::Class).

## Key Differences from DBIx::Class

- Namespace: `DBIO::` replaces `DBIx::Class::`
- SQL::Abstract replaces SQL::Abstract::Classic
- Integrates DBIx::Class::TimeStamp and DBIx::Class::Helpers into core
- Integrates [DBIx::Class::Candy](https://metacpan.org/pod/DBIx::Class::Candy) as `DBIO::Candy` (import-based sugar)
- Integrates [DBIx::Class::ResultDDL](https://metacpan.org/pod/DBIx::Class::ResultDDL) as `DBIO::Cake` (DDL-like DSL)
- Replicated storage built into core (`DBIO::Replicated`)
- Change tracking built into core (`DBIO::ChangeLog`)
- Async storage interface (`DBIO::Storage::Async`, `DBIO::Future`)
- SQL::Translator is optional, replaced by DB-specific modules

## Core Features

- **Replicated Storage** — master/slave replication via `DBIO::Replicated`
- **Change Tracking** — automatic insert/update/delete logging via `DBIO::ChangeLog`
- **Async Interface** — `all_async`, `first_async`, `count_async`, `create_async`
  return Futures; async drivers (e.g. [DBIO-PostgreSQL-Async](https://github.com/p5-dbio/dbio-postgresql-async))
  bypass DBI entirely

## Database Drivers (separate distributions)

- [**DBIO-PostgreSQL**](https://github.com/p5-dbio/dbio-postgresql) — introspection via pg_catalog, deploy via test-and-compare
- [**DBIO-MySQL**](https://github.com/p5-dbio/dbio-mysql) — MySQL and MariaDB support
- [**DBIO-SQLite**](https://github.com/p5-dbio/dbio-sqlite) — SQLite support
- [**DBIO-PostgreSQL-Async**](https://github.com/p5-dbio/dbio-postgresql-async) — async PostgreSQL via EV::Pg (no DBI)

## Defining Result Classes

Three ways to define the same result class:

### Vanilla (verbose, full control)

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

### DBIO::Candy (import-based sugar)

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

### DBIO::Cake (DDL-like DSL)

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Cake;
table 'artists';
col id   => integer, auto_inc;
col name => varchar(100);
primary_key 'id';
has_many cds => 'MyApp::Schema::Result::CD', 'artist_id';
1;
```

## Migration from DBIx::Class

```perl
# Before
use DBIx::Class::Schema;
# After
use DBIO::Schema;

# Before
use DBIx::Class::Candy;
# After
use DBIO::Candy;

# Before
use DBIx::Class::ResultDDL qw/-V2/;
# After
use DBIO::Cake;
```

Most code works with a namespace search-and-replace. See individual
module documentation for detailed migration notes.

## Testing

```bash
prove -l t/             # Run tests (uses DBIO::Test::Storage, no real DB)
prove -lv t/test/*.t    # Run core tests verbose
```

## Copyright

Copyright (C) 2026 DBIO Authors

Portions Copyright (C) 2005-2025 DBIx::Class Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
