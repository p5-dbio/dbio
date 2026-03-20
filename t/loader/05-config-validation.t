use strict;
use warnings;
use Test::More;
use Test::Exception;

eval { require DBIO::Loader::Base }
    or plan skip_all => 'DBIO::Loader::Base required';

# --- Legacy option rejection ---

throws_ok {
    DBIO::Loader::Base->new(use_moose => 1);
} qr/use_moose is no longer supported/,
    'use_moose is rejected';

throws_ok {
    DBIO::Loader::Base->new(only_autoclean => 1);
} qr/only_autoclean is no longer supported/,
    'only_autoclean is rejected';

throws_ok {
    DBIO::Loader::Base->new(result_roles => ['Some::Role']);
} qr/result_roles.*is no longer supported/,
    'result_roles is rejected';

throws_ok {
    DBIO::Loader::Base->new(result_roles_map => { Foo => ['Role'] });
} qr/result_roles_map.*is no longer supported/,
    'result_roles_map is rejected';

# --- loader_style validation ---

# Valid styles should not croak (they'll fail later for other reasons
# but the style itself is accepted)
for my $style (qw(vanilla cake candy)) {
    lives_ok {
        my $obj = bless { loader_style => $style }, 'DBIO::Loader::Base';
        is $obj->loader_style, $style, "loader_style=$style accepted";
    } "loader_style=$style does not croak";
}

done_testing;
