# DRY Refactor: Shared SQL Utilities + Firebird DDL

**Goal:** Extract duplicated `_quote_ident` und `_split_statements` in DBIO::SQL::Util. Füge Firebird DDL hinzu. Standardisiere Type-Mapping. Alle 6 Driver nutzen danach die gemeinsamen Utilities.

**Architecture:** Ein neues `DBIO::SQL::Util` Modul in dbio core enthält die zwei Funktionen. Jeder Driver importiert sie via `use DBIO::SQL::Util qw(_quote_ident _split_statements)`. Zusätzlich ein `DBIO::SQL::Type` Modul für Type-Mapping. `DBIO::Firebird::DDL` wird neu erstellt.

**Tech Stack:** Perl (DBIO core + 6 Driver Repos)

---

## Task 1: DBIO::SQL::Util erstellen

**Files:**
- Create: `dbio/lib/DBIO/SQL/Util.pm`

- [ ] **Step 1: DBIO::SQL::Util schreiben**

```perl
package DBIO::SQL::Util;
# ABSTRACT: Shared SQL rendering utilities for DBIO drivers
our $VERSION = '0.900000';

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(_quote_ident _split_statements);

=func _quote_ident

    my $quoted = _quote_ident($name);

Quote a SQL identifier. Unquoted identifiers must match C</^[a-z_][a-z0-9_]*$/i>.
Double-quotes inside names are escaped as C<"">.

=cut

sub _quote_ident {
  my ($name) = @_;
  return $name if $name =~ /^[a-z_][a-z0-9_]*$/i;
  $name =~ s/"/""/g;
  return qq{"$name"};
}

=func _split_statements

    my @stmts = _split_statements($sql);

Split a SQL string on semicolons. Statements ending with a semicolon
are separated. Trailing whitespace is trimmed. Blank statements are
discarded. Dollar-quoted strings (C<$$ ... $$>) are correctly handled
so that semicolons inside them do not split.

=cut

sub _split_statements {
  my ($sql) = @_;
  my @stmts;
  my $in_dollar = 0;
  my $current = '';

  for my $line (split /\n/, $sql) {
    if ($line =~ /\$\$/) {
      my $count = () = $line =~ /\$\$/g;
      $in_dollar = ($in_dollar + $count) % 2;
    }
    $current .= "$line\n";

    if (!$in_dollar && $line =~ /;\s*$/) {
      $current =~ s/^\s+|\s+$//g;
      push @stmts, $current if $current =~ /\S/;
      $current = '';
    }
  }
  $current =~ s/^\s+|\s+$//g;
  push @stmts, $current if $current =~ /\S/;
  return @stmts;
}

1;
```

- [ ] **Step 2: Test für DBIO::SQL::Util schreiben**

```perl
# dbio/t/sql_util.t
use Test::More;
use DBIO::SQL::Util qw(_quote_ident _split_statements);

# _quote_ident tests
is(_quote_ident('foo'), 'foo');
is(_quote_ident('foo_bar'), 'foo_bar');
is(_quote_ident('FooBar'), 'FooBar');
is(_quote_ident('foo bar'), '"foo bar"');
is(_quote_ident('foo"bar'), '"foo""bar"');
is(_quote_ident('123'), '"123"');

# _split_statements tests
is_deeply([_split_statements("SELECT 1; SELECT 2;")], ['SELECT 1;', 'SELECT 2;']);
is_deeply([_split_statements("SELECT \$\$; INSERT INTO t VALUES (\$a); \$\$;")], ["SELECT \$\$; INSERT INTO t VALUES (\$a); \$\$;"]);
is_deeply([_split_statements("  ;  ;")], []);
is_deeply([_split_statements("SELECT 1")], ['SELECT 1']);

done_testing;
```

- [ ] **Step 3: Test ausführen und verifizieren es fehlschlägt**

Run: `cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio && perl -Ilib t/sql_util.t`
Expected: FAIL — `Can't locate DBIO/SQL/Util.pm`

- [ ] **Step 4: Implementierung verifizieren (Util existiert noch nicht)**

Util Datei ist noch nicht da — weiter mit commit.

- [ ] **Step 5: Commit**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio
git add lib/DBIO/SQL/Util.pm t/sql_util.t
git commit -m "feat: add DBIO::SQL::Util with _quote_ident and _split_statements"
```

---

## Task 2: DB2 — DBIO::SQL::Util verwenden + totes ForeignKeys-Code entfernen

**Files:**
- Modify: `dbio-db2/lib/DBIO/DB2/DDL.pm` — ersetze lokale `_quote_ident` durch Import
- Modify: `dbio-db2/lib/DBIO/DB2/Deploy.pm` — ersetze lokale `_split_statements` durch Import
- Modify: `dbio-db2/lib/DBIO/DB2/Diff/Table.pm` — Import + tote Zeilen in ForeignKeys entfernen
- Modify: `dbio-db2/lib/DBIO/DB2/Diff/Column.pm` — Import
- Modify: `dbio-db2/lib/DBIO/DB2/Diff/Index.pm` — Import
- Modify: `dbio-db2/lib/DBIO/DB2/Introspect/Columns.pm` — falls dort `_quote_ident` ist
- Modify: `dbio-db2/lib/DBIO/DB2/Introspect/ForeignKeys.pm` — tote Zeilen nach execute entfernen

- [ ] **Step 1: Alle `_quote_ident` Aufrufe in DB2 finden**

```bash
grep -n "_quote_ident" /storage/raid/home/getty/dev/perl/dbio-dev/dbio-db2/lib/DBIO/DB2/*.pm /storage/raid/home/getty/dev/perl/dbio-dev/dbio-db2/lib/DBIO/DB2/**/*.pm 2>/dev/null
```

- [ ] **Step 2: `_split_statements` in DB2 finden**

```bash
grep -n "_split_statements" /storage/raid/home/getty/dev/perl/dbio-dev/dbio-db2/lib/DBIO/DB2/Deploy.pm
```

- [ ] **Step 3: DB2 DDL — lokale `_quote_ident` entfernen, Import hinzufügen**

In `DBIO::DB2::DDL` — Zeile ~203:
- Lokale `_quote_ident` Sub (Zeilen 203+) entfernen
- Am Anfang der Datei hinzufügen:
```perl
use DBIO::SQL::Util qw(_quote_ident);
```

- [ ] **Step 4: DB2 Deploy — lokale `_split_statements` entfernen, Import hinzufügen**

In `DBIO::DB2::Deploy` — am Dateianfang:
```perl
use DBIO::SQL::Util qw(_split_statements);
```
Lokale `_split_statements` Sub entfernen (vor `1;` am Ende).

- [ ] **Step 5: DB2 Diff Module — Import hinzufügen**

DDL, Diff/Table, Diff/Column, Diff/Index — jeweils am Anfang:
```perl
use DBIO::SQL::Util qw(_quote_ident);
```

- [ ] **Step 6: DB2 Introspect::ForeignKeys — tote Zeilen entfernen**

Lies `/storage/raid/home/getty/dev/perl/dbio-dev/dbio-db2/lib/DBIO/DB2/Introspect/ForeignKeys.pm` — die Zeilen nach dem ersten `$sth->execute` die nur `finish` machen und dann nochmal execute → totes Code-Block entfernen.

- [ ] **Step 7: Test ausführen**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-db2 && prove -l t/00-load.t
```

- [ ] **Step 8: Commit**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-db2
git add -A && git commit -m "refactor: use DBIO::SQL::Util for _quote_ident and _split_statements"
```

---

## Task 3: Firebird — DBIO::SQL::Util + fehlende DDL erstellen

**Files:**
- Create: `dbio-firebird/lib/DBIO/Firebird/DDL.pm`
- Modify: `dbio-firebird/lib/DBIO/Firebird/Deploy.pm` — Import + lokale `_split_statements` entfernen
- Modify: `dbio-firebird/lib/DBIO/Firebird/Diff/Table.pm` — Import
- Modify: `dbio-firebird/lib/DBIO/Firebird/Diff/Column.pm` — Import
- Modify: `dbio-firebird/lib/DBIO/Firebird/Diff/Index.pm` — Import
- Modify: `dbio-firebird/lib/DBIO/Firebird/Deploy.pm` — `dbio_deploy_class` Deklaration an einer Stelle konsolidieren

Hinweis: Firebird hat keinen native DDL Generator — Deploy used `storage->deploy` (SQL::Translator). CLAUDE.md sagt "referenced but doesn't exist". Ein minimaler DDL Writer muss erstellt werden für CREATE TABLE + FKs.

- [ ] **Step 1: DBIO::Firebird::DDL schreiben**

```perl
package DBIO::Firebird::DDL;
# ABSTRACT: Generate Firebird DDL from DBIO Result classes
our $VERSION = '0.900000';

