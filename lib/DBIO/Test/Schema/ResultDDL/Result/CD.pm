package DBIO::Test::Schema::ResultDDL::Result::CD;
# ABSTRACT: Test Cake result class for the cd table
use DBIO::Cake;
table 'cd';
col id        => integer, unsigned, auto_inc;
col artist_id => integer, unsigned;
col title     => varchar(255);
col year      => integer, null;
primary_key 'id';
belongs_to artist => { id => 'Artist.artist_id' };
1;
