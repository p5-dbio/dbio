#   belongs to t/05components.t
package # hide from PAUSE
    DBIO::Test::ForeignComponent;
use warnings;
use strict;

use base qw/ DBIO /;

__PACKAGE__->load_components( qw/ +DBIO::Test::ForeignComponent::TestComp / );

1;
