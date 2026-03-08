package DBIO::Admin::Descriptive;
# ABSTRACT: Getopt::Long::Descriptive subclass for DBIO admin tooling

use warnings;
use strict;

use base 'Getopt::Long::Descriptive';

require DBIO::Admin::Usage;

=head1 METHODS

=method usage_class

Return the custom usage formatter class.

=cut

sub usage_class { 'DBIO::Admin::Usage'; }

1;
