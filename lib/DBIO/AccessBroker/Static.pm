# ABSTRACT: Single-DSN AccessBroker drop-in replacement
package DBIO::AccessBroker::Static;

use strict;
use warnings;
use base 'DBIO::AccessBroker';

__PACKAGE__->mk_group_accessors('simple' => qw(
  dsn username password dbi_attrs
));

sub new {
  my ($class, %args) = @_;
  my $self = $class->SUPER::new(%args);
  $self->dsn($args{dsn})           if exists $args{dsn};
  $self->username($args{username} // '');
  $self->password($args{password} // '');
  $self->dbi_attrs($args{dbi_attrs} // {});
  return $self;
}

sub connect_info_for {
  my ($self, $mode) = @_;
  return [$self->dsn, $self->username, $self->password, $self->dbi_attrs];
}

sub needs_refresh { 0 }

1;