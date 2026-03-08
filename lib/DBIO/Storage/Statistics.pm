package DBIO::Storage::Statistics;
# ABSTRACT: SQL Statistics

use strict;
use warnings;

use DBIO::_Util qw(sigwarn_silencer qsub);
use IO::Handle ();
use Moo;
extends 'DBIO';
use namespace::clean;

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is called by DBIO::Storage::DBI as a means of collecting
statistics on its actions.  Using this class alone merely prints the SQL
executed, the fact that it completes and begin/end notification for
transactions.

To really use this class you should subclass it and create your own method
for collecting the statistics as discussed in L<DBIO::Manual::Cookbook>.

=head1 METHODS

=method new

Returns a new L<DBIO::Storage::Statistics> object.

=method debugfh

Sets or retrieves the filehandle used for trace/debug output.  This should
be an L<IO::Handle> compatible object (only the
L<< print|IO::Handle/METHODS >> method is used). By
default it is initially set to STDERR - although see discussion of the
L<DBIC_TRACE|DBIO::Storage/DBIC_TRACE> environment variable.

Invoked as a getter it will lazily open a filehandle and set it to
L<< autoflush|perlvar/HANDLE->autoflush( EXPR ) >> (if one is not
already set).

=cut

# FIXME - there ought to be a way to fold this into _debugfh itself
# having the undef re-trigger the builder (or better yet a default
# which can be folded in as a qsub)
sub debugfh {
  my $self = shift;

  return $self->_debugfh(@_) if @_;
  $self->_debugfh || $self->_build_debugfh;
}

has _debugfh => (
  is => 'rw',
  lazy => 1,
  trigger => qsub '$_[0]->_defaulted_to_stderr(undef)',
  builder => '_build_debugfh',
);

sub _build_debugfh {
  my $fh;

  my $debug_env = $ENV{DBIX_CLASS_STORAGE_DBI_DEBUG} || $ENV{DBIC_TRACE};

  if (defined($debug_env) and ($debug_env =~ /=(.+)$/)) {
    open ($fh, '>>', $1)
      or die("Cannot open trace file $1: $!\n");
  }
  else {
    open ($fh, '>&STDERR')
      or die("Duplication of STDERR for debug output failed (perhaps your STDERR is closed?): $!\n");
    $_[0]->_defaulted_to_stderr(1);
  }

  $fh->autoflush(1);

  $fh;
}

has [qw(_defaulted_to_stderr silence callback)] => (
  is => 'rw',
);

=attr _defaulted_to_stderr

Internal flag indicating that debug output currently defaults to STDERR.

=attr silence

Boolean flag to suppress trace output when true.

=attr callback

Optional callback invoked by C<query_start> instead of printing.

=method print

Prints the specified string to our debugging filehandle.  Provided to save our
methods the worry of how to display the message.

=cut
sub print {
  my ($self, $msg) = @_;

  return if $self->silence;

  my $fh = $self->debugfh;

  # not using 'no warnings' here because all of this can change at runtime
  local $SIG{__WARN__} = sigwarn_silencer(qr/^Wide character in print/)
    if $self->_defaulted_to_stderr;

  $fh->print($msg);
}

=method txn_begin

Called when a transaction begins.

=cut
sub txn_begin {
  my $self = shift;

  return if $self->callback;

  $self->print("BEGIN WORK\n");
}

=method txn_rollback

Called when a transaction is rolled back.

=cut
sub txn_rollback {
  my $self = shift;

  return if $self->callback;

  $self->print("ROLLBACK\n");
}

=method txn_commit

Called when a transaction is committed.

=cut
sub txn_commit {
  my $self = shift;

  return if $self->callback;

  $self->print("COMMIT\n");
}

=method svp_begin

Called when a savepoint is created.

=cut
sub svp_begin {
  my ($self, $name) = @_;

  return if $self->callback;

  $self->print("SAVEPOINT $name\n");
}

=method svp_release

Called when a savepoint is released.

=cut
sub svp_release {
  my ($self, $name) = @_;

  return if $self->callback;

  $self->print("RELEASE SAVEPOINT $name\n");
}

=method svp_rollback

Called when rolling back to a savepoint.

=cut
sub svp_rollback {
  my ($self, $name) = @_;

  return if $self->callback;

  $self->print("ROLLBACK TO SAVEPOINT $name\n");
}

=method query_start

Called before a query is executed.  The first argument is the SQL string being
executed and subsequent arguments are the parameters used for the query.

=cut
sub query_start {
  my ($self, $string, @bind) = @_;

  my $message = "$string: ".join(', ', @bind)."\n";

  if(defined($self->callback)) {
    $string =~ m/^(\w+)/;
    $self->callback->($1, $message);
    return;
  }

  $self->print($message);
}

=method query_end

Called when a query finishes executing.  Has the same arguments as query_start.

=cut

sub query_end {
  my ($self, $string) = @_;
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
