package DBIO::ResultSource::Table;
# ABSTRACT: Table object

use strict;
use warnings;

use DBIO::ResultSet;

use base qw/DBIO/;
__PACKAGE__->load_components(qw/ResultSource/);

=head1 SYNOPSIS

=head1 DESCRIPTION

Table object that inherits from L<DBIO::ResultSource>.

=head1 METHODS

=method from

Returns the FROM entry for the table (i.e. the table name)

=cut

sub from { shift->name; }

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIO resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut

1;
