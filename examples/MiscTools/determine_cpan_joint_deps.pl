#!/usr/bin/env perl

use warnings;
use strict;

use CPANDB;
use DBIO::Schema::Loader 0.05;
use Data::Dumper::Concise;

{
  package CPANDB::Schema;
  use base qw/DBIO::Schema::Loader/;

  __PACKAGE__->loader_options (
    naming => 'v5',
  );
}

my $s = CPANDB::Schema->connect (sub { CPANDB->dbh } );

# reference names are unstable - just create rels manually
my $distrsrc = $s->source('Distribution');

# the has_many helper is a class-only method (why?), thus
# manual add_rel
$distrsrc->add_relationship (
  'deps',
  $s->class('Dependency'),
  { 'foreign.distribution' => 'self.' . ($distrsrc->primary_columns)[0] },
  { accessor => 'multi', join_type => 'left' },
);

# here is how one could use the helper currently:
#
#my $distresult = $s->class('Distribution');
#$distresult->has_many (
#  'deps',
#  $s->class('Dependency'),
#  'distribution',
#);
#$s->unregister_source ('Distribution');
#$s->register_class ('Distribution', $distresult);


# a proof of concept how to find out who uses us *AND* SQLT
my $us_and_sqlt = $s->resultset('Distribution')->search (
  {
    'deps.dependency' => 'DBIO',
    'deps_2.dependency' => 'SQL-Translator',
  },
  {
    join => [qw/deps deps/],
    order_by => 'me.author',
    select => [ 'me.distribution', 'me.author', map { "$_.phase" } (qw/deps deps_2/)],
    as => [qw/dist_name dist_author req_dbic_at req_sqlt_at/],
    result_class => 'DBIO::ResultClass::HashRefInflator',
  },
);

print Dumper [$us_and_sqlt->all];