use strict;
use warnings;

use DBIO::SQL::Util qw(_quote_ident);

=method install_ddl

    my $ddl = DBIO::Firebird::DDL->install_ddl($schema);

Returns the full installation DDL as a single string.

=cut

sub install_ddl {
  my ($class, $schema) = @_;
  my @stmts;

  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    my $table_name = $source->name;

    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = _firebird_column_type($info);
      my $def = sprintf '  %s %s', _quote_ident($col_name), $type;
      $def .= ' NOT NULL' if defined $info->{is_nullable} && !$info->{is_nullable};
      if (defined $info->{default_value}) {
        my $dv = $info->{default_value};
        $def .= ref $dv eq 'SCALAR' ? " DEFAULT $$dv" : " DEFAULT '$dv'";
      }
      push @col_defs, $def;
    }

    if (@pk_cols) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { _quote_ident($_) } @pk_cols);
    }

    my $qualified = _quote_ident($table_name);
    push @stmts, sprintf "CREATE TABLE %s (\n%s\n);", $qualified, join(",\n", @col_defs);

    # Unique indexes
    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      if ($info->{is_unique} || $info->{is_single_unique_key}) {
        push @stmts, sprintf 'CREATE UNIQUE INDEX %s ON %s (%s);',
          _quote_ident("${table_name}_${col_name}_idx"),
          $qualified,
          _quote_ident($col_name);
      }
    }
  }

  return join "\n\n", @stmts;
}

