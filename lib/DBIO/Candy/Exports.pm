package DBIO::Candy::Exports;
# ABSTRACT: Create sugar for DBIO components

use strict;
use warnings;

use Sub::Name ();

our %methods;
our %aliases;

sub export_methods        { $methods{scalar caller(0)} = $_[0] }
sub export_method_aliases { $aliases{scalar caller(0)} = $_[0] }

use Sub::Exporter -setup => {
   exports => [ qw(export_methods export_method_aliases) ],
   groups  => { default => [ qw(export_methods export_method_aliases) ] },
};

# Sub::Exporter generates an anonymous import; name it so
# t/55namespaces_cleaned.t can verify it
Sub::Name::subname('DBIO::Candy::Exports::import', \&import);

1;

__END__

=head1 SYNOPSIS

 package DBIO::SomeComponent;

 sub create_widget { ... }

 # so you don't depend on ::Candy
 eval {
   require DBIO::Candy::Exports;
   DBIO::Candy::Exports->import;
   export_methods ['create_widget'];
   export_method_aliases {
     widget => 'create_widget'
   };
 };

 1;

The above will make it such that users of your component who use it with
L<DBIO::Candy> will have the methods you designate exported into their
namespace.

=head1 DESCRIPTION

This module allows DBIO components to register sugar functions that
L<DBIO::Candy> will export into result classes that load those components.

=method export_methods

 export_methods [qw( foo bar baz )];

Define methods that get exported as subroutines of the same name.

=method export_method_aliases

 export_method_aliases {
   old_method_name => 'new_sub_name',
 };

Define methods that get exported as subroutines of a different name.
