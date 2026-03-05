package DBIO::Storage::DBI::Sybase::Microsoft_SQL_Server::NoBindVars;

use strict;
use warnings;

use base qw/
  DBIO::Storage::DBI::NoBindVars
  DBIO::Storage::DBI::Sybase::Microsoft_SQL_Server
/;
use mro 'c3';

sub _init {
  my $self = shift;
  $self->disable_sth_caching(1);

  $self->next::method(@_);
}

1;

=head1 NAME

DBIO::Storage::DBI::Sybase::Microsoft_SQL_Server::NoBindVars - Support for Microsoft
SQL Server via DBD::Sybase without placeholders

=head1 SYNOPSIS

This subclass supports MSSQL server connections via DBD::Sybase when ? style
placeholders are not available.

=head1 DESCRIPTION

If you are using this driver then your combination of L<DBD::Sybase> and
libraries (most likely FreeTDS) does not support ? style placeholders.

This storage driver uses L<DBIO::Storage::DBI::NoBindVars> as a base.
This means that bind variables will be interpolated (properly quoted of course)
into the SQL query itself, without using bind placeholders.

More importantly this means that caching of prepared statements is explicitly
disabled, as the interpolation renders it useless.

In all other respects, it is a subclass of
L<DBIO::Storage::DBI::Sybase::Microsoft_SQL_Server>.

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.
