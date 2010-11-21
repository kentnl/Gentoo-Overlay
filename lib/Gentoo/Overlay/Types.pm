use strict;
use warnings;

package Gentoo::Overlay::Types;
BEGIN {
  $Gentoo::Overlay::Types::VERSION = '0.01000020';
}

# ABSTRACT: Gentoo Overlay types.

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

__END__
=pod

=head1 NAME

Gentoo::Overlay::Types - Gentoo Overlay types.

=head1 VERSION

version 0.01000020

=head1 TYPES

=head2 Gentoo__Overlay_Overlay

    class_type Gentoo::Overlay

    coerces from Str

=head2 Gentoo__Overlay_Category

    class_type Gentoo::Overlay::Category

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

