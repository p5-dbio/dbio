# DBIO

Extensible and flexible object <-> relational mapper. Fork of DBIx::Class.

## Key Differences from DBIx::Class

- Namespace: `DBIO::` replaces `DBIx::Class::`
- No RIBASUSHI dependencies
- SQL::Abstract replaces SQL::Abstract::Classic
- Integrates DBIx::Class::TimeStamp and DBIx::Class::Helpers into core
- SQL::Translator is optional, replaced by DB-specific modules

## Database Drivers (separate distributions)

- **DBIO-PostgreSQL** -- introspection via pg_catalog, deploy via test-and-compare
- **DBIO-MySQL** -- MySQL and MariaDB support
- **DBIO-SQLite** -- SQLite support
- **DBIO-Replicated** -- master/slave replication (Moose-based)

## Migration from DBIx::Class

```perl
# Before
use DBIx::Class::Schema;
# After
use DBIO::Schema;
```

Most code works with a namespace search-and-replace. See individual
module documentation for detailed migration notes.

## Testing

```bash
prove -l t/                    # Run tests (uses DBD::SQLite)
prove -lv t/specific_test.t    # Run a single test verbose
```

## Copyright

Copyright (C) 2026 DBIO Authors

Portions Copyright (C) 2005-2025 DBIx::Class Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
