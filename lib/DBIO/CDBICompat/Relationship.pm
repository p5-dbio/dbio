package
    DBIO::CDBICompat::Relationship;

use strict;
use warnings;

use DBIO::_Util 'quote_sub';

=head1 NAME

DBIO::CDBICompat::Relationship - Emulate the Class::DBI::Relationship object returned from meta_info()

=head1 DESCRIPTION

Emulate the Class::DBI::Relationship object returned from C<meta_info()>.

=cut

my %method2key = (
    name            => 'type',
    class           => 'self_class',
    accessor        => 'accessor',
    foreign_class   => 'class',
    args            => 'args',
);

quote_sub __PACKAGE__ . "::$_" => "\$_[0]->{$method2key{$_}}"
  for keys %method2key;

sub new {
    my($class, $args) = @_;

    return bless $args, $class;
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
