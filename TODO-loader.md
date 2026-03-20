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
- [x] script/dbiodump with --style=cake|candy|vanilla|moose and -o key=value
- [x] Cake output style in Base.pm code generation (col name => type modifiers)
- [x] Candy output style in Base.pm code generation (has_column name => 'type' => { opts })
- [x] Code generation tests (t/loader/02-code-generation.t) for all three styles
- [x] Fixed DBIO::Candy::set_base idempotency bug (C3 merge failure on reload)

## Testing

- [ ] Port loader_*.t tests from Schema::Loader distribution
- [ ] Driver-specific loader tests go in driver distributions (dbio-sqlite, dbio-postgresql, dbio-mysql)

## Future

- [ ] Default output format: Cake (most concise) -- currently vanilla
- [ ] Support pgvector, hstore, jsonb and other modern types in introspection (dbio-postgresql)
- [ ] Support PostgreSQL enum introspection -> enum() in Cake output (dbio-postgresql)
