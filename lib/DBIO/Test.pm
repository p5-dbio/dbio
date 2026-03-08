package DBIO::Test;
# ABSTRACT: Test utilities for DBIO and DBIO driver distributions

use strict;
use warnings;

use DBIO::Test::Schema;
use Carp;

=head1 DESCRIPTION

Provides test utilities for the DBIO ecosystem.  The primary entry point
is L</init_schema> which gives you a fully set up test schema, either
backed by L<DBIO::Test::Storage> (no database needed) or by a real
database connection you supply.

External driver distributions (e.g. L<DBIO::PostgreSQL>, L<DBIO::MySQL>)
should depend on this module for their test suites.

=head1 SYNOPSIS

  use DBIO::Test;

  # Quick schema with fake storage (no DB needed)
  my $schema = DBIO::Test->init_schema;

  # With a real database
  my $schema = DBIO::Test->init_schema(
    dsn  => $ENV{DBIOTEST_PG_DSN},
    user => $ENV{DBIOTEST_PG_USER},
    pass => $ENV{DBIOTEST_PG_PASS},
  );

  # Only SQL generation tests (no deploy/populate)
  my $schema = DBIO::Test->init_schema(no_deploy => 1);

=cut

sub import {
  my $self = shift;

  for my $exp (@_) {
    if ($exp eq ':DiffSQL') {
      require DBIO::SQLMaker;
      require SQL::Abstract::Test;
      my $into = caller(0);
      for (qw(is_same_sql_bind is_same_sql is_same_bind)) {
        no strict 'refs';
        *{"${into}::$_"} = \&{"SQL::Abstract::Test::$_"};
      }
    }
    else {
      croak "Unknown export $exp requested from $self";
    }
  }
}

=method init_schema

  my $schema = DBIO::Test->init_schema(%opts);

Creates and returns a L<DBIO::Test::Schema> instance.

Options:

=over 4

=item dsn, user, pass

Connect to a real database instead of using the fake storage.

=item no_deploy

Skip deploying the test schema tables (via C<< $schema->deploy >>).

=item no_populate

Skip populating the test schema with sample data.

=item no_connect

Return the schema class without connecting.

=item storage_type

Override the storage class used by the schema.

When used together with C<dsn>/C<connect_info>, this behaves like
L<DBIO::Schema/storage_type>.

When used without a real C<dsn>, C<init_schema()> creates a hybrid storage
class combining L<DBIO::Test::Storage> (fake execution) and the requested
driver storage class. This allows offline SQL-generation tests with
driver-specific SQLMaker behavior, for example:

  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::MySQL::Storage',
  );

=item connect_opts

Extra hashref merged into connect options.

=back

=cut

sub init_schema {
  my $self = shift;
  my %args = @_;

  my $schema;

  if ($args{no_connect}) {
    $schema = DBIO::Test::Schema->compose_namespace('DBIO::Test');
    return $schema;
  }

  if ($args{dsn} || $args{connect_info}) {
    # Real database connection
    my @connect = $args{connect_info}
      ? @{$args{connect_info}}
      : ($args{dsn}, $args{user}||'', $args{pass}||'', {
          AutoCommit => 1,
          %{ $args{connect_opts} || {} },
        });

    $schema = DBIO::Test::Schema->clone;
    $schema->storage_type($args{storage_type}) if $args{storage_type};
    $schema = $schema->connect(@connect);
  }
  else {
    # Fake storage — no database needed
    $schema = DBIO::Test::Schema->connect(
      sub { }, # dummy connect coderef, Storage overrides everything
    );
    # Re-bless storage to our fake one
    require DBIO::Test::Storage;

    my $storage_class = 'DBIO::Test::Storage';

    if (my $st = $args{storage_type}) {
      # Create a dynamic subclass that combines fake execution
      # (from DBIO::Test::Storage) with SQL generation behavior
      # (from the requested storage type)
      (my $st_file = "$st.pm") =~ s|::|/|g;
      require $st_file;

      $storage_class = "DBIO::Test::Storage::_hybrid_::${st}";
      if (!$storage_class->isa('DBIO::Test::Storage')) {
        no strict 'refs';
        @{"${storage_class}::ISA"} = ('DBIO::Test::Storage', $st);
        mro::set_mro($storage_class, 'c3');
        # Copy class data from the requested storage type
        for my $attr (qw(sql_limit_dialect sql_quote_char sql_name_sep datetime_parser_type)) {
          my $val = $st->$attr;
          $storage_class->$attr($val) if defined $val;
        }
      }
    }

    my $storage = $storage_class->new($schema);
    # If the requested storage type sets sql_quote_char, propagate it
    # to the sql_maker_opts so the sql_maker picks it up
    if (my $qc = $storage_class->sql_quote_char) {
      $storage->{_sql_maker_opts}{quote_char} = $qc;
      $storage->{_sql_maker_opts}{name_sep} = $storage_class->sql_name_sep || '.';
    }
    $schema->storage($storage);
  }

  if (!$args{no_deploy}) {
    __PACKAGE__->deploy_schema($schema, $args{deploy_args});
    __PACKAGE__->populate_schema($schema) unless $args{no_populate};
  }

  return $schema;
}

=method deploy_schema

  DBIO::Test->deploy_schema($schema, \%sqlt_args);

Deploys the test schema. With a real database this runs
C<< $schema->deploy() >>. With L<DBIO::Test::Storage> this is a no-op
(the fake storage doesn't need tables).

=cut

sub deploy_schema {
  my ($self, $schema, $args) = @_;
  $args ||= {};

  # Fake storage doesn't need deployment
  return if $schema->storage->isa('DBIO::Test::Storage');

  $schema->deploy($args);
}

=method populate_schema

  DBIO::Test->populate_schema($schema);

Populates the test schema with standard test data (artists, CDs,
tracks, etc.).  Skipped when using L<DBIO::Test::Storage>.

=cut

sub populate_schema {
  my ($self, $schema) = @_;

  # Fake storage can't hold data
  return if $schema->storage->isa('DBIO::Test::Storage');

  $schema->populate('Genre', [
    [qw/genreid name/],
    [qw/1       emo  /],
  ]);

  $schema->populate('Artist', [
    [ qw/artistid name/ ],
    [ 1, 'Caterwauler McCrae' ],
    [ 2, 'Random Boy Band' ],
    [ 3, 'We Are Goth' ],
  ]);

  $schema->populate('CD', [
    [ qw/cdid artist title year genreid/ ],
    [ 1, 1, "Spoonful of bees", 1999, 1 ],
    [ 2, 1, "Forkful of bees", 2001 ],
    [ 3, 1, "Caterwaulin' Blues", 1997 ],
    [ 4, 2, "Generic Manufactured Singles", 2001 ],
    [ 5, 3, "Come Be Depressed With Us", 1998 ],
  ]);

  $schema->populate('LinerNotes', [
    [ qw/liner_id notes/ ],
    [ 2, "Buy Whiskey!" ],
    [ 4, "Buy Merch!" ],
    [ 5, "Kill Yourself!" ],
  ]);

  $schema->populate('Tag', [
    [ qw/tagid cd tag/ ],
    [ 1, 1, "Blue" ],
    [ 2, 2, "Blue" ],
    [ 3, 3, "Blue" ],
    [ 4, 5, "Blue" ],
    [ 5, 2, "Cheesy" ],
    [ 6, 4, "Cheesy" ],
    [ 7, 5, "Cheesy" ],
    [ 8, 2, "Shiny" ],
    [ 9, 4, "Shiny" ],
  ]);

  $schema->populate('TwoKeys', [
    [ qw/artist cd/ ],
    [ 1, 1 ],
    [ 1, 2 ],
    [ 2, 2 ],
  ]);

  $schema->populate('FourKeys', [
    [ qw/foo bar hello goodbye sensors/ ],
    [ 1, 2, 3, 4, 'online' ],
    [ 5, 4, 3, 6, 'offline' ],
  ]);

  $schema->populate('OneKey', [
    [ qw/id artist cd/ ],
    [ 1, 1, 1 ],
    [ 2, 1, 2 ],
    [ 3, 2, 2 ],
  ]);

  $schema->populate('SelfRef', [
    [ qw/id name/ ],
    [ 1, 'First' ],
    [ 2, 'Second' ],
  ]);

  $schema->populate('SelfRefAlias', [
    [ qw/self_ref alias/ ],
    [ 1, 2 ]
  ]);

  $schema->populate('ArtistUndirectedMap', [
    [ qw/id1 id2/ ],
    [ 1, 2 ]
  ]);

  $schema->populate('Producer', [
    [ qw/producerid name/ ],
    [ 1, 'Matt S Trout' ],
    [ 2, 'Bob The Builder' ],
    [ 3, 'Fred The Phenotype' ],
  ]);

  $schema->populate('CD_to_Producer', [
    [ qw/cd producer/ ],
    [ 1, 1 ],
    [ 1, 2 ],
    [ 1, 3 ],
  ]);

  $schema->populate('TreeLike', [
    [ qw/id parent name/ ],
    [ 1, undef, 'root' ],
    [ 2, 1, 'foo'  ],
    [ 3, 2, 'bar'  ],
    [ 6, 2, 'blop' ],
    [ 4, 3, 'baz'  ],
    [ 5, 4, 'quux' ],
    [ 7, 3, 'fong'  ],
  ]);

  $schema->populate('Track', [
    [ qw/trackid cd  position title/ ],
    [ 4, 2, 1, "Stung with Success"],
    [ 5, 2, 2, "Stripy"],
    [ 6, 2, 3, "Sticky Honey"],
    [ 7, 3, 1, "Yowlin"],
    [ 8, 3, 2, "Howlin"],
    [ 9, 3, 3, "Fowlin"],
    [ 10, 4, 1, "Boring Name"],
    [ 11, 4, 2, "Boring Song"],
    [ 12, 4, 3, "No More Ideas"],
    [ 13, 5, 1, "Sad"],
    [ 14, 5, 2, "Under The Weather"],
    [ 15, 5, 3, "Suicidal"],
    [ 16, 1, 1, "The Bees Knees"],
    [ 17, 1, 2, "Apiary"],
    [ 18, 1, 3, "Beehind You"],
  ]);

  $schema->populate('Event', [
    [ qw/id starts_at created_on varchar_date varchar_datetime skip_inflation/ ],
    [ 1, '2006-04-25 22:24:33', '2006-06-22 21:00:05', '2006-07-23', '2006-05-22 19:05:07', '2006-04-21 18:04:06'],
  ]);

  $schema->populate('Link', [
    [ qw/id url title/ ],
    [ 1, '', 'aaa' ]
  ]);

  $schema->populate('Bookmark', [
    [ qw/id link/ ],
    [ 1, 1 ]
  ]);

  $schema->populate('Collection', [
    [ qw/collectionid name/ ],
    [ 1, "Tools" ],
    [ 2, "Body Parts" ],
  ]);

  $schema->populate('TypedObject', [
    [ qw/objectid type value/ ],
    [ 1, "pointy", "Awl" ],
    [ 2, "round", "Bearing" ],
    [ 3, "pointy", "Knife" ],
    [ 4, "pointy", "Tooth" ],
    [ 5, "round", "Head" ],
  ]);

  $schema->populate('CollectionObject', [
    [ qw/collection object/ ],
    [ 1, 1 ],
    [ 1, 2 ],
    [ 1, 3 ],
    [ 2, 4 ],
    [ 2, 5 ],
  ]);

  $schema->populate('Owners', [
    [ qw/id name/ ],
    [ 1, "Newton" ],
    [ 2, "Waltham" ],
  ]);

  $schema->populate('BooksInLibrary', [
    [ qw/id owner title source price/ ],
    [ 1, 1, "Programming Perl", "Library", 23 ],
    [ 2, 1, "Dynamical Systems", "Library",  37 ],
    [ 3, 2, "Best Recipe Cookbook", "Library", 65 ],
  ]);
}

1;
