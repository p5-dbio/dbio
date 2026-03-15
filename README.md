# DBIO

DBI Objects — Relational mapping. Joins itself. Fully native. Everything included.

A modern fork of [DBIx::Class](https://metacpan.org/pod/DBIx::Class).

## Key Differences from DBIx::Class

- Namespace: `DBIO::` replaces `DBIx::Class::`
- [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract) replaces SQL::Abstract::Classic
- Integrates [DBIx::Class::TimeStamp](https://metacpan.org/pod/DBIx::Class::TimeStamp) and [DBIx::Class::Helpers](https://metacpan.org/pod/DBIx::Class::Helpers) into core
- Integrates [DBIx::Class::Candy](https://metacpan.org/pod/DBIx::Class::Candy) as [DBIO::Candy](https://metacpan.org/pod/DBIO::Candy) (import-based sugar)
- Integrates [DBIx::Class::ResultDDL](https://metacpan.org/pod/DBIx::Class::ResultDDL) as [DBIO::Cake](https://metacpan.org/pod/DBIO::Cake) (DDL-like DSL)
- Replicated storage built into core ([DBIO::Replicated](https://metacpan.org/pod/DBIO::Replicated))
- Change tracking built into core ([DBIO::ChangeLog](https://metacpan.org/pod/DBIO::ChangeLog))
- Async storage interface ([DBIO::Storage::Async](https://metacpan.org/pod/DBIO::Storage::Async), [DBIO::Future](https://metacpan.org/pod/DBIO::Future))
- [SQL::Translator](https://metacpan.org/pod/SQL::Translator) is optional, replaced by DB-specific modules

## Core Features

- **Replicated Storage** — master/slave replication via [DBIO::Replicated](https://metacpan.org/pod/DBIO::Replicated)
- **Change Tracking** — automatic insert/update/delete logging via [DBIO::ChangeLog](https://metacpan.org/pod/DBIO::ChangeLog)
- **Async Interface** — `all_async`, `first_async`, `count_async`, `create_async`
  return [Futures](https://metacpan.org/pod/DBIO::Future); async drivers
  (e.g. [DBIO-PostgreSQL-Async](https://metacpan.org/pod/DBIO::PostgreSQL::Async))
  bypass DBI entirely

## Database Drivers (separate distributions)

- [**DBIO::PostgreSQL**](https://metacpan.org/pod/DBIO::PostgreSQL) — introspection via pg_catalog, deploy via test-and-compare
- [**DBIO::MySQL**](https://metacpan.org/pod/DBIO::MySQL) — MySQL and MariaDB support
- [**DBIO::SQLite**](https://metacpan.org/pod/DBIO::SQLite) — SQLite support
- [**DBIO::PostgreSQL::Async**](https://metacpan.org/pod/DBIO::PostgreSQL::Async) — async PostgreSQL via [EV::Pg](https://metacpan.org/pod/EV::Pg) (no DBI)

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

### [DBIO::Candy](https://metacpan.org/pod/DBIO::Candy) (import-based sugar)

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

### [DBIO::Cake](https://metacpan.org/pod/DBIO::Cake) (DDL-like DSL)

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Cake;

table 'artists';
col id     => integer, auto_inc;
col name   => varchar(100);
col bio    => text, null;
col active => boolean, default(1);
col tags   => array(text), null;
primary_key 'id';
unique artist_name => ['name'];
has_many cds => 'MyApp::Schema::Result::CD', 'artist_id';
1;
```

Cake with PostgreSQL-specific features:

```perl
package MyApp::Schema::Result::User;
use DBIO::Cake -inflate_json;

table 'users';
col id        => uuid, default(\'gen_random_uuid()');
col name      => varchar(100);
col role      => enum(qw( admin moderator user guest ));
col metadata  => jsonb, default('{}');
col embedding => vector(1536);
col tsv       => tsvector, null;
col tags      => array(text), null;
col created   => timestamp, default(\'now()');
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
