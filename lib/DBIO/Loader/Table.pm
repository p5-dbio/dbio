package DBIO::Loader::Table;
# ABSTRACT: Table metadata object

use strict;
use warnings;
use base 'DBIO::Loader::DBObject';
use mro 'c3';

=head1 NAME

DBIO::Loader::Table - Class for Tables in
L<DBIO::Loader>

=head1 DESCRIPTION

Inherits from L<DBIO::Loader::DBObject>. Stringifies to
C<< $table->name >>.

=head1 SEE ALSO

L<DBIO::Loader::DBObject>, L<DBIO::Loader>, L<DBIO::Loader::Base>

=head1 AUTHORS

See L<DBIO::Loader/AUTHORS>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
# vim:et sts=4 sw=4 tw=0:
