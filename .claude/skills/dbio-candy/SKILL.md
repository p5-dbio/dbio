---
name: dbio-candy
description: "DBIO::Candy import-based sugar for Result classes — method-renaming style. Use when project uses 'use DBIO::Candy'"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO::Candy is the import-based sugar style for Result classes. It provides renamed/aliased methods but does NOT change how columns are defined — you still use `add_columns` with hashrefs.

## When to Use

Use Candy when the project's Result classes contain `use DBIO::Candy`. Candy is a lighter sugar layer than Cake.

## What `use DBIO::Candy` Does

1. Sets base class (default: `DBIO::Core`)
2. Imports method aliases (shorter names for common operations)
3. Loads components specified in the import
4. Cleans up via `namespace::clean`

## Complete Example

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Candy -base => 'DBIO::Core';

table 'artist';

column id => {
  data_type         => 'integer',
  is_auto_increment => 1,
};

column name => {
  data_type   => 'varchar',
  size        => 100,
  is_nullable => 0,
};

column bio => {
  data_type   => 'text',
  is_nullable => 1,
};

primary_key 'id';

has_many 'albums', 'MyApp::Schema::Result::Album', 'artist_id';

1;
```

## Import Options

```perl
use DBIO::Candy;                                    # defaults
use DBIO::Candy -base => 'MyApp::Schema::Result';  # custom base class
use DBIO::Candy -components => [qw(
  InflateColumn::DateTime
  TimeStamp
)];
```

## Method Aliases Provided

Candy provides shorter names for common DBIO methods:

| Candy method   | Maps to                  |
|---------------|--------------------------|
| `column`      | `add_columns`            |
| `primary_key` | `set_primary_key`        |
| `unique`      | `add_unique_constraint`  |
| `table`       | `table`                  |
| `belongs_to`  | `belongs_to`             |
| `has_one`     | `has_one`                |
| `has_many`    | `has_many`               |
| `might_have`  | `might_have`             |
| `many_to_many`| `many_to_many`           |

## Key Differences from Cake

| Aspect | Candy | Cake |
|--------|-------|------|
| Column definition | `column name => { data_type => '...', ... }` | `col name => varchar(100), null` |
| Type specification | Hashref with `data_type` key | Bare function calls |
| Nullable | Explicit `is_nullable => 1` in hashref | `null` modifier |
| Auto-increment | Explicit `is_auto_increment => 1` | `auto_inc` modifier |
| Verbosity | Medium — shorter method names | Low — DDL-like syntax |
| Import sugar | Method aliasing | Full DSL with type functions |

## Key Rules

1. **Column definitions use hashrefs** — not the DDL-like syntax of Cake
2. **`column` is an alias for `add_columns`** — accepts the same arguments
3. **Base class is configurable** via `-base` import option
4. **Components are loaded** via `-components` import option
5. **Symbols are cleaned** via `namespace::clean` — imported methods don't leak
