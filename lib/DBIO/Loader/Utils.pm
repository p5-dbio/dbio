package DBIO::Loader::Utils;
# ABSTRACT: Utility functions for the Loader

use strict;
use warnings;
use DBIO::Util ();
use base 'Exporter';

our @EXPORT_OK = qw/split_name dumper dumper_squashed eval_package_without_redefine_warnings class_path no_warnings warnings_exist warnings_exist_silent slurp_file write_file array_eq sigwarn_silencer apply firstidx uniq/;

# Re-export from DBIO::Util via delegation -- no imports to pollute namespace

sub split_name  { shift if $_[0] eq __PACKAGE__; goto &DBIO::Util::split_name }
sub dumper_squashed { goto &DBIO::Util::dumper_squashed }
sub sigwarn_silencer { goto &DBIO::Util::sigwarn_silencer }
sub eval_package_without_redefine_warnings { goto &DBIO::Util::eval_package_without_redefine_warnings }
sub class_path  { goto &DBIO::Util::class_path }
sub write_file  { goto &DBIO::Util::write_file }
sub array_eq    { goto &DBIO::Util::array_eq }
sub firstidx (&@) { goto &DBIO::Util::firstidx }
sub uniq (@)    { goto &DBIO::Util::uniq }
sub apply (&@)  { goto &DBIO::Util::apply }

# slurp_file in Loader context always means UTF-8 + CRLF normalization
sub slurp_file  { goto &DBIO::Util::slurp_file_utf8 }

# dumper is only used in Loader context, not worth moving to core
sub dumper {
  require Data::Dumper;
  my $dd = Data::Dumper->new([]);
  $dd->Terse(1)->Indent(1)->Useqq(1)->Deparse(1)->Quotekeys(0)->Sortkeys(1);
  return $dd->Values([ $_[0] ])->Dump;
}

# test helpers -- only used in Loader test suites
sub no_warnings(&;$) {
  my ($code, $test_name) = @_;
  my $failed = 0;
  my $warn_handler = $SIG{__WARN__} || sub { warn @_ };
  local $SIG{__WARN__} = sub { $failed = 1; $warn_handler->(@_) };
  $code->();
  Test::More::ok((not $failed), $test_name);
}

sub warnings_exist(&$$) {
  my ($code, $re, $test_name) = @_;
  my $matched = 0;
  my $warn_handler = $SIG{__WARN__} || sub { warn @_ };
  local $SIG{__WARN__} = sub {
    if ($_[0] =~ $re) { $matched = 1 } else { $warn_handler->(@_) }
  };
  $code->();
  Test::More::ok $matched, $test_name;
}

sub warnings_exist_silent(&$$) {
  my ($code, $re, $test_name) = @_;
  my $matched = 0;
  local $SIG{__WARN__} = sub { $matched = 1 if $_[0] =~ $re };
  $code->();
  Test::More::ok $matched, $test_name;
}

1;
# vim:et sts=4 sw=4 tw=0:
