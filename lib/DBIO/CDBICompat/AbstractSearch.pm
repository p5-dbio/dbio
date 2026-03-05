package # hide form PAUSE
    DBIO::CDBICompat::AbstractSearch;

use strict;
use warnings;

=head1 NAME

DBIO::CDBICompat::AbstractSearch - Emulates Class::DBI::AbstractSearch

=head1 SYNOPSIS

See DBIO::CDBICompat for usage directions.

=head1 DESCRIPTION

Emulates L<Class::DBI::AbstractSearch>.

=cut

# The keys are mostly the same.
my %cdbi2dbix = (
    limit               => 'rows',
);

sub search_where {
    my $class = shift;
    my $where = (ref $_[0]) ? $_[0] : { @_ };
    my $attr  = (ref $_[0]) ? $_[1] : {};

    # Translate the keys
    $attr->{$cdbi2dbix{$_}} = delete $attr->{$_} for keys %cdbi2dbix;

    return $class->resultset_instance->search($where, $attr);
}

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut

1;
