#   belongs to t/86sqlt.t
package DBIO::Test::DeployComponent;
# ABSTRACT: Test component for sqlt_deploy_hook testing
use warnings;
use strict;

our $hook_cb;

sub sqlt_deploy_hook {
  my $class = shift;

  $hook_cb->($class, @_) if $hook_cb;
  $class->next::method(@_) if $class->next::can;
}

1;
