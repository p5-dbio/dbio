#   belongs to t/05components.t
package # hide from PAUSE
    DBIO::Test::ForeignComponent::TestComp;
# ABSTRACT: Test component loaded as a foreign component
use warnings;
use strict;

sub foreign_test_method { 1 }

1;
