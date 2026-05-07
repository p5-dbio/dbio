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
- [SQL::Translator](https://metacpan.org/pod/SQL::Translator) has been removed;
  all drivers use native desired-state deployment (introspect live DB, deploy
  to throwaway, diff the two models) via DB-specific modules

## Core Features

- **Replicated Storage** — master/slave replication via [DBIO::Replicated](https://metacpan.org/pod/DBIO::Replicated)
- **Access Brokers** — `Schema->connect($broker)` with rotating credentials and storage-native connect info via [DBIO::AccessBroker](https://metacpan.org/pod/DBIO::AccessBroker)
- **Change Tracking** — automatic insert/update/delete logging via [DBIO::ChangeLog](https://metacpan.org/pod/DBIO::ChangeLog)
- **Async Interface** — `all_async`, `first_async`, `count_async`, `create_async`
  return [Futures](https://metacpan.org/pod/DBIO::Future); async drivers
  (e.g. [DBIO-PostgreSQL-Async](https://metacpan.org/pod/DBIO::PostgreSQL::Async))
  bypass DBI entirely

## Brokered Connections

```perl
use DBIO::AccessBroker::Static;

my $broker = DBIO::AccessBroker::Static->new(
    dsn      => 'dbi:Pg:dbname=myapp;host=db',
    username => 'app',
    password => 'secret',
);

my $schema = MyApp::Schema->connect($broker);
```

## Database Drivers (separate distributions)

Active drivers (native desired-state deployment via test-and-compare):

- [**DBIO::PostgreSQL**](https://metacpan.org/pod/DBIO::PostgreSQL) — introspection via pg_catalog, deploy via test-and-compare, RLS, indexes
- [**DBIO::MySQL**](https://metacpan.org/pod/DBIO::MySQL) — MySQL and MariaDB support
  (requires [DBD::mysql](https://metacpan.org/pod/DBD::mysql) **or** [DBD::MariaDB](https://metacpan.org/pod/DBD::MariaDB) — install the one that matches your server)
- [**DBIO::SQLite**](https://metacpan.org/pod/DBIO::SQLite) — SQLite support
- [**DBIO::DuckDB**](https://metacpan.org/pod/DBIO::DuckDB) — DuckDB support
- [**DBIO::PostgreSQL::Async**](https://metacpan.org/pod/DBIO::PostgreSQL::Async) — async PostgreSQL via [EV::Pg](https://metacpan.org/pod/EV::Pg) (no DBI)

Extracted drivers (same native deployment pattern):

- [**DBIO::DB2**](https://metacpan.org/pod/DBIO::DB2) · [**DBIO::Firebird**](https://metacpan.org/pod/DBIO::Firebird) · [**DBIO::Informix**](https://metacpan.org/pod/DBIO::Informix) · [**DBIO::MSSQL**](https://metacpan.org/pod/DBIO::MSSQL) · [**DBIO::Oracle**](https://metacpan.org/pod/DBIO::Oracle) · [**DBIO::Sybase**](https://metacpan.org/pod/DBIO::Sybase)

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
col deleted_at => timestamp null;                              # nullable, no auto-set
primary_key 'id';
1;
```

Note: bareword-to-bareword chains need no comma (`integer auto_inc`,
`text null`, `boolean default(1)`). After a number or closing paren,
Perl needs a comma (`varchar(100), null` or `varchar 100, null`).

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
