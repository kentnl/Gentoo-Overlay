use strict;
use warnings;

package Gentoo::Overlay::Types;

# ABSTRACT: Gentoo Overlay types.

use MooseX::Types -declare => [qw(
    Gentoo__Overlay_Overlay
    Gentoo__Overlay_Category
)];
use MooseX::Types::Moose qw( :all );

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

1;
