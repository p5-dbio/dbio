package DBIO::Relationship::Helpers;
# ABSTRACT: Load all standard relationship declaration components

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
