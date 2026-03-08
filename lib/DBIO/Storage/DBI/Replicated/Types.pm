package DBIO::Storage::DBI::Replicated::Types;
# ABSTRACT: Type constraints used by replicated storage components

=head1 SYNOPSIS

Used internally by L<DBIO::Storage::DBI::Replicated> and related classes.

=head1 DESCRIPTION

Defines shared Moose type constraints and coercions for replicated storage:
schema/storage classes, balancer-class resolution, and read-weight validation.

=head1 TYPES

=head2 BalancerClassNamePart

A loadable class name. Strings beginning with C<::> are coerced into
C<DBIO::Storage::DBI::Replicated::Balancer::...>.

=head2 Weight

Numeric value greater than or equal to zero.

=head2 DBICSchema

Subtype of L<DBIO::Schema>.

=head2 DBICStorageDBI

Subtype of L<DBIO::Storage::DBI>.

=cut

# Workaround for https://rt.cpan.org/Public/Bug/Display.html?id=83336
use warnings;
use strict;

use MooseX::Types
  -declare => [qw/BalancerClassNamePart Weight DBICSchema DBICStorageDBI/];
use MooseX::Types::Moose qw/ClassName Str Num/;
use MooseX::Types::LoadableClass qw/LoadableClass/;

class_type 'DBIO::Storage::DBI';
class_type 'DBIO::Schema';

subtype DBICSchema, as 'DBIO::Schema';
subtype DBICStorageDBI, as 'DBIO::Storage::DBI';

subtype BalancerClassNamePart,
  as LoadableClass;

coerce BalancerClassNamePart,
  from Str,
  via {
    my $type = $_;
    $type =~ s/\A::/DBIO::Storage::DBI::Replicated::Balancer::/;
    $type;
  };

subtype Weight,
  as Num,
  where { $_ >= 0 },
  message { 'weight must be a decimal greater than 0' };

1;
