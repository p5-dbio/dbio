package DBIO::Storage::DBI::MariaDB;
# ABSTRACT: Storage::DBI class implementing MariaDB specifics

use strict;
use warnings;

use base qw/DBIO::Storage::DBI::mysql/;

sub _dbh_last_insert_id {
  my ($self, $dbh, $source, $col) = @_;
  $dbh->{mariadb_insertid};
}

sub _run_connection_actions {
  my $self = shift;

  # default mariadb_auto_reconnect to off unless explicitly set
  if (
    $self->_dbh->{mariadb_auto_reconnect}
      and
    ! exists $self->_dbic_connect_attributes->{mariadb_auto_reconnect}
  ) {
    $self->_dbh->{mariadb_auto_reconnect} = 0;
  }

  # skip the mysql _run_connection_actions, go straight to DBI's
  $self->DBIO::Storage::DBI::_run_connection_actions(@_);
}

sub is_replicating {
  my $status = shift->_get_dbh->selectrow_hashref('SHOW REPLICA STATUS')
    || shift->_get_dbh->selectrow_hashref('SHOW SLAVE STATUS');
  return ($status->{Slave_IO_Running} eq 'Yes') && ($status->{Slave_SQL_Running} eq 'Yes');
}

sub lag_behind_master {
  my $status = shift->_get_dbh->selectrow_hashref('SHOW REPLICA STATUS')
    || shift->_get_dbh->selectrow_hashref('SHOW SLAVE STATUS');
  return $status->{Seconds_Behind_Master};
}

1;

=head1 SYNOPSIS

Storage::DBI autodetects the underlying MariaDB database when using
L<DBD::MariaDB>, and re-blesses the C<$storage> object into this class.

  my $schema = MyApp::Schema->connect(
    'dbi:MariaDB:database=mydb', $user, $pass,
    { on_connect_call => 'set_strict_mode' }
  );

=head1 DESCRIPTION

This class inherits from L<DBIO::Storage::DBI::mysql> and overrides the
DBD handle attribute names to match L<DBD::MariaDB>'s naming convention
(C<mariadb_*> instead of C<mysql_*>).

MariaDB and MySQL share the same SQL dialect, quote characters, limit syntax,
and savepoint semantics, so most behaviour is inherited unchanged. The
differences handled here are:

=over 4

=item * C<mariadb_insertid> for last-insert-id retrieval

=item * C<mariadb_auto_reconnect> for reconnection control

=item * C<SHOW REPLICA STATUS> (modern syntax) with fallback to C<SHOW SLAVE STATUS>

=back

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIO resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIO) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.
