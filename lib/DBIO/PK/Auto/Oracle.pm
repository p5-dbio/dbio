package # hide package from pause
  DBIO::PK::Auto::Oracle;

use strict;
use warnings;

use base qw/DBIO/;

__PACKAGE__->load_components(qw/PK::Auto/);

1;

__END__

=head1 NAME

DBIO::PK::Auto::Oracle - (DEPRECATED) Automatic primary key class for Oracle

=head1 SYNOPSIS

Just load PK::Auto instead; auto-inc is now handled by Storage.

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.
