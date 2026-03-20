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
- [x] Utils.pm merged into DBIO::Util -- Loader::Utils is now a thin re-export wrapper
- [x] RelBuilder::Compat/ removed (v0_040, v0_05, v0_06, v0_07) -- DBIO starts fresh
- [x] Removed unused Optional::Dependencies import from Base.pm

## Script

- [x] Create script/dbiodump (basic CLI with -o key=value options)
- [ ] Add `--style=candy|cake|classic|moose` option for choosing output format
- [ ] Default output format: Cake (most concise)

## Code Generation

- [ ] Add Cake output style to Base.pm code generation
- [ ] Add Candy output style to Base.pm code generation
- [ ] Keep classic (use base) and Moose styles as options

## Testing

- [ ] Port loader_*.t tests from Schema::Loader distribution
- [ ] Write core Loader tests using DBIO::Test::Storage mocks
- [ ] Driver-specific loader tests go in driver distributions (dbio-sqlite, dbio-postgresql, dbio-mysql)

## Future

- [ ] Support pgvector, hstore, jsonb and other modern types in introspection
- [ ] Support PostgreSQL enum introspection -> enum() in Cake output
