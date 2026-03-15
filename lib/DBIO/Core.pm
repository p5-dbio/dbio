package DBIO::Core;
# ABSTRACT: Standard base class for DBIO result classes

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

L<DBIO::Core> is the normal base class for vanilla DBIO result classes. It
collects the standard row, relationship, primary-key, and table-definition
behavior that most applications want in every result class.

If you are not using L<DBIO::Cake> or L<DBIO::Candy>, this is usually the class
you inherit from directly.

The bundled components currently are:

=over 4

=item L<DBIO::InflateColumn>

=item L<DBIO::Relationship> (See also L<DBIO::Relationship::Base>)

=item L<DBIO::PK>

=item L<DBIO::Row>

=item L<DBIO::ResultSourceProxy::Table> (See also L<DBIO::ResultSource>)

=back

For a broader tour of what a result class can do, see
L<DBIO::Manual::ResultClass>.

=cut
