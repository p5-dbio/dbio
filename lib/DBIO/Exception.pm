package DBIO::Exception;

use strict;
use warnings;

# load Carp early to prevent tickling of the ::Internal stash being
# interpreted as "Carp is already loaded" by some braindead loader
use Carp ();
$Carp::Internal{ (__PACKAGE__) }++;

use DBIO::Carp ();

use overload
    '""' => sub { shift->{msg} },
    fallback => 1;

=head1 NAME

DBIO::Exception - Exception objects for DBIO

=head1 DESCRIPTION

Exception objects of this class are used internally by
the default error handling of L<DBIO::Schema/throw_exception>
and derivatives.

These objects stringify to the contained error message, and use
overload fallback to give natural boolean/numeric values.

=head1 METHODS

=head2 throw

=over 4

=item Arguments: $exception_scalar, $stacktrace

=back

This is meant for internal use by L<DBIO>'s C<throw_exception>
code, and shouldn't be used directly elsewhere.

Expects a scalar exception message. The optional boolean C<$stacktrace>
causes it to output a full trace similar to L<confess|Carp/DESCRIPTION>.

  DBIO::Exception->throw('Foo');
  try { ... } catch { DBIO::Exception->throw(shift) }

=cut

sub throw {
    my ($class, $msg, $stacktrace) = @_;

    # Don't re-encapsulate exception objects of any kind
    die $msg if ref($msg);

    # all exceptions include a caller
    $msg =~ s/\n$//;

    if(!$stacktrace) {
        # skip all frames that match the original caller, or any of
        # the dbic-wide classdata patterns
        my ($ln, $calling) = DBIO::Carp::__find_caller(
          '^' . caller() . '$',
          'DBIO',
        );

        $msg = "${calling}${msg} ${ln}\n";
    }
    else {
        $msg = Carp::longmess($msg);
    }

    my $self = { msg => $msg };
    bless $self => $class;

    die $self;
}

=head2 rethrow

This method provides some syntactic sugar in order to
re-throw exceptions.

=cut

sub rethrow {
    die shift;
}

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut

1;
