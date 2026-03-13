use strict;
use warnings;
use Test::More;

# Test DBIO::Candy
{
    package TestCandy::Result::Artist;
    use DBIO::Candy;

    table 'artists';

    column id => {
        data_type => 'integer',
        is_auto_increment => 1,
    };

    primary_key 'id';

    column name => {
        data_type => 'varchar',
        size => 100,
    };

    unique_constraint ['name'];
}

ok(TestCandy::Result::Artist->isa('DBIO::Core'), 'Candy sets base class to DBIO::Core');
is(TestCandy::Result::Artist->table, 'artists', 'Candy table() works');
ok(TestCandy::Result::Artist->has_column('id'), 'Candy column() works');
ok(TestCandy::Result::Artist->has_column('name'), 'Candy column() works for name');
is_deeply(
    [TestCandy::Result::Artist->primary_columns],
    ['id'],
    'Candy primary_key() works'
);

# Verify sugar functions are cleaned up
# table() is inherited from DBIO::Core, so it stays — only pure sugar functions get cleaned
ok(!TestCandy::Result::Artist->can('column'), 'Sugar function column() cleaned from namespace');
ok(!TestCandy::Result::Artist->can('unique_constraint'), 'Sugar function unique_constraint() cleaned from namespace');

# Test DBIO::Cake
{
    package TestCake::Result::CD;
    use DBIO::Cake;

    table 'cds';

    col id       => integer, auto_inc;
    col title    => varchar(255);
    col year     => integer, null;
    col rating   => boolean, default(0);

    primary_key 'id';
}

ok(TestCake::Result::CD->isa('DBIO::Core'), 'Cake sets base class to DBIO::Core');
is(TestCake::Result::CD->table, 'cds', 'Cake table() works');
ok(TestCake::Result::CD->has_column('id'), 'Cake col() works for id');
ok(TestCake::Result::CD->has_column('title'), 'Cake col() works for title');

my $id_info = TestCake::Result::CD->column_info('id');
is($id_info->{data_type}, 'integer', 'Cake integer type');
is($id_info->{is_auto_increment}, 1, 'Cake auto_inc');

my $title_info = TestCake::Result::CD->column_info('title');
is($title_info->{data_type}, 'varchar', 'Cake varchar type');
is($title_info->{size}, 255, 'Cake varchar size');

my $year_info = TestCake::Result::CD->column_info('year');
is($year_info->{is_nullable}, 1, 'Cake null modifier');

my $rating_info = TestCake::Result::CD->column_info('rating');
is($rating_info->{data_type}, 'boolean', 'Cake boolean type');
is($rating_info->{default_value}, 0, 'Cake default()');
is($rating_info->{is_nullable}, 0, 'Cake default is_nullable => 0');

# Verify sugar functions are cleaned up
# table() is inherited from DBIO::Core, so it stays
ok(!TestCake::Result::CD->can('col'), 'Cake sugar col() cleaned');
ok(!TestCake::Result::CD->can('integer'), 'Cake sugar integer() cleaned');

done_testing;
