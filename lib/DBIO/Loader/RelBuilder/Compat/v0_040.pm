package DBIO::Loader::RelBuilder::Compat::v0_040;
# ABSTRACT: RelBuilder compatibility for v0.04

use strict;
use warnings;
use base 'DBIO::Loader::RelBuilder::Compat::v0_05';
use mro 'c3';

our $VERSION = '0.07053';

sub _relnames_and_method {
    my ( $self, $local_moniker, $rel, $cond, $uniqs, $counters ) = @_;

    my $remote_moniker = $rel->{remote_source};
    my $remote_table   = $rel->{remote_table};

    my $local_table = $rel->{local_table};
    my $local_cols  = $rel->{local_columns};

    # for single-column case, set the remote relname to just the column name
    my ($local_relname) =
        scalar keys %{$cond} == 1
            ? $self->_inflect_singular( values %$cond  )
            : $self->_inflect_singular( lc $remote_table );

    # If more than one rel between this pair of tables, use the local
    # col names to distinguish
    my $remote_relname;
    if ($counters->{$remote_moniker} > 1) {
        my $colnames = '_' . join( '_', @$local_cols );
        $local_relname .= $colnames if keys %$cond > 1;
        ($remote_relname) = $self->_inflect_plural( lc($local_table) . $colnames );
    } else {
        ($remote_relname) = $self->_inflect_plural(lc $local_table);
    }

    return ( $local_relname, $remote_relname, 'has_many' );
}

sub _remote_attrs { }

=head1 NAME

DBIO::Loader::RelBuilder::Compat::v0_040 - RelBuilder for
compatibility with DBIO::Loader version 0.04006

=head1 DESCRIPTION

See L<DBIO::Loader::Base/naming> and
L<DBIO::Loader::RelBuilder>.

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIO resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut

1;
