#!/usr/bin/env perl

# Benchmark: DESTROY overhead on row objects
#
# In DBIx::Class (and early DBIO), every single object inherited a DESTROY
# method from the root class that maintained a destruction registry:
#
#   sub DESTROY { &DBIO::Util::detected_reinvoked_destructor }
#
# The registry protected against broken Perl/toolchain versions that could
# invoke destructors multiple times. On each DESTROY it:
#   1. Iterated ALL known live objects to GC dead weakrefs  <- O(n) per call
#   2. Checked the registry for this specific object        <- O(1)
#
# Total cost: O(n) per object destruction = O(n^2) for n objects.
#
# DBIO removed this in commit 8c3c3059. This benchmark demonstrates the gain.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use Benchmark qw(cmpthese);
use Scalar::Util qw(weaken refaddr);

# -----------------------------------------------------------------------
# Simulate the old detection mechanism (stripped down for benchmarking)
# -----------------------------------------------------------------------
{
  package _Old::Root;

  my $registry = {};

  sub new { bless {}, shift }

  sub DESTROY {
    my $self = $_[0];

    # GC pass — this is the expensive O(n) part
    defined $registry->{$_} or delete $registry->{$_}
      for keys %$registry;

    my $addr = refaddr($self);
    if (!defined $registry->{$addr}) {
      weaken($registry->{$addr} = $self);
    }
  }
}

# -----------------------------------------------------------------------
# New DBIO root — no DESTROY at all
# -----------------------------------------------------------------------
{
  package _New::Root;
  sub new { bless {}, shift }
  # no DESTROY
}

# -----------------------------------------------------------------------
# Run at increasing object counts
# -----------------------------------------------------------------------
for my $n (10, 100, 500, 2000, 10_000) {
  printf "\n--- %d objects (create + destroy cycle) ---\n", $n;

  cmpthese(-2, {
    'old (with registry)' => sub {
      my @objs = map { _Old::Root->new } 1..$n;
      @objs = ();
    },
    'new (no DESTROY)' => sub {
      my @objs = map { _New::Root->new } 1..$n;
      @objs = ();
    },
  });
}
