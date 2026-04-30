---
name: dbio-vanilla
description: "DBIO Vanilla style — classic DBIx::Class-like Result classes without sugar. Use when project uses 'use base DBIO::Core'"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

Classic DBIx::Class-compatible style. No sugar/DSL — explicit class method calls + hashrefs. Trigger: `use base 'DBIO::Core'` or `use parent 'DBIO::Core'` (no Cake/Candy).

## Example

```perl
package MyApp::Schema::Result::Artist;
use strict;
use warnings;
use base 'DBIO::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  id => {
    data_type=>'integer', is_auto_increment=>1, is_nullable=>0,
    extra=>{unsigned=>1},
  },
  name      => { data_type=>'varchar', size=>100, is_nullable=>0 },
  formed    => { data_type=>'date',    is_nullable=>0 },
  disbanded => { data_type=>'date',    is_nullable=>1 },
  bio       => { data_type=>'text',    is_nullable=>1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(artist_name => ['name']);
__PACKAGE__->has_many(
  albums => 'MyApp::Schema::Result::Album',
  { 'foreign.artist_id' => 'self.id' },
);
1;
```

## Column attrs

```perl
column_name => {
  data_type           => 'integer',     # required
  size                => 11,
  is_nullable         => 0,             # 0|1
  is_auto_increment   => 1,
  is_foreign_key      => 1,
  default_value       => 'x',
  extra               => { unsigned=>1 },
  retrieve_on_insert  => 1,
  sequence            => 'seq_name',    # Oracle/PG explicit
  accessor            => 'method_name',
  is_numeric          => 1,
}
```

## Relationships

```perl
__PACKAGE__->belongs_to(artist => 'MyApp::Schema::Result::Artist', { 'foreign.id'=>'self.artist_id' }, { join_type=>'left' });
__PACKAGE__->belongs_to(artist => 'MyApp::Schema::Result::Artist', 'artist_id');                      # short form
__PACKAGE__->has_many   (albums  => 'MyApp::Schema::Result::Album',   { 'foreign.artist_id'=>'self.id' });
__PACKAGE__->has_one    (profile => 'MyApp::Schema::Result::Profile', { 'foreign.user_id'=>'self.id' });
__PACKAGE__->might_have (bio     => 'MyApp::Schema::Result::Bio',     { 'foreign.artist_id'=>'self.id' });
__PACKAGE__->many_to_many(tags => 'album_tags', 'tag');
```

## Constraints

```perl
__PACKAGE__->set_primary_key('id');
__PACKAGE__->set_primary_key('artist_id','cd_id');           # composite
__PACKAGE__->add_unique_constraint(['email']);                # anonymous
__PACKAGE__->add_unique_constraint(email_uniq => ['email']);  # named
```

## Components

```perl
__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp EncodedColumn));
```

## Vanilla vs Cake vs Candy

| Aspect | Vanilla | Cake | Candy |
|---|---|---|---|
| Base | `use base 'DBIO::Core'` | auto | `-base` opt |
| Columns | `add_columns(...)` | `col x => type, mod` | `column x => {...}` |
| Nullable | `is_nullable=>1` | `null` | `is_nullable=>1` |
| Rels | `__PACKAGE__->has_many(...)` | `has_many ...` | `has_many ...` |
| Verbosity | high | low | medium |
| Autoclean | manual if wanted | auto | auto |

## Rules

1. Every method call uses `__PACKAGE__->`
2. Column info = hashref with explicit keys
3. Relationship cond = `{ 'foreign.col' => 'self.col' }` hashref
4. Components must be loaded explicitly via `load_components`
5. Declare `strict` + `warnings` manually
6. End file with `1;`
7. 1:1 compatible with DBIx::Class — ideal for migrated codebases
