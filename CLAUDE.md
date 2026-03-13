# CLAUDE.md -- DBIO Core

## Core-Specific Build

Uses `[@DBIO] core = 1` which enables: VersionFromMainModule (version from `$VERSION` in lib/DBIO.pm), MakeMaker::Awesome, ExecDir, extra GatherDir excludes, no GithubMeta.

Has additional plugins beyond `[@DBIO]`: MetaNoIndex, MetaResources.

## dist.ini specifics

```ini
copyright_holder = DBIO Contributors
copyright_year = 2005
```

## Testing

Core tests MUST use `DBIO::Test::Storage` (fake storage), NEVER `dbi:SQLite` or any real database. Use `DBIO::Test->init_schema` without DSN arguments. The mock system (`$storage->mock(qr/.../, \@rows)`) provides fake query results. Real DB testing belongs in driver distributions (dbio-sqlite, dbio-postgresql, etc.).
