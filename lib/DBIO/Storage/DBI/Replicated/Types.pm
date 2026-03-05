package # hide from PAUSE
  DBIO::Storage::DBI::Replicated::Types;

# DBIO::Storage::DBI::Replicated::Types - Types used internally by
# L<DBIO::Storage::DBI::Replicated>

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
