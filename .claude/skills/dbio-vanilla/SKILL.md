---
name: dbio-vanilla
description: "DBIO Vanilla style — classic DBIx::Class-like Result classes without sugar. Use when project uses 'use base DBIO::Core'"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

Vanilla is the classic DBIx::Class-compatible style for DBIO Result classes. No sugar, no DSL — just class method calls with explicit hashrefs. This is what existing DBIx::Class code looks like after namespace conversion.

## When to Use

Use Vanilla when the project's Result classes use `use base 'DBIO::Core'` or `use parent 'DBIO::Core'` (without Cake or Candy imports).

## Complete Example

```perl
package MyApp::Schema::Result::Artist;

use strict;
use warnings;

use base 'DBIO::Core';

__PACKAGE__->load_components(qw(
  InflateColumn::DateTime
));

__PACKAGE__->table('artist');

__PACKAGE__->add_columns(
  id => {
    data_type         => 'integer',
    is_auto_increment => 1,
    is_nullable       => 0,
    extra             => { unsigned => 1 },
  },
  name => {
    data_type   => 'varchar',
    size        => 100,
    is_nullable => 0,
  },
  formed => {
    data_type   => 'date',
    is_nullable => 0,
  },
  disbanded => {
    data_type   => 'date',
    is_nullable => 1,
  },
  bio => {
    data_type   => 'text',
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint(
  artist_name => ['name'],
);

__PACKAGE__->has_many(
  albums => 'MyApp::Schema::Result::Album',
  { 'foreign.artist_id' => 'self.id' },
);

1;
```

## Column Definition

All column attributes are explicit key-value pairs in a hashref:

```perl
__PACKAGE__->add_columns(
  column_name => {
    data_type           => 'integer',     # required
    size                => 11,            # for varchar, numeric, etc.
    is_nullable         => 0,             # 0 or 1
    is_auto_increment   => 1,             # auto-increment
    is_foreign_key      => 1,             # FK marker
    default_value       => 'some_val',    # default
    extra               => { unsigned => 1 },  # DB-specific extras
    retrieve_on_insert  => 1,             # re-fetch after insert
    sequence            => 'seq_name',    # explicit sequence (Oracle, PG)
    accessor            => 'method_name', # custom accessor name
    is_numeric          => 1,             # hint for quoting
  },
);
```

## Relationships

Vanilla uses explicit condition hashrefs:

```perl
# belongs_to (many-to-one)
__PACKAGE__->belongs_to(
  artist => 'MyApp::Schema::Result::Artist',
  { 'foreign.id' => 'self.artist_id' },
  { join_type => 'left' },  # optional attrs
);

# Short form (single FK column)
__PACKAGE__->belongs_to(
  artist => 'MyApp::Schema::Result::Artist',
  'artist_id',
);

# has_many (one-to-many)
__PACKAGE__->has_many(
  albums => 'MyApp::Schema::Result::Album',
  { 'foreign.artist_id' => 'self.id' },
);

# has_one (one-to-one)
__PACKAGE__->has_one(
  profile => 'MyApp::Schema::Result::Profile',
  { 'foreign.user_id' => 'self.id' },
);

# might_have (one-to-zero-or-one)
__PACKAGE__->might_have(
  bio => 'MyApp::Schema::Result::Bio',
  { 'foreign.artist_id' => 'self.id' },
);

# many_to_many (through link table)
__PACKAGE__->many_to_many(
  tags => 'album_tags', 'tag',
);
```

## Constraints

```perl
# Primary key
__PACKAGE__->set_primary_key('id');
__PACKAGE__->set_primary_key('artist_id', 'cd_id');  # composite

# Unique constraints
__PACKAGE__->add_unique_constraint(['email']);                  # anonymous
__PACKAGE__->add_unique_constraint(email_uniq => ['email']);    # named
```

## Components

```perl
__PACKAGE__->load_components(qw(
  InflateColumn::DateTime
  TimeStamp
  EncodedColumn
));
```

## Key Differences from Cake/Candy

| Aspect | Vanilla | Cake | Candy |
|--------|---------|------|-------|
| Base class | `use base 'DBIO::Core'` | automatic | `-base` option |
| Columns | `__PACKAGE__->add_columns(...)` | `col name => type, mod` | `column name => {...}` |
| Types | `data_type => 'integer'` in hashref | `integer` function | `data_type => 'integer'` |
| Nullable | `is_nullable => 1` in hashref | `null` modifier | `is_nullable => 1` |
| Relationships | `__PACKAGE__->has_many(...)` | `has_many ...` | `has_many ...` |
| Verbosity | High — fully explicit | Low — DDL-like | Medium |
| Autoclean | manual `namespace::clean` if wanted | automatic | automatic |

## Key Rules

1. **Every method call uses `__PACKAGE__->`** prefix
2. **Column info is always a hashref** with explicit keys
3. **Relationship conditions** use `{ 'foreign.col' => 'self.col' }` hashref notation
4. **Components must be loaded explicitly** via `load_components`
5. **`strict` and `warnings` must be declared manually**
6. **File must end with `1;`**
7. This style is 1:1 compatible with DBIx::Class — ideal for migrated codebases
