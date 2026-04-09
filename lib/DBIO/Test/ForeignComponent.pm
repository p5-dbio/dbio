#   belongs to t/05components.t
package DBIO::Test::ForeignComponent;
# ABSTRACT: Test class for foreign component loading
use warnings;
use strict;

use base qw/ DBIO /;

__PACKAGE__->load_components( qw/ +DBIO::Test::ForeignComponent::TestComp / );

1;
