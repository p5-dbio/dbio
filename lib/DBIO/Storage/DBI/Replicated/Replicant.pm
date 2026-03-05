package DBIO::Storage::DBI::Replicated::Replicant;

use Moose::Role;
requires qw/_query_start/;
with 'DBIO::Storage::DBI::Replicated::WithDSN';
use MooseX::Types::Moose qw/Bool Str/;
use DBIO::Storage::DBI::Replicated::Types 'DBICStorageDBI';

use namespace::clean -except => 'meta';

=head1 NAME

DBIO::Storage::DBI::Replicated::Replicant - A replicated DBI Storage Role

=head1 SYNOPSIS

This class is used internally by L<DBIO::Storage::DBI::Replicated>.

=head1 DESCRIPTION

Replicants are DBI Storages that follow a master DBI Storage.  Typically this
is accomplished via an external replication system.  Please see the documents
for L<DBIO::Storage::DBI::Replicated> for more details.

This class exists to define methods of a DBI Storage that only make sense when
it's a classic 'slave' in a pool of slave databases which replicate from a
given master database.

=head1 ATTRIBUTES

This class defines the following attributes.

=head2 active

This is a boolean which allows you to programmatically activate or deactivate a
replicant from the pool.  This way you can do stuff like disallow a replicant
when it gets too far behind the master, if it stops replicating, etc.

This attribute DOES NOT reflect a replicant's internal status, i.e. if it is
properly replicating from a master and has not fallen too many seconds behind a
reliability threshold. For that, use
L<DBIO::Storage::DBI::Replicated/is_replicating> and
L<DBIO::Storage::DBI::Replicated/lag_behind_master>.
Since the implementation of those functions database specific (and not all DBIC
supported DBs support replication) you should refer your database-specific
storage driver for more information.

=cut

has 'active' => (
  is=>'rw',
  isa=>Bool,
  lazy=>1,
  required=>1,
  default=>1,
);

has dsn => (is => 'rw', isa => Str);
has id  => (is => 'rw', isa => Str);

=head2 master

Reference to the master Storage.

=cut

has master => (is => 'rw', isa => DBICStorageDBI, weak_ref => 1);

=head1 METHODS

This class defines the following methods.

=head2 debugobj

Override the debugobj method to redirect this method call back to the master.

=cut

sub debugobj {
  my $self = shift;

  return $self->master->debugobj;
}

=head1 ALSO SEE

L<http://en.wikipedia.org/wiki/Replicant>,
L<DBIO::Storage::DBI::Replicated>

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut

1;
