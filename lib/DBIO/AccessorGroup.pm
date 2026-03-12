package DBIO::AccessorGroup;
# ABSTRACT: See Class::Accessor::Grouped

use strict;
use warnings;

use base qw/Class::Accessor::Grouped/;
use Scalar::Util qw/weaken blessed/;
use namespace::clean;

my $successfully_loaded_components;

=method get_component_class

Resolve and lazily load a configured component class.

=cut

sub get_component_class {
  my $class = $_[0]->get_inherited($_[1]);

  # It's already an object, just go for it.
  return $class if blessed $class;

  if (defined $class and ! $successfully_loaded_components->{$class} ) {
    $_[0]->ensure_class_loaded($class);

    no strict 'refs';
    $successfully_loaded_components->{$class}
      = ${"${class}::__LOADED__BY__DBIC__CAG__COMPONENT_CLASS__"}
        = do { \(my $anon = 'loaded') };
    weaken($successfully_loaded_components->{$class});
  }

  $class;
};

=method set_component_class

Set inherited component class configuration.

=cut

sub set_component_class {
  shift->set_inherited(@_);
}

1;

=head1 SYNOPSIS

=head1 DESCRIPTION

This class now exists in its own right on CPAN as Class::Accessor::Grouped

=cut
