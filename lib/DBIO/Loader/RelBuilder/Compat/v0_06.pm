package DBIO::Loader::RelBuilder::Compat::v0_06;
# ABSTRACT: RelBuilder compatibility for v0.06

use strict;
use warnings;
use base 'DBIO::Loader::RelBuilder::Compat::v0_07';
use mro 'c3';

our $VERSION = '0.07053';

sub _normalize_name {
    my ($self, $name) = @_;

    $name = $self->_sanitize_name($name);

    return lc $name;
}

=head1 NAME

DBIO::Loader::RelBuilder::Compat::v0_06 - RelBuilder for
compatibility with DBIO::Loader version 0.06000

=head1 DESCRIPTION

See L<DBIO::Loader::Base/naming> and
L<DBIO::Loader::RelBuilder>.

=head1 AUTHORS

See L<DBIO::Loader/AUTHORS>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
# vim:et sts=4 sw=4 tw=0:
