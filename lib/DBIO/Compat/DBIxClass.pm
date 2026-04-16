package DBIO::Compat::DBIxClass;
# ABSTRACT: Runtime compatibility layer for DBIx::Class names on DBIO

use strict;
use warnings;

my $hook_installed;
my $isa_patched;

=head1 METHODS

=method import

Install compatibility hooks and aliases.

=cut

sub import {
  _install_hook();
  _install_isa_patch();
  _setup_existing_modules();
}

=method _install_hook

Install the C<@INC> hook once.

=cut

sub _install_hook {
  return if $hook_installed;
  $hook_installed = 1;
  unshift @INC, \&_dbic_inc_hook;
}

=method _install_isa_patch

Patch C<DBIO::isa> to acknowledge C<DBIx::Class::*> package names.

=cut

sub _install_isa_patch {
  return if $isa_patched;

  # DBIO::Base is the meta-infra parent of every internal class;
  # patching its isa propagates via MRO to DBIO::Core/Row/Schema/...
  # The direct *DBIO::isa patch keeps `DBIO->isa('DBIx::Class')` working.
  my $orig_isa = DBIO::Base->can('isa') or return;
  $isa_patched = 1;

  my $patch = sub {
    return 1 if $orig_isa->(@_);
    if (defined $_[1]) {
      if ($_[1] eq 'DBIx::Class') {
        # Any class in the DBIO world is considered a DBIx::Class
        my $class = ref($_[0]) || $_[0];
        return 1 if $class eq 'DBIO' || $class eq 'DBIO::Base';
        return 1 if $orig_isa->($_[0], 'DBIO::Base');
        return '';
      }
      if ($_[1] =~ /^DBIx::Class::(.+)$/) {
        return $orig_isa->($_[0], "DBIO::$1");
      }
    }
    return '';
  };

  no warnings 'redefine';
  *DBIO::Base::isa = $patch;
  *DBIO::isa       = $patch;
}

# For a given DBIO package, set up the DBIx::Class equivalent
=method _setup_dbix_package

Create and initialize a DBIx::Class alias package for a DBIO package.

=cut

sub _setup_dbix_package {
  my ($dbix_pkg, $dbic_pkg) = @_;

  no strict 'refs';
  unless (@{"${dbix_pkg}::ISA"}) {
    @{"${dbix_pkg}::ISA"} = ($dbic_pkg);
  }
  require mro;
  mro::set_mro($dbix_pkg, mro::get_mro($dbic_pkg));
}

# Scan %INC for all loaded DBIO modules and ensure their
# DBIx::Class aliases exist. Called at import time and
# every time the hook intercepts a DBIx::Class require.
=method _setup_existing_modules

Synchronize aliases for already-loaded DBIO modules.

=cut

sub _setup_existing_modules {
  for my $file (keys %INC) {
    next unless $file =~ m{^DBIO(/|\.pm$)};
    (my $dbix_file = $file) =~ s{^DBIO(?=/|\.pm$)}{DBIx/Class};
    next if exists $INC{$dbix_file};

    (my $dbic_pkg = $file) =~ s{/}{::}g;
    $dbic_pkg =~ s{\.pm$}{};
    (my $dbix_pkg = $dbix_file) =~ s{/}{::}g;
    $dbix_pkg =~ s{\.pm$}{};

    # The naked DBIx::Class name historically carried the meta-infra
    # (Componentised, AccessorGroup, mk_classdata, component_base_class...).
    # After the DBIO/DBIO::Base split that machinery lives in DBIO::Base,
    # so DBIx::Class (the alias) must inherit from there, not from
    # DBIO.pm (which is now just a sugar pragma).
    if ($dbic_pkg eq 'DBIO') {
      require DBIO::Base;
      _setup_dbix_package($dbix_pkg, 'DBIO::Base');
    }
    else {
      _setup_dbix_package($dbix_pkg, $dbic_pkg);
    }
    $INC{$dbix_file} = $INC{$file};
  }

  _install_isa_patch();
}

=method _dbic_inc_hook

C<@INC> hook that maps DBIx::Class module requests to DBIO modules.

=cut

sub _dbic_inc_hook {
  my (undef, $file) = @_;

  # Only intercept DBIx/Class requests
  return unless $file =~ /^DBIx\/Class(?:\/|\.pm$)/;

  # Every time any DBIx::Class module is requested, ensure all
  # already-loaded DBIO modules have their DBIx::Class aliases.
  # This handles the case where ResultDDL's table() references
  # DBIx::Class::Core->can('table') but nobody ever did
  # require DBIx::Class::Core (because the class was set up
  # through DBIO::Core directly).
  _setup_existing_modules();

  # Map DBIx/Class.pm -> DBIO.pm, DBIx/Class/Foo.pm -> DBIO/Foo.pm
  (my $dbic_file = $file) =~ s{^DBIx/Class(?=/|\.pm$)}{DBIO};

  # Derive package names
  (my $dbix_pkg = $file) =~ s{/}{::}g;
  $dbix_pkg =~ s{\.pm$}{};

  (my $dbic_pkg = $dbic_file) =~ s{/}{::}g;
  $dbic_pkg =~ s{\.pm$}{};

  # If _setup_existing_modules already set this up, return a stub
  # to prevent Perl from finding a real DBIx::Class file on disk
  if (exists $INC{$file}) {
    open my $fh, '<', \"1;\n";
    return $fh;
  }

  # Check that the DBIO equivalent actually exists on disk
  for my $inc (@INC) {
    next if ref $inc;
    next unless -f "$inc/$dbic_file";

    # Load the DBIO module and set up the alias
    local $@;
    eval "require ${dbic_pkg}; 1" or do {
      warn "DBIO::Compat::DBIxClass: Failed to load ${dbic_pkg}: $@";
      return;
    };
    # Naked DBIO is the sugar pragma; the meta-infra DBIx::Class
    # historically matches lives in DBIO::Base.
    if ($dbic_pkg eq 'DBIO') {
      require DBIO::Base;
      _setup_dbix_package($dbix_pkg, 'DBIO::Base');
    }
    else {
      _setup_dbix_package($dbix_pkg, $dbic_pkg);
    }
    $INC{$file} = $INC{$dbic_file};

    # Return minimal stub to satisfy the require
    open my $fh, '<', \"1;\n";
    return $fh;
  }

  return;
}

=head1 SYNOPSIS

  use DBIO::Compat::DBIxClass;

  # DBIx::Class-oriented plugins can now target the DBIO process:
  use DBIx::Class::ResultDDL qw/ -V2 /;

=head1 DESCRIPTION

This module lets DBIx::Class-oriented extensions run in a DBIO process without
shipping parallel compatibility files on disk.

It installs an C<@INC> hook that maps C<DBIx::Class::*> requests to the
corresponding C<DBIO::*> modules, then creates runtime alias packages so the
DBIx::Class names inherit from the DBIO implementations. That keeps
C<require>, method dispatch, and C<can()> aligned with the loaded DBIO code.

Whenever a C<DBIx::Class::*> module is requested, already-loaded C<DBIO::*>
packages are also synchronized to their DBIx::Class aliases. This covers code
that reaches for names such as C<DBIx::Class::Core> even though the schema or
result classes were built directly on C<DBIO::Core>.

DBIO's C<isa()> handling is patched as well, so
C<< $obj->isa('DBIx::Class::Foo') >> stays true whenever the object is really a
C<DBIO::Foo>.

No files are written to disk. The compatibility layer exists entirely at
runtime and does not create PAUSE-indexed shadow modules.

=cut

1;
