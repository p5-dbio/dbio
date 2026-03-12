package DBIO::StartupCheck;
# ABSTRACT: Run environment checks on startup

use strict;
use warnings;

1;

__END__

=head1 SYNOPSIS

  use DBIO::StartupCheck;

=head1 DESCRIPTION

This module used to check for, and if necessary issue a warning for, a
particular bug found on Red Hat and Fedora systems using their system
perl build. As of September 2008 there are fixed versions of perl for
all current Red Hat and Fedora distributions, but the old check still
triggers, incorrectly flagging those versions of perl to be buggy. A
more comprehensive check has been moved into the test suite in
C<t/99rh_perl_perf_bug.t> and further information about the bug has been
put in L<DBIO::Manual::Troubleshooting>.

Other checks may be added from time to time.

Any checks herein can be disabled by setting an appropriate environment
variable. If your system suffers from a particular bug, you will get a
warning message on startup sent to STDERR, explaining what to do about
it and how to suppress the message. If you don't see any messages, you
have nothing to worry about.

=cut
