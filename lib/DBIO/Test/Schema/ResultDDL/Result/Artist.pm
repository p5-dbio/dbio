package DBIO::Test::Schema::ResultDDL::Result::Artist;
# ABSTRACT: Test Cake result class for the artist table
use DBIO::Cake;
table 'artist';
col id   => integer, unsigned, auto_inc;
col name => varchar(100), null;
primary_key 'id';
1;
