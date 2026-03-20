package DBIO::Loader::DBI::Component::QuotedDefault;
# ABSTRACT: Mixin for handling quoted column defaults

use strict;
use warnings;
use base 'DBIO::Loader::DBI';
use mro 'c3';

our $VERSION = '0.07053';

=head1 NAME

DBIO::Loader::DBI::Component::QuotedDefault -- Loader::DBI
Component to parse quoted default constants and functions

=head1 DESCRIPTION

If C<COLUMN_DEF> from L<DBI/column_info> returns character constants quoted,
then we need to remove the quotes. This also allows distinguishing between
default functions without information schema introspection.

=cut

sub _columns_info_for {
    my $self    = shift;
    my ($table) = @_;

    my ($result,$raw) = $self->next::method(@_);

    while (my ($col, $info) = each %$result) {
        if (my $def = $info->{default_value}) {
            $def =~ s/^\s+//;
            $def =~ s/\s+\z//;

# remove Pg typecasts (e.g. 'foo'::character varying) too
            if ($def =~ /^["'](.*?)['"](?:::[\w\s]+)?\z/) {
                $info->{default_value} = $1;
            }
# Some DBs (eg. Pg) put parenthesis around negative number defaults
            elsif ($def =~ /^\((-?\d.*?)\)(?:::[\w\s]+)?\z/) {
                $info->{default_value} = $1;
            }
            elsif ($def =~ /^(-?\d.*?)(?:::[\w\s]+)?\z/) {
                $info->{default_value} = $1;
            }
            elsif ($def =~ /^NULL:?/i) {
                my $null = 'null';
                $info->{default_value} = \$null;
            }
            else {
                $info->{default_value} = \$def;
            }
        }
    }

    return wantarray ? ($result, $raw) : $result;
}

1;

=head1 SEE ALSO

L<DBIO::Loader>, L<DBIO::Loader::Base>,
L<DBIO::Loader::DBI>

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIO resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut
