package DBIO::Test::Util::UmaskGuard;
# ABSTRACT: RAII guard that restores the umask on scope exit

use strict;
use warnings;

sub DESTROY {
  local ($@, $!);
  eval { defined(umask ${ $_[0] }) or die };
  warn("Unable to reset old umask ${ $_[0] }: " . ($! || 'Unknown error'))
    if $@ || $!;
}

1;
