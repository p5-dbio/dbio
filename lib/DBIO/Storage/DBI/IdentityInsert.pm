package DBIO::Storage::DBI::IdentityInsert;
# ABSTRACT: Storage Component for Sybase ASE and MSSQL for Identity Inserts / Updates

use strict;
use warnings;
use base 'DBIO::Storage::DBI';
use mro 'c3';

=head1 DESCRIPTION

This is a storage component for Sybase ASE
(L<DBIO::Sybase::Storage::ASE>) and Microsoft SQL Server
(L<DBIO::MSSQL::Storage>) to support identity inserts, that is
inserts of explicit values into C<IDENTITY> columns.

This is done by wrapping C<INSERT> operations in a pair of table identity
toggles like:

  SET IDENTITY_INSERT $table ON
  $sql
  SET IDENTITY_INSERT $table OFF

=cut

=method _prep_for_execute

When explicit identity values are supplied, wrap generated SQL with
C<SET IDENTITY_INSERT ... ON/OFF> statements for the target table.

# SET IDENTITY_X only works as part of a statement scope. We can not
# $dbh->do the $sql and the wrapping set()s individually. Hence the
# sql mangling. The newlines are important.
sub _prep_for_execute {
  my $self = shift;

  return $self->next::method(@_) unless $self->_autoinc_supplied_for_op;

  my ($op, $ident) = @_;

  my $table = $self->sql_maker->_quote($ident->name);
  $op = uc $op;

  my ($sql, $bind) = $self->next::method(@_);

  return (<<EOS, $bind);
SET IDENTITY_$op $table ON
$sql
SET IDENTITY_$op $table OFF
EOS

}

=cut

1;
