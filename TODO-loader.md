# DBIO::Loader TODO

Ported from DBIx::Class::Schema::Loader. Namespace conversion done,
needs integration testing and cleanup.

## Done

- [x] Namespace conversion: DBIx::Class::Schema::Loader -> DBIO::Loader
- [x] Driver dispatch uses `DBIO::DriverName::Loader` naming (not `DBIO::Loader::DBI::DriverName`)
- [x] ODBC proxy moved to `DBIO::Loader::ODBC` (was `DBIO::Loader::DBI::ODBC`)
- [x] All driver ODBC subclasses updated to inherit from `DBIO::Loader::ODBC`
- [x] `dbicdump` references renamed to `dbiodump` in POD
- [x] RT references replaced with GitHub Issues
- [x] SEE ALSO sections updated across all driver Loader files
- [x] DBI/Writing.pm updated with new naming convention
- [x] POD footers updated to DBIO boilerplate (FURTHER QUESTIONS / COPYRIGHT AND LICENSE)
- [x] Legacy DBIx::Class options rejected: use_moose, result_roles, result_roles_map (t/loader/01-legacy-options.t)

## Core (lib/DBIO/Loader/)

- [ ] Convert Base.pm from Class::Accessor::Grouped to Moo (NOT Moose -- it already uses C::A::G)
- [ ] Remove RelBuilder::Compat/ legacy layers (v0_040 through v0_07) -- we start fresh
- [ ] Remove Optional::Dependencies.pm usage from Base.pm -- DBIO has its own dep system
- [ ] Update Base.pm code generation to emit `use DBIO::Candy` or `use DBIO::Cake` style classes (default to Cake)
- [ ] Clean up Utils.pm -- remove unused functions: dumper, write_file, no_warnings, warnings_exist, warnings_exist_silent
- [ ] Add DBIO::Loader to MetaNoIndex exclusions in dist.ini (currently NOT excluded, will be indexed)

## Script

- [ ] Create script/dbiodump (port from dbicdump -- does NOT exist yet)
- [ ] Update to use DBIO::Loader instead of DBIx::Class::Schema::Loader
- [ ] Add `--style=candy|cake|classic` option for choosing output format
- [ ] Default output format: Cake (most concise)

## Testing

- [ ] Port loader_*.t tests from Schema::Loader distribution
- [ ] Write core Loader tests using DBIO::Test::Storage mocks
- [ ] Driver-specific loader tests go in driver distributions (dbio-sqlite, dbio-postgresql, dbio-mysql)
- [ ] Core tests use DBIO::Test::Storage mocks only (no real DB in core)

## Future

- [ ] Generate DBIO::Cake style by default (most concise)
- [ ] Support pgvector, hstore, jsonb and other modern types in introspection
- [ ] Support PostgreSQL enum introspection -> enum() in Cake output
