package DBIO::ResultSource::Table;
# ABSTRACT: Table object

use strict;
use warnings;

use DBIO::ResultSet;

use base qw/DBIO::Base/;
__PACKAGE__->load_components(qw/ResultSource/);

=head1 SYNOPSIS

=head1 DESCRIPTION

Table object that inherits from L<DBIO::ResultSource>.

=head1 METHODS

=method from

Returns the FROM entry for the table (i.e. the table name)

=cut

sub from { shift->name; }


1;
