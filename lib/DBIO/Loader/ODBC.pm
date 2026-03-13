package DBIO::Loader::ODBC;
# ABSTRACT: ODBC proxy — detects backend and reblesses to driver-specific Loader

use strict;
use warnings;
use base 'DBIO::Loader::DBI';
use mro 'c3';

our $VERSION = '0.07053';

=head1 DESCRIPTION

When connecting via L<DBD::ODBC>, this class detects the actual database backend
using C<< $dbh->get_info(17) >> and reblesses into the appropriate
driver-specific Loader class (e.g. L<DBIO::MSSQL::Loader::ODBC>,
L<DBIO::Firebird::Loader::ODBC>).

No ODBC-specific introspection logic lives here — it is purely a dispatch proxy.

See L<DBIO::Loader::Base> for usage information.

=cut

sub _rebless {
    my $self = shift;

    return if ref $self ne __PACKAGE__;

    my $dbh    = $self->schema->storage->dbh;
    my $dbtype = eval { $dbh->get_info(17) };
    unless ( $@ ) {
        # Translate the backend name into a perl identifier
        $dbtype =~ s/\W/_/gi;

        my %odbc_loader = (
            Microsoft_SQL_Server => 'DBIO::MSSQL::Loader::ODBC',
            SQL_Anywhere         => 'DBIO::MSSQL::Loader::SQLAnywhere',
            Firebird             => 'DBIO::Firebird::Loader::ODBC',
        );

        my $class = $odbc_loader{$dbtype}
            || 'DBIO::' . $dbtype . '::Loader::ODBC';

        if ($self->load_optional_class($class) && !$self->isa($class)) {
            bless $self, $class;
            $self->_rebless;
        }
    }
}

=head1 SEE ALSO

L<DBIO::MSSQL::Loader::ODBC>,
L<DBIO::Firebird::Loader::ODBC>,
L<DBIO::Loader>, L<DBIO::Loader::Base>,
L<DBIO::Loader::DBI>

=cut

1;
