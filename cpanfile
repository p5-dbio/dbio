requires 'perl', '5.008001';

# DBI itself should be capable of installation and execution in pure-perl
# mode. However it has never been tested yet, so consider XS for the time
# being
#
# IMPORTANT - do not raise this dependency
# even though many bugfixes are present in newer versions, the general DBIC
# rule is to bend over backwards for available DBI versions (given upgrading
# them is often *not* easy or even possible)
requires 'DBI', '1.57';

# XS (or XS-dependent) libs
requires 'Sub::Name', '0.04';

# pure-perl (FatPack-able) libs
requires 'Class::Accessor::Grouped', '0.10012';
requires 'Class::C3::Componentised', '1.0009';
requires 'Context::Preserve', '0.01';
requires 'Devel::GlobalDestruction', '0.09';
requires 'Hash::Merge', '0.12';
requires 'MRO::Compat', '0.12';
requires 'Module::Find', '0.07';
requires 'namespace::clean', '0.24';
requires 'SQL::Abstract', '2.000001';
requires 'Try::Tiny', '0.07';

on 'test' => sub {
  requires 'File::Temp', '0.22';
  requires 'Test::Deep', '0.101';
  requires 'Test::Exception', '0.31';
  requires 'Test::Warn', '0.21';
  requires 'Test::More', '0.94';

  # needed for testing only, not for operation
  # we will move away from this dep eventually, perhaps to DBD::CSV or something
  #
  # IMPORTANT - do not raise this dependency
  # even though many bugfixes are present in newer versions, the general DBIC
  # rule is to bend over backwards for available DBDs (given upgrading them is
  # often *not* easy or even possible)
  requires 'DBD::SQLite', '1.29';

  # this is already a dep of n::c, but just in case - used by t/55namespaces_cleaned.t
  # remove and do a manual glob-collection if n::c is no longer a dep
  requires 'Package::Stash', '0.28';
};

on 'develop' => sub {
  requires 'Dist::Zilla';
  requires 'Dist::Zilla::Plugin::VersionFromMainModule';
  requires 'Dist::Zilla::Plugin::GatherDir';
  requires 'Dist::Zilla::Plugin::PruneCruft';
  requires 'Dist::Zilla::Plugin::MetaJSON';
  requires 'Dist::Zilla::Plugin::MetaYAML';
  requires 'Dist::Zilla::Plugin::MetaNoIndex';
  requires 'Dist::Zilla::Plugin::MetaResources';
  requires 'Dist::Zilla::Plugin::MetaProvides::Package';
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::ExecDir';
  requires 'Dist::Zilla::Plugin::PodWeaver';
  requires 'Dist::Zilla::Plugin::ExtraTests';
  requires 'Dist::Zilla::Plugin::MakeMaker::Awesome';
  requires 'Dist::Zilla::Plugin::License';
  requires 'Dist::Zilla::Plugin::Readme';
  requires 'Dist::Zilla::Plugin::ManifestSkip';
  requires 'Dist::Zilla::Plugin::Manifest';
  requires 'Dist::Zilla::Plugin::MetaConfig';
  requires 'Dist::Zilla::Plugin::Git';
};
