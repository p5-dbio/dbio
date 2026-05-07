# DBIO::ChangeLog Komplett-Implementierung Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ChangeLog-Feature vollständig und korrekt implementieren — Row-Tracking, Schema-Component, Deployment, Tests, Dokumentation.

**Architecture:**
- `DBIO::ChangeLog` — Row Component (trackt insert/update/delete auf Row-Ebene)
- `DBIO::ChangeLog::Schema` — Schema Component (txn_do wrapping, Source-Registrierung)
- `DBIO::ChangeLog::Table` — Gemeinsames Role für `source_definition` (löst Entry/Set duplication)
- `DBIO::ChangeLog::Entry` — ResultSource-Definition für `<source>_changelog` (nutzt Table-Role)
- `DBIO::ChangeLog::Set` — ResultSource-Definition für `changelog_set` (nutzt Table-Role)
- `deploy_changelog` — Echte DDL-Generierung statt no-op

**Tech Stack:** DBIO::Core, DBIO::Schema, DBIO::Test::Storage (für tests)

---

## Task 1: Table-Role extrahieren (Entry/Set DRY)

**Files:**
- Create: `lib/DBIO/ChangeLog/Table.pm`
- Modify: `lib/DBIO/ChangeLog/Entry.pm`
- Modify: `lib/DBIO/ChangeLog/Set.pm`

- [ ] **Step 1: Create Table role with shared source_definition**

```perl
package DBIO::ChangeLog::Table;
use Role::Tiny::With;
use strict;
use warnings;

requires 'source_definition';

sub _build_source_definition {
  my ($class, %args) = @_;
  my $def = $class->source_definition(%args);
  die "source_definition must return a hashref" unless ref $def eq 'HASH';
  return $def;
}

1;
```

- [ ] **Step 2: Rewrite Entry.pm to use shared columns**

Entry bekommt `source_definition` das die geteilten Spalten nutzt.
Set bekommt `source_definition` ohne Argumente (table ist fix).

- [ ] **Step 3: Commit**

---

## Task 2: Delete-Ordering Bug fixen

**Files:**
- Modify: `lib/DBIO/ChangeLog.pm:252-265`

- [ ] **Step 1: Write failing test**

```perl
# t/changelog/delete-ordering.t
# Test dass delete changelog NACH dem delete geschrieben wird
# Vorher: changelog write passiert VOR next::method (falsch)
# Nachher: changelog write passiert NACH next::method (korrekt)
```

- [ ] **Step 2: Fix delete method — move _changelog_record after next::method**

```perl
sub delete {
  my ($self, @args) = @_;

  my %cols;
  if (ref $self && $self->_changelog_is_tracked && !$self->_changelog_is_disabled) {
    %cols = $self->_changelog_filtered_columns($self->get_columns);
  }

  my $result = $self->next::method(@args);  # delete first

  if (%cols) {
    $self->_changelog_record('delete', \%cols);  # then log
  }

  return $result;
}
```

- [ ] **Step 3: Commit**

---

## Task 3: deploy_changelog implementieren

**Files:**
- Modify: `lib/DBIO/ChangeLog/Schema.pm`

- [ ] **Step 1: Write failing test — deploy_changelog erstellt tables**

```perl
# t/changelog/deploy.t
# Test dass deploy_changelog die changelog_set und <source>_changelog tables erstellt
# Nutzt DBIO::Test::Storage
```

- [ ] **Step 2: Implement deploy_changelog**

```perl
sub deploy_changelog {
  my ($self) = @_;

  my @tables;
  push @tables, $self->source('ChangeLog_Set');

  for my $source_name ($self->sources) {
    next if $source_name =~ /_ChangeLog$/ || $source_name eq 'ChangeLog_Set';
    if (my $cl = $self->source($source_name . '_ChangeLog')) {
      push @tables, $cl;
    }
  }

  for my $table (@tables) {
    $self->storage->deploy_table($table);
  }

  return $self;
}
```

- [ ] **Step 3: Commit**

---

## Task 4: _build_changelog_source fixen (keine eval-strings)

**Files:**
- Modify: `lib/DBIO/ChangeLog/Schema.pm:230-265`

- [ ] **Step 1: Write failing test**

```perl
# t/changelog/source-generation.t
# Test dass changelog sources korrekt registered werden
# ohne anonyme eval-classes
```

- [ ] **Step 2: Replace eval-string class creation mit DBIO::Core subclass**

```perl
# Statt:
#   my $result_class = "DBIO::ChangeLog::_Auto_::${source_name}";
#   eval "package $result_class; ...";

# Nutze:
my $result_class = "DBIO::ChangeLog::Entry::$source_name";
```

- [ ] **Step 3: Commit**

---

## Task 5: Error handling in changelog_write_entry

**Files:**
- Modify: `lib/DBIO/ChangeLog.pm:84-92`

- [ ] **Step 1: Write test für exception handling**

```perl
# t/changelog/write-error.t
# Test dass bei changelog write failure die exception propagiert
# (transaction muss rollback können)
```

- [ ] **Step 2: Dokumentiere error behavior in POD**

- [ ] **Step 3: Commit**

---

## Task 6: Klassen-Schema testen

**Files:**
- Create: `t/changelog/00-load.t`
- Create: `t/changelog/01-basic.t`
- Create: `t/changelog/02-insert.t`
- Create: `t/changelog/03-update.t`
- Create: `t/changelog/04-delete.t`
- Create: `t/changelog/05-txn_do.t`
- Create: `t/changelog/06-custom-events.t`

- [ ] **Step 1: Write all tests using DBIO::Test::Storage**

```perl
use DBIO::Test;
my ($storage, $schema) = DBIO::Test->init_schema;
# Nutze DBIO::Test::Storage (fake/virtual storage)
# KEINE echte DB-Verbindung
```

- [ ] **Step 2: Alle tests müssen passing sein**

- [ ] **Step 3: Commit**

---

## Task 7: POD Dokumentation

**Files:**
- Modify: `lib/DBIO/ChangeLog.pm` — komplette Doku überarbeiten
- Modify: `lib/DBIO/ChangeLog/Schema.pm` — Doku überarbeiten
- Create: `lib/DBIO/ChangeLog.pod` (optional als overview)

- [ ] **Step 1: Write comprehensive POD for DBIO::ChangeLog**

```pod
=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('ChangeLog');
  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');

  # Usage:
  my $artist = $schema->resultset('Artist')->create({ name => 'Bob' });
  my $entries = $artist->changelog;  # alle changelog einträge für diese row
  $artist->log_event('exported', { format => 'mp3' });  # custom event

=head1 DEPLOYMENT

  $schema->deploy_changelog;  # erstellt changelog_set und alle <source>_changelog tables
```

- [ ] **Step 2: Commit**

---

## Task 8: Final review and commit

- [ ] **Step 1: Run full test suite**

```bash
prove -l t/changelog/
```

- [ ] **Step 2: Review alle änderungen**

- [ ] **Step 3: Final commit**