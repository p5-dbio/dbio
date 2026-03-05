package # hide from PAUSE
    DBIO::Relationship::Helpers;

use strict;
use warnings;

use base qw/DBIO/;

__PACKAGE__->load_components(qw/
    Relationship::HasMany
    Relationship::HasOne
    Relationship::BelongsTo
    Relationship::ManyToMany
/);

1;
