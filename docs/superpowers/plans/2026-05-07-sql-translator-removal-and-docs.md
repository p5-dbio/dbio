# SQL::Translator Removal + Documentation Alignment

**Goal:** SQL::Translator komplett aus dbio core entfernen. POD-Doku in DBIO.pm und README.md auf den aktuellen Stand bringen. Skills in allen 6 Driver repos verlinken.

**Architecture:** SQL::Translator war der alte Deploy-Path für Driver ohne native Deploy. Alle Driver haben jetzt `dbio_deploy_class`. Der alte Path über `storage->deploy` wird zu einem echten No-Op (oder removed den ganzen Code).

**Tech Stack:** Perl, DBIO core

---

## Task 1: SQL::Translator aus dbio core entfernen

**Files:**
- Modify: `lib/DBIO/Storage/DBI.pm` — `deploy` methode: SQL::Translator path entfernen, nur noch native Deploy
- Modify: `lib/DBIO/Storage/DBI.pm` — `deploy_ddl` methode: komplett entfernen oder No-Op
- Modify: `lib/DBIO/Storage/DBI.pm` — `storage_ddl` methode: No-Op oder removed
- Modify: `lib/DBIO/Optional/Dependencies.pm` — SQL::Translator aus `deploy` gruppe entfernen
- Modify: `lib/DBIO/Schema.pm` — POD in `deploy` methode: "SQL::Translator" упоминание entfernen
- Modify: `lib/DBIO/ResultSource.pm` — POD referenzen auf SQL::Translator entfernen
- Modify: `lib/DBIO/Cake.pm` — POD referenzen auf SQL::Translator entfernen
- Modify: `lib/DBIO/Relationship/Base.pm` — POD referenzen entfernen

- [ ] **Step 1: Storage::DBI — `deploy` methode lesen und SQL::Translator path identifizieren**

Lies `/storage/raid/home/getty/dev/perl/dbio-dev/dbio/lib/DBIO/Storage/DBI.pm` ab Zeile ~3150. Die `deploy` methode macht:
- SQL::Translator->new mit parser 'SQL::Translator::Parser::DBIO'
- translate()
- Producer für verschiedene DBs

Nach dem SQL::Translator removal sollte `deploy` NUR noch den native Deploy path gehen (der ist über `$self->storage->can('dbio_deploy_class')`... aber das passiert schon in Schema.pm).

Die `storage_ddl` und `deploy_ddl` Methoden können entweder:
- Einen Fehler werfen ("SQL::Translator wurde entfernt, nutze native Deploy")
- Oder einfachremoved werden

- [ ] **Step 2: Schema.pm — `deploy` POD updaten**

Die POD spricht von "using SQL::Translator". Das muss weg. Korrekte POD:

```perl
=method deploy

    $schema->deploy;

Deploys the schema to the current storage. If the storage class provides
a native Deploy class (via L<DBIO::Storage::DBI/dbio_deploy_class>),
uses that. Otherwise throws an exception.

=cut
```

- [ ] **Step 3: Optional::Dependencies — SQL::Translator aus `deploy` gruppe entfernen**

Lies die `req_list_for('deploy')` gruppe. SQL::Translator dort entfernen.

- [ ] **Step 4: Alle POD-referenzen auf SQL::Translator in Schema, ResultSource, Cake, Relationship/Base**

Überall wo SQL::Translator erwähnt wird in der Doku — Verweis auf den alten Weg entfernen.

- [ ] **Step 5: Test ausführen**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio && prove -l t/00-load.t t/test/07_diffsql.t
```

- [ ] **Step 6: Commit**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio
git add -A && git commit -m "refactor: remove SQL::Translator from dbio core (native Deploy only)"
```

---

## Task 2: DBIO.pm POD + README.md updaten

**Files:**
- Modify: `lib/DBIO.pm` — POD review und updaten
- Modify: `README.md` — updaten

- [ ] **Step 1: DBIO.pm POD review**

Lies `lib/DBIO.pm`. Prüfe:
- Werden SQL::Translator, deploy, DDL, Diff noch korrekt beschrieben?
- Die "desired-state deployment" Sprache sollte verwendet werden
- DBIO::SQL::Util sollte erwähnt werden als geteilte Utilities
- Die aktiven Driver (PostgreSQL, MySQL, SQLite, DuckDB) sollten aufgelistet sein
- Die extrahierten Driver (DB2, Firebird, Informix, MSSQL, Oracle, Sybase) sollten erwähnt sein

- [ ] **Step 2: README.md review**

Lies `README.md`. Das gleiche review.

- [ ] **Step 3: Test ausführen und commit**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio && prove -l t/00-load.t
git add -A && git commit -m "docs: align DBIO.pm POD + README.md with current architecture"
```

---

## Task 3: README.md in allen 6 Driver repos aktualisieren

**Files:**
- Modify: `dbio-db2/README.md`
- Modify: `dbio-firebird/README.md`
- Modify: `dbio-informix/README.md`
- Modify: `dbio-mssql/README.md`
- Modify: `dbio-oracle/README.md`
- Modify: `dbio-sybase/README.md`

Für jedes Driver-Repo: README.md prüfen und auf den neuesten Stand bringen. Die Driver haben alle jetzt:
- Native Deploy (test-deploy-and-compare)
- DBIO::SQL::Util als geteilte Utility
- DBIO::Introspect::Base und DBIO::Diff::Base

Typisches README Template:
```markdown
# DBIO::<Driver>

<Driver> database driver for DBIO (fork of DBIx::Class).

## Supports

- desired-state deployment via test-deploy-and-compare (L<DBIO::Deploy>)
- native introspection (L<DBIO::Introspect>)
- native diff (L<DBIO::Diff>)
- native DDL generation (L<DBIO::DDL>)

## Usage

    package MyApp::DB;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('<Driver>');

    my $schema = MyApp::DB->connect('dbi:<Driver>:database=myapp');

## Requirements

- Perl 5.36+
- DBD::<Driver>
- DBIO core

## Testing

    prove -l t/

Requires a running <Driver> instance. Set C<DBIO_TEST_<DRIVER>_DSN>.

## See Also

L<DBIO::Introspect::Base>, L<DBIO::Diff::Base>
```

- [ ] **Step 1: Für jedes Driver-Repo: README.md lesen, prüfen, updaten**

- [ ] **Step 2: Commit pro Driver**

---

## Task 4: Skills in Informix und Sybase verlinken

Informix und Sybase haben keine `dbio-core` und `perl-release-dbio` skills. Das muss nachgeholt werden.

- [ ] **Step 1: Informix — dbio-core und perl-release-dbio verlinken**

```bash
manage-skills link dbio-core perl-release-dbio
# Im Informix Verzeichnis
```

- [ ] **Step 2: Sybase — dbio-core und perl-release-dbio verlinken**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-sybase && manage-skills link dbio-core perl-release-dbio
```

- [ ] **Step 3: Verify**

```bash
manage-skills check
```
