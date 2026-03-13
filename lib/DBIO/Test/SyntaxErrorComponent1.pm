#   belongs to t/run/90ensure_class_loaded.tl
package # hide from PAUSE
    DBIO::Test::SyntaxErrorComponent1;
# ABSTRACT: Test component with intentional syntax error
use warnings;
use strict;

my $str ''; # syntax error

1;
