use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Gentoo::Overlay;
use Test::Output qw( stderr_from );
use FindBin;

my $base = "$FindBin::Bin/../corpus";

isnt(
  exception {
    my $overlay = Gentoo::Overlay->new();
  },
  undef,
  'Objects need a path'
);

is(
  exception {
    my $overlay = Gentoo::Overlay->new( path => "$base/overlay_0" );
  },
  undef,
  "Path makes it happy"
);

like(
  exception {
    Gentoo::Overlay->new( path => "$base/overlay_0" )->_profile_dir;
  },
  qr/No profile/,
  'Need a profile dir'
);

is(
  exception {
    Gentoo::Overlay->new( path => "$base/overlay_1" )->_profile_dir;
  },
  undef,
  'Need a profile dir'
);

like(
  exception {
    Gentoo::Overlay->new( path => "$base/overlay_1" )->name;
  },
  qr/No repo_name file/,
  'Need a repo_name file'
);

is(
  exception {
    Gentoo::Overlay->new( path => "$base/overlay_2" )->name;
  },
  undef,
  'Need a repo_name file'
);

is( Gentoo::Overlay->new( path => "$base/overlay_2" )->name, 'overlay_2', '->name is right' );
my $stderr;
my %cats;
is(
  exception {
    $stderr = stderr_from {
      %cats = Gentoo::Overlay->new( path => "$base/overlay_2" )->categories;
    };
  },
  undef,
  'call to categories lives'
);
like( $stderr, qr/No category file/, 'categories without indices warn' );
is_deeply( [ sort keys %cats ], [ sort qw( fake-category) ], 'Good discovered categories' );

is(
  exception {
    $stderr = stderr_from {
      %cats = Gentoo::Overlay->new( path => "$base/overlay_3" )->categories;
    };
  },
  undef,
  'call to categories lives'
);
like( $stderr, qr/fake-category-3 is not an existing directory/, 'categories without indices warn' );
is_deeply( [ sort keys %cats ], [ sort qw( fake-category fake-category-2) ], 'Good discovered categories' );

done_testing;

