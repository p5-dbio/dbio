package DBIO::Loader::RelBuilder::Compat::v0_07;
# ABSTRACT: RelBuilder compatibility for v0.07

use strict;
use warnings;
use base 'DBIO::Loader::RelBuilder';
use mro 'c3';

=head1 NAME

DBIO::Loader::RelBuilder::Compat::v0_07 - RelBuilder for
compatibility with DBIO::Loader version 0.07000

=head1 DESCRIPTION

See L<DBIO::Loader::Base/naming> and
L<DBIO::Loader::RelBuilder>.

=cut

our $VERSION = '0.07053';

sub _strip_id_postfix {
    my ($self, $name) = @_;

    $name =~ s/_id\z//;

    return $name;
}

=head1 AUTHORS

See L<DBIO::Loader/AUTHORS>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
# vim:et sts=4 sw=4 tw=0:
