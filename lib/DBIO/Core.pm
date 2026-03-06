package DBIO::Core;
# ABSTRACT: Core set of DBIO modules

use strict;
use warnings;

use base qw/DBIO/;

__PACKAGE__->load_components(qw/
  Relationship
  InflateColumn
  PK
  Row
  ResultSourceProxy::Table
/);

1;

__END__

=head1 SYNOPSIS

  # In your result (table) classes
  use base 'DBIO::Core';

=head1 DESCRIPTION

This class just inherits from the various modules that make up the
L<DBIO> core features.  You almost certainly want these.

The core modules currently are:

=over 4

=item L<DBIO::InflateColumn>

=item L<DBIO::Relationship> (See also L<DBIO::Relationship::Base>)

=item L<DBIO::PK>

=item L<DBIO::Row>

=item L<DBIO::ResultSourceProxy::Table> (See also L<DBIO::ResultSource>)

=back

A better overview of the methods found in a Result class can be found
in L<DBIO::Manual::ResultClass>.

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.
