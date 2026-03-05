package DBIO::PK::Auto;

#use base qw/DBIO::PK/;
use base qw/DBIO/;
use strict;
use warnings;

1;

__END__

=head1 NAME

DBIO::PK::Auto - Automatic primary key class

=head1 SYNOPSIS

use base 'DBIO::Core';
__PACKAGE__->set_primary_key('id');

=head1 DESCRIPTION

This class overrides the insert method to get automatically incremented primary
keys.

PK::Auto is now part of Core.

See L<DBIO::Manual::Component> for details of component interactions.

=head1 LOGIC

C<PK::Auto> does this by letting the database assign the primary key field and
fetching the assigned value afterwards.

=head1 METHODS

=head2 insert

The code that was handled here is now in Row for efficiency.

=head2 sequence

The code that was handled here is now in ResultSource, and is being proxied to
Row as well.

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.
