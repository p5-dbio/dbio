---
name: dbio-cake
description: "DBIO::Cake DDL-like DSL for Result classes — the most concise style. Use when project uses 'use DBIO::Cake'"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO::Cake is the DDL-like DSL for defining Result classes. It is the most concise of the three DBIO styles.

## When to Use

Use Cake when the project's Result classes contain `use DBIO::Cake`. This is the recommended style for new DBIO projects.

## What `use DBIO::Cake` Does Automatically

1. Enables `strict` and `warnings`
2. Sets the class to inherit from `DBIO::Core`
3. Exports all DSL functions
4. Cleans up exported symbols via `namespace::clean` (autoclean)

## Complete Example

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Cake;

table 'artist';

col id           => integer, unsigned, auto_inc;
col name         => varchar(25), null;
col formed       => date;
col disbanded    => date, null;
col general_info => json, null;
col last_update  => datetime('UTC');

primary_key 'id';

unique artist_name => ['name'];

idx artist_by_name => ['name'];

has_many albums => 'MyApp::Schema::Result::Album', 'artist_id';

1;
```

```perl
package MyApp::Schema::Result::Album;
use DBIO::Cake -inflate_datetime;

table 'album';

col id        => serial;
col artist_id => integer, unsigned, fk;
col title     => varchar(100);
col released  => date, null;
col rating    => numeric(3, 1), null;
col price     => decimal(8, 2), default(9.99);

primary_key 'id';

belongs_to artist => 'MyApp::Schema::Result::Artist', 'artist_id';
has_many tracks => 'MyApp::Schema::Result::Track', 'album_id';

1;
```

## Import Options

```perl
use DBIO::Cake;                            # defaults
use DBIO::Cake -inflate_datetime;          # auto-inflate date/datetime
use DBIO::Cake -inflate_json;              # auto-inflate json/jsonb columns
use DBIO::Cake -inflate_jsonb;             # auto-inflate jsonb only (leaves json() free)
use DBIO::Cake -retrieve_defaults;         # retrieve_on_insert for defaults
use DBIO::Cake -no_autoclean;              # keep DSL symbols in namespace

# Driver shortcuts — load driver-recommended defaults in one flag:
use DBIO::Cake '-Pg';                      # = -inflate_jsonb, -inflate_datetime, -retrieve_defaults
use DBIO::Cake '-MySQL';                   # (if DBIO::MySQL::Storage has cake_defaults)
use DBIO::Cake '-SQLite';                  # (if DBIO::SQLite::Storage has cake_defaults)
```

Driver shortcuts use the `DBIO::Storage::DBI` driver registry to find the
storage class, then call `cake_defaults()` on it. Explicit flags after a
driver shortcut override the driver defaults.

## Column Types — Complete Reference

### Integers
- `integer`, `tinyint`, `smallint`, `bigint`

### Serial (auto-increment shortcuts)
- `serial`, `bigserial`, `smallserial`
- These imply `is_auto_increment => 1`

### Numeric
- `numeric($precision, $scale)`, `decimal($precision, $scale)`
- `money`

### Float
- `real` (alias: `float4`)
- `double` (alias: `float8`) — maps to `double precision`
- `float($bits)`

### String
- `char($size)`, `varchar($size)`

### Text
- `text`, `tinytext`, `mediumtext`, `longtext`

### Binary
- `blob`, `tinyblob`, `mediumblob`, `longblob`, `bytea`

### Boolean
- `boolean` (alias: `bool`)

### Date/Time
- `date`
- `datetime($tz)`, `timestamp($tz)`, `time($tz)`
- `timestamptz`, `timetz` — `with time zone` variants
- `interval`

### Enum
- `enum('val1', 'val2', 'val3')`

### UUID
- `uuid`

### JSON
- `json`, `jsonb`

### XML / Key-Value
- `xml`, `hstore`

### Array (PostgreSQL)
- `array('text')` — produces `text[]`
- `array({data_type => '...'})` — complex form

### Vector / AI (pgvector)
- `vector($dims)`, `halfvec($dims)`, `sparsevec($dims)`

### Bit Strings
- `bit($size)`, `varbit($size)`

### Network (PostgreSQL)
- `inet`, `cidr`, `macaddr`, `macaddr8`

### Full-Text Search (PostgreSQL)
- `tsvector`, `tsquery`

### Geometric (PostgreSQL)
- `point`, `line`, `lseg`, `box`, `path`, `polygon`, `circle`

### Range Types (PostgreSQL)
- `int4range`, `int8range`, `numrange`
- `tsrange`, `tstzrange`, `daterange`

## Column Modifiers

- `null` — `is_nullable => 1` (columns are NOT NULL by default)
- `auto_inc` — `is_auto_increment => 1`
- `fk` — `is_foreign_key => 1`
- `unsigned` — `extra => { unsigned => 1 }` (MySQL)
- `default($value)` — `default_value => $value`

Modifiers are comma-separated after the type:
```perl
col id   => integer, unsigned, auto_inc;
col name => varchar(50), null;
col rank => integer, default(0);
```

## Relationships

```perl
belongs_to artist  => 'MyApp::Schema::Result::Artist', 'artist_id';
has_one    profile => 'MyApp::Schema::Result::Profile', 'user_id';
has_many   tracks  => 'MyApp::Schema::Result::Track', 'album_id';
might_have bio     => 'MyApp::Schema::Result::Bio', 'artist_id';
many_to_many tags  => 'album_tags', 'tag';

# Left-join variants
rel_one  publisher => 'MyApp::Schema::Result::Publisher', 'publisher_id';
rel_many reviews   => 'MyApp::Schema::Result::Review', 'album_id';
```

## Cascade Helpers

```perl
belongs_to artist => 'MyApp::Schema::Result::Artist', 'artist_id',
  { ddl_cascade };     # ON DELETE CASCADE, ON UPDATE CASCADE

has_many tracks => 'MyApp::Schema::Result::Track', 'album_id',
  { dbic_cascade };    # cascade_delete => 1, cascade_copy => 1
```

## Constraints and Indexes

```perl
primary_key 'id';
primary_key 'artist_id', 'cd_id';    # composite

unique ['email'];                      # anonymous
unique email_uniq => ['email'];        # named

idx name_idx => ['name'];
idx composite => ['last', 'first'], type => 'unique';
```

## Views

```perl
package MyApp::Schema::Result::ActiveArtist;
use DBIO::Cake;

view 'active_artists', 'SELECT * FROM artist WHERE active = 1';
col id   => integer;
col name => varchar(100);
```

## Combining Cake with Moo or Moose

Cake works seamlessly with `DBIO::Moo` or `DBIO::Moose`. Load the OO bridge FIRST, then Cake:

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Moo;     # or: use DBIO::Moose;
use DBIO::Cake;

table 'artist';
col id   => integer auto_inc;
col name => varchar(100);
primary_key 'id';

# Moo/Moose attributes alongside Cake columns
has display_name => ( is => 'lazy' );
sub _build_display_name { 'Artist: ' . $_[0]->name }

has score => ( is => 'rw', lazy => 1, default => sub { 0 } );

# For Moose: __PACKAGE__->meta->make_immutable;
1;
```

**Order matters**: `use DBIO::Moo` (or `DBIO::Moose`) must come before `use DBIO::Cake` because the Cake keywords call `__PACKAGE__->add_columns(...)` etc. at compile time and need `DBIO::Core` already in the inheritance chain.

**All Moo/Moose attributes with defaults must be `lazy => 1`** — see `dbio-core` skill for details on why (`inflate_result` bypasses `new()`).

## Key Rules

1. **Columns are NOT NULL by default** — use `null` modifier explicitly
2. **Types return flat key-value lists** — they compose naturally: `integer, unsigned, auto_inc`
3. **No `1;` at end needed if you use `-V2`** — but harmless to include
4. **Symbols are auto-cleaned** — `col`, `integer`, etc. don't pollute the namespace
5. **Always use full class names** in relationships, not short moniker names
6. **For nullable columns use `null`** — the keyword, not `is_nullable` (that's a hash key for Vanilla-style)
