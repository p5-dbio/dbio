package DBIO::Storage::DBI::Oracle;

use strict;
use warnings;

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

sub _rebless {
  my ($self) = @_;

  # Default driver
  my $class = $self->_server_info->{normalized_dbms_version} < 9
    ? 'DBIO::Storage::DBI::Oracle::WhereJoins'
    : 'DBIO::Storage::DBI::Oracle::Generic';

  $self->ensure_class_loaded ($class);
  bless $self, $class;
}

1;

=head1 NAME

DBIO::Storage::DBI::Oracle - Base class for Oracle driver

=head1 DESCRIPTION

This class simply provides a mechanism for discovering and loading a sub-class
for a specific version Oracle backend. It should be transparent to the user.

For Oracle major versions < 9 it loads the ::Oracle::WhereJoins subclass,
which unrolls the ANSI join style DBIC normally generates into entries in
the WHERE clause for compatibility purposes. To force usage of this version
no matter the database version, add

  __PACKAGE__->storage_type('::DBI::Oracle::WhereJoins');

to your Schema class.

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.