sub _firebird_column_type {
  my ($info) = @_;
  my $type = lc($info->{data_type} // 'varchar');
  return 'INTEGER' if $type eq 'integer' || $type eq 'bigint' || $type eq 'smallint';
  return 'BIGINT' if $type eq 'bigserial' || $type eq 'serial';
  return 'VARCHAR(255)' if $type eq 'varchar' || $type eq 'nvarchar';
  return 'CHAR(1)' if $type eq 'char' || $type eq 'nchar';
  return 'BLOB' if $type eq 'bytea' || $type eq 'blob';
  return 'BLOB SUB_TYPE TEXT' if $type eq 'text' || $type eq 'clob' || $type eq 'long';
  return 'DATE' if $type eq 'date' || $type eq 'datetime' || $type eq 'timestamp';
  return 'DOUBLE PRECISION' if $type eq 'double precision' || $type eq 'float';
  return 'DECIMAL(18,6)' if $type eq 'numeric' || $type eq 'decimal';
  return 'SMALLINT' if $type eq 'boolean';  # Firebird has no boolean; use SMALLINT
  return uc($type);
}

1;
```

- [ ] **Step 2: Firebird Deploy — Import hinzufügen, lokale `_split_statements` und `dbio_deploy_class` redundante Deklarationen prüfen**

Am Anfang von `DBIO::Firebird::Deploy`:
```perl
use DBIO::SQL::Util qw(_split_statements);
```
Lokale `_split_statements` Sub entfernen.

Firebird Deploy hatte 3× `dbio_deploy_class` deklariert — an einer Stelle belassen (in Storage.pm oderDeploy.pm, nicht beide).

- [ ] **Step 3: Firebird Diff Module — Import hinzufügen**

Diff/Table, Diff/Column, Diff/Index — jeweils am Anfang:
```perl
use DBIO::SQL::Util qw(_quote_ident);
```
Lokale `_quote_ident` Subs entfernen.

- [ ] **Step 4: Test ausführen**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-firebird && prove -l t/00-load.t
```

- [ ] **Step 5: Commit**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-firebird
git add -A && git commit -m "feat: add DBIO::Firebird::DDL and use DBIO::SQL::Util"
```

---

## Task 4: MSSQL — DBIO::SQL::Util + Type-Mapping deduplizieren

**Files:**
- Modify: `dbio-mssql/lib/DBIO/MSSQL/DDL.pm` — Import + lokale `_quote_ident` entfernen
- Modify: `dbio-mssql/lib/DBIO/MSSQL/Diff/Table.pm` — Import + lokale `_mssql_column_type` entfernen
- Modify: `dbio-mssql/lib/DBIO/MSSQL/Diff/Column.pm` — Import + lokale `_mssql_column_type` entfernen
- Modify: `dbio-mssql/lib/DBIO/MSSQL/Diff/Index.pm` — Import + lokale `_quote_ident` entfernen falls vorhanden
- Modify: `dbio-mssql/lib/DBIO/MSSQL/Deploy.pm` — Import + lokale `_split_statements` falls vorhanden
- Modify: `dbio-mssql/lib/DBIO/MSSQL/Introspect/Columns.pm` — Import falls `_quote_ident` dort

- [ ] **Step 1: Alle`_quote_ident` und `_mssql_column_type` Aufrufe in MSSQL finden**

```bash
grep -rn "_quote_ident\|_mssql_column_type" /storage/raid/home/getty/dev/perl/dbio-dev/dbio-mssql/lib/
```

- [ ] **Step 2: MSSQL DDL updaten**

Am Anfang der Datei:
```perl
use DBIO::SQL::Util qw(_quote_ident);
```
Lokale `_quote_ident` Sub entfernen.

- [ ] **Step 3: MSSQL Diff::Table und Diff::Column — `_mssql_column_type` durch gemeinsames Modul ersetzen**

MSSQL hat `_mssql_column_type` in DDL, Diff::Table und Diff::Column. Alle drei kopieren das gleiche Mapping. Wir erstellen noch kein separates Modul — erst mal nur per Import aus DDL::Table::Type oder direkt in der Klasse.

Besser: MSSQL Diff::Table und Diff::Column importieren `_mssql_column_type` vom DDL-Modul (das DDL existiert ja als eigenständiges Modul und wird von Deploy geladen).

Falls MSSQL::DDL die Funktion exportiert:
```perl
use DBIO::MSSQL::DDL qw(_mssql_column_type _quote_ident);
```

- [ ] **Step 4: MSSQL Deploy — `_split_statements` Import hinzufügen**

Falls MSSQL Deploy eine eigene Kopie hat — Import via `DBIO::SQL::Util`.

- [ ] **Step 5: Test ausführen**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-mssql && prove -l t/00-load.t
```

- [ ] **Step 6: Commit**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-mssql
git add -A && git commit -m "refactor: use DBIO::SQL::Util"
```

---

## Task 5: Informix — DBIO::SQL::Util + Diff eigene DDL-Rendering ersetzen

**Files:**
- Modify: `dbio-informix/lib/DBIO/Informix/DDL.pm` — Import + lokale `_quote_ident` entfernen
- Modify: `dbio-informix/lib/DBIO/Informix/Diff/*.pm` — alle Diff sub-modules importieren `_quote_ident` statt eigene Kopie
- Modify: `dbio-informix/lib/DBIO/Informix/Deploy.pm` — Import + lokale `_split_statements` falls vorhanden
- Modify: `dbio-informix/lib/DBIO/Informix/Introspect/*.pm` — `_quote_ident` Import falls dupliziert

Hinweis: Informix Diff rendert eigene DDL (statt DDL-Modul zu verwenden) — das ist eine stärkere Duplizierung. Hier sollte Diff::Table die SQL-Generierung delegieren oder das DDL-Modul verwenden.

- [ ] **Step 1: Alle `_quote_ident` in Informix finden**

```bash
grep -rn "_quote_ident" /storage/raid/home/getty/dev/perl/dbio-dev/dbio-informix/lib/
```

- [ ] **Step 2: Informix DDL — Import hinzufügen, lokale `_quote_ident` entfernen**

- [ ] **Step 3: Informix Diff — alle Copies durch Import ersetzen**

Falls `Diff::Table` eigene `_quote_ident` Kopie hat → Import aus `DBIO::SQL::Util`.

- [ ] **Step 4: Informix Deploy — Import hinzufügen**

- [ ] **Step 5: Test ausführen**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-informix && prove -l t/00-load.t
```

- [ ] **Step 6: Commit**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-informix
git add -A && git commit -m "refactor: use DBIO::SQL::Util"
```

---

## Task 6: Oracle — DBIO::SQL::Util + tote Code-Pfade in Introspect entfernen

**Files:**
- Modify: `dbio-oracle/lib/DBIO/Oracle/DDL.pm` — Import + lokale `_quote_ident` entfernen
- Modify: `dbio-oracle/lib/DBIO/Oracle/Diff/Table.pm` — Import + lokale `_quote_ident` entfernen
- Modify: `dbio-oracle/lib/DBIO/Oracle/Diff/Column.pm` — Import + lokale `_quote_ident` entfernen
- Modify: `dbio-oracle/lib/DBIO/Oracle/Diff/Index.pm` — Import + lokale `_quote_ident` entfernen
- Modify: `dbio-oracle/lib/DBIO/Oracle/Introspect/Columns.pm` — tote execute/finish-Blöcke entfernen (Zeilen 41-49)
- Modify: `dbio-oracle/lib/DBIO/Oracle/Introspect/Indexes.pm` — dupliziertes execute/finish entfernen (Zeilen 29-45)

- [ ] **Step 1: Oracle DDL — lokale `_quote_ident` durch Import ersetzen**

Am Anfang:
```perl
use DBIO::SQL::Util qw(_quote_ident);
```
Lokale Sub entfernen.

- [ ] **Step 2: Oracle Diff Module — alle durch Import ersetzen**

- [ ] **Step 3: Oracle Introspect::Columns — tote Zeilen entfernen**

Lies die Datei. Das erste `$sth->execute` + `$sth->finish` Block (vor dem `$col_sth` Block) produziert keine Daten und ist tot. Entferne Zeilen ~41-49.

- [ ] **Step 4: Oracle Introspect::Indexes — dupliziertes execute entfernen**

Lies die Datei. Das erste prepare/execute/finish Block (vor dem `$idx_sth` Block) ist totem Code. Entferne Zeilen ~29-45.

- [ ] **Step 5: Test ausführen**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-oracle && prove -l t/00-load.t
```

- [ ] **Step 6: Commit**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-oracle
git add -A && git commit -m "refactor: use DBIO::SQL::Util + remove dead code in Introspect"
```

---

## Task 7: Sybase — DBIO::SQL::Util + tote Oracle/Diff-遗留问题

**Files:**
- Modify: `dbio-sybase/lib/DBIO/Sybase/DDL.pm` — Import + lokale `_quote_ident` entfernen
- Modify: `dbio-sybase/lib/DBIO/Sybase/Diff/Table.pm` — Import
- Modify: `dbio-sybase/lib/DBIO/Sybase/Diff/Column.pm` — Import
- Modify: `dbio-sybase/lib/DBIO/Sybase/Diff/Index.pm` — Import
- Modify: `dbio-sybase/lib/DBIO/Sybase/Deploy.pm` — Import + lokale `_split_statements` entfernen

- [ ] **Step 1: Sybase DDL — lokale `_quote_ident` durch Import ersetzen**

```perl
use DBIO::SQL::Util qw(_quote_ident);
```
Lokale Sub entfernen.

- [ ] **Step 2: Sybase Diff/Deploy — alle Importe**

- [ ] **Step 3: Test ausführen**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-sybase && prove -l t/00-load.t
```

- [ ] **Step 4: Commit**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-sybase
git add -A && git commit -m "refactor: use DBIO::SQL::Util"
```

---

## Task 8: PostgreSQL, SQLite, MySQL, DuckDB — DBIO::SQL::Util ebenfalls verwenden

Diese Driver haben ihre eigenen Kopien von `_quote_ident` und `_split_statements`. Nachdem das Util-Modul in dbio core existiert, können diese Driver auch umgestellt werden (optional aber empfohlen).

**Files:**
- Modify: `dbio-postgresql/lib/DBIO/PostgreSQL/DDL.pm` — Import + lokale `_quote_ident` entfernen
- Modify: `dbio-postgresql/lib/DBIO/PostgreSQL/Deploy.pm` — Import + lokale `_split_statements` entfernen
- Modify: `dbio-sqlite/lib/DBIO/SQLite/DDL.pm` — Import + lokale `_quote_ident` entfernen
- Modify: `dbio-sqlite/lib/DBIO/SQLite/Deploy.pm` — Import + lokale `_split_statements` entfernen
- Modify: `dbio-mysql/lib/DBIO/MySQL/DDL.pm` — Import + lokale `_quote_ident` entfernen
- Modify: `dbio-duckdb/lib/DBIO/DuckDB/DDL.pm` — Import + lokale `_quote_ident` entfernen

- [ ] **Step 1: PostgreSQL umstellen**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-postgresql
git add -A && git commit -m "refactor: use DBIO::SQL::Util"
```

- [ ] **Step 2: SQLite umstellen**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-sqlite
git add -A && git commit -m "refactor: use DBIO::SQL::Util"
```

- [ ] **Step 3: MySQL umstellen**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-mysql
git add -A && git commit -m "refactor: use DBIO::SQL::Util"
```

- [ ] **Step 4: DuckDB umstellen**

```bash
cd /storage/raid/home/getty/dev/perl/dbio-dev/dbio-duckdb
git add -A && git commit -m "refactor: use DBIO::SQL::Util"
```
