package DBIO::Compat::DBIxClass;
# ABSTRACT: Compatibility layer to use DBIx::Class plugins with DBIO

use strict;
use warnings;

my $hook_installed;

sub import {
  return if $hook_installed;
  unshift @INC, \&_dbic_inc_hook;
  $hook_installed = 1;
}

sub _dbic_inc_hook {
  my (undef, $file) = @_;

  # Only intercept DBIx/Class requests
  return unless $file =~ /^DBIx\/Class(?:\/|\.pm$)/;

  # Map DBIx/Class.pm -> DBIO.pm, DBIx/Class/Foo.pm -> DBIO/Foo.pm
  (my $dbic_file = $file) =~ s{^DBIx/Class(?=/|\.pm$)}{DBIO};

  # Derive package names
  (my $dbix_pkg = $file) =~ s{/}{::}g;
  $dbix_pkg =~ s{\.pm$}{};

  (my $dbic_pkg = $dbic_file) =~ s{/}{::}g;
  $dbic_pkg =~ s{\.pm$}{};

  # Check that the DBIO equivalent actually exists
  for my $inc (@INC) {
    next if ref $inc;
    next unless -f "$inc/$dbic_file";

    # Generate a stub that loads the DBIO module and aliases the stash
    my $code = "require $dbic_pkg; *${dbix_pkg}:: = *${dbic_pkg}::; 1;\n";
    open my $fh, '<', \$code;
    return $fh;
  }

  return;
}

=head1 SYNOPSIS

  use DBIO::Compat::DBIxClass;

  # Now any DBIx::Class plugin works transparently:
  use DBIx::Class::ResultDDL qw/ -V2 /;

=head1 DESCRIPTION

This module installs an C<@INC> hook that intercepts any attempt to load
a C<DBIx::Class::*> module and transparently redirects it to the
corresponding C<DBIO::*> module. The C<DBIx::Class::*> namespace is then
aliased to the C<DBIO::*> stash, so method calls, C<can()>, and C<isa()>
all work correctly.

This allows existing CPAN modules written for C<DBIx::Class> to work
with DBIO without any modifications.

No files are created on disk — the compatibility stubs are generated
purely at runtime and will not be indexed by PAUSE.

=cut

1;
