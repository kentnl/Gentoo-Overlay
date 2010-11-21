use strict;
use warnings;

package Gentoo::Overlay::Types;

use MooseX::Types -declare => [qw(
    Gentoo__Overlay_Overlay
    Gentoo__Overlay_Category
)];
use MooseX::Types::Moose qw( :all );


class_type Gentoo__Overlay_Overlay, { class => 'Gentoo::Overlay' };
coerce Gentoo__Overlay_Overlay, from Str, via {
    require Gentoo::Overlay;
    return Gentoo::Overlay->new( path => $_ );
};

class_type Gentoo__Overlay_Category, { class => 'Gentoo::Overlay::Category' };

1;
