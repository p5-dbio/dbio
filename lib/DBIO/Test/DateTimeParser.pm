package DBIO::Test::DateTimeParser;
# ABSTRACT: Minimal datetime parser for DBIO offline test storage

use strict;
use warnings;

sub new { bless {}, shift }

sub parse_datetime { $_[1] }
sub parse_date     { $_[1] }
sub parse_time     { $_[1] }

sub format_datetime { $_[1] }
sub format_date     { $_[1] }
sub format_time     { $_[1] }

1;
