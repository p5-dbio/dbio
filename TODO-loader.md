# DBIO::Loader TODO

Ported from DBIx::Class::Schema::Loader. Namespace conversion done,
needs integration testing and cleanup.

## Done

- [x] Namespace conversion: DBIx::Class::Schema::Loader → DBIO::Loader
- [x] Driver dispatch uses `DBIO::DriverName::Loader` naming (not `DBIO::Loader::DBI::DriverName`)
- [x] ODBC proxy moved to `DBIO::Loader::ODBC` (was `DBIO::Loader::DBI::ODBC`)
- [x] All driver ODBC subclasses updated to inherit from `DBIO::Loader::ODBC`
- [x] `dbicdump` references renamed to `dbiodump` in POD
- [x] RT references replaced with GitHub Issues
- [x] SEE ALSO sections updated across all driver Loader files
- [x] DBI/Writing.pm updated with new naming convention

## Core (lib/DBIO/Loader/)

- [ ] Remove Moose/MooseX dependencies from Base.pm — convert to plain accessors or Moo
- [ ] Remove RelBuilder::Compat/ legacy layers (v0_040 through v0_07) — we start fresh
- [ ] Remove Optional::Dependencies.pm usage — DBIO has its own dep system
- [ ] Update Base.pm code generation to emit `use DBIO::Candy` or `use DBIO::Cake` style classes (default to Cake)
- [ ] Add `--style=candy|cake|classic|moose` option to dbiodump for choosing output format
- [ ] Integrate with DBIO::Test::Storage for Loader test infrastructure
- [ ] Write core Loader tests using DBIO::Test::Storage mocks
- [ ] Add DBIO::Loader to MetaNoIndex exclusions in dist.ini if needed
- [ ] Review and clean up Utils.pm — remove unused utilities

## Script

- [ ] Create script/dbiodump (port from dbicdump)
- [ ] Update to use DBIO::Loader instead of DBIx::Class::Schema::Loader
- [ ] Default output format: Cake (most concise), with --candy, --moose, --classic flags

## Testing

- [ ] Port loader_*.t tests from Schema::Loader distribution
- [ ] Driver-specific loader tests go in driver distributions
- [ ] Core tests use DBIO::Test::Storage mocks only (no real DB in core)

## Future

- [ ] Generate DBIO::Cake style by default (most concise)
- [ ] Support pgvector, hstore, jsonb and other modern types in introspection
- [ ] Support PostgreSQL enum introspection → enum() in Cake output
