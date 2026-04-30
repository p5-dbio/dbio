---
name: dbio-candy
description: "DBIO::Candy import-based sugar for Result classes — method-renaming style. Use when project uses 'use DBIO::Candy'"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

Import-based sugar layer. Renames methods, but columns still use `add_columns` hashref form. Trigger: `use DBIO::Candy` in a Result class. Lighter than Cake.

## What `use DBIO::Candy` does

1. Sets base class (default `DBIO::Core`)
2. Imports method aliases
3. Loads requested components
4. `namespace::clean`

## Example

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Candy -base => 'DBIO::Core';

table 'artist';
column id   => { data_type=>'integer', is_auto_increment=>1 };
column name => { data_type=>'varchar', size=>100, is_nullable=>0 };
column bio  => { data_type=>'text', is_nullable=>1 };
primary_key 'id';
has_many 'albums', 'MyApp::Schema::Result::Album', 'artist_id';
1;
```

## Import flags

```perl
use DBIO::Candy;
use DBIO::Candy -base => 'MyApp::Schema::Result';
use DBIO::Candy -components => [qw(InflateColumn::DateTime TimeStamp)];
```

## Method aliases

| Candy | Maps to |
|---|---|
| `column` | `add_columns` |
| `primary_key` | `set_primary_key` |
| `unique` | `add_unique_constraint` |
| `table`, `belongs_to`, `has_one`, `has_many`, `might_have`, `many_to_many` | identity |

## Candy vs Cake

| Aspect | Candy | Cake |
|---|---|---|
| Column def | hashref `{data_type=>..,..}` | `varchar(100), null` |
| Nullable | `is_nullable=>1` | `null` |
| Auto-inc | `is_auto_increment=>1` | `auto_inc` |
| Style | method aliases | full DSL |

## Rules

1. Columns = hashref form (not Cake's DDL syntax)
2. `column` = alias for `add_columns`
3. Base class via `-base`
4. Components via `-components`
5. `namespace::clean` strips imports
