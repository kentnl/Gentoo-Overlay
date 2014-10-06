use 5.006;
use strict;
use warnings;

package Gentoo::Overlay::Types;

our $VERSION = '2.000000';

# ABSTRACT: Gentoo Overlay types.

# AUTHORITY

use MooseX::Types qw( class_type coerce from via as where subtype );
use MooseX::Types -declare => [
  qw(
    Gentoo__Overlay_Overlay
    Gentoo__Overlay_Category
    Gentoo__Overlay_Ebuild
    Gentoo__Overlay_Package
    Gentoo__Overlay_CategoryName
    Gentoo__Overlay_EbuildName
    Gentoo__Overlay_PackageName
    Gentoo__Overlay_RepositoryName
    )
];
use MooseX::Types::Moose qw( Str  );

=type Gentoo__Overlay_Overlay

    class_type Gentoo::Overlay

    coerces from Str

=cut

class_type Gentoo__Overlay_Overlay, { class => 'Gentoo::Overlay' };
coerce Gentoo__Overlay_Overlay, from Str, via {
  require Gentoo::Overlay;
  return Gentoo::Overlay->new( path => $_ );
};

=type Gentoo__Overlay_Category

    class_type Gentoo::Overlay::Category

=cut

class_type Gentoo__Overlay_Category, { class => 'Gentoo::Overlay::Category' };

=type Gentoo__Overlay_Ebuild

    class_type Gentoo::Overlay::Ebuild

=cut

class_type Gentoo__Overlay_Ebuild, { class => 'Gentoo::Overlay::Ebuild' };

=type Gentoo__Overlay_Package

    class_type Gentoo::Overlay::Package

=cut

class_type Gentoo__Overlay_Package, { class => 'Gentoo::Overlay::Package' };

=type Gentoo__Overlay_CategoryName

    Str matching         ^[A-Za-z0-9+_.-]+$
        and not matching ^[-.]

I<A category name may contain any of the characters [A-Za-z0-9+_.-]. It must not begin with a hyphen or a dot.>

=cut

subtype Gentoo__Overlay_CategoryName, as Str, where {
## no critic ( RegularExpressions )
  $_ =~ qr/^[a-zA-Z0-9+_.-]+$/
    && $_ !~ qr/^[-.]/;
};

=type Gentoo__Overlay_EbuildName

    Str matching ^[A-Za-z0-9+_.-]+$
        and not matching ^-
        and not matching -$
        and matching \.ebuild$

I<An ebuild name may contain any of the characters [A-Za-z0-9+_.-]. It must not begin with a hyphen, and must not end in a hyphen.>

=cut

subtype Gentoo__Overlay_EbuildName, as Str, where {
  ## no critic ( RegularExpressions )
       $_ =~ qr/^[A-Za-z0-9+_.-]+$/
    && $_ !~ qr/^-/
    && $_ !~ qr/-$/
    && $_ =~ qr/\.ebuild$/;
};

=type Gentoo__Overlay_PackageName

    Str matching ^[A-Za-z0-9+_-]+$
        and not matching ^-
        and not matching -$
        and not matching -\d+$

I<A package name may contain any of the characters [A-Za-z0-9+_-]. It must not begin with a hyphen, and must not end in a hyphen followed by one or more digits.>

=cut

subtype Gentoo__Overlay_PackageName, as Str, where {
  ## no critic ( RegularExpressions )
       $_ =~ qr/^[A-Za-z0-9+_-]+$/
    && $_ !~ qr/^-/
    && $_ !~ qr/-$/
    && $_ !~ qr/-\d+$/;
};

=type Gentoo__Overlay_RepositoryName

    Str matching ^[A-Za-z0-9_-]+$
        and not matching ^-

I<A repository name may contain any of the characters [A-Za-z0-9_-]. It must not begin with a hyphen.>

=cut

subtype Gentoo__Overlay_RepositoryName, as Str, where {
## no critic ( RegularExpressions )

  $_ =~ qr/^[A-Za-z0-9_-]+$/
    && $_ !~ qr/^-/;
};

1;
