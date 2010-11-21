use strict;
use warnings;

package Gentoo::Overlay::Category;
BEGIN {
  $Gentoo::Overlay::Category::VERSION = '0.01000020';
}

# ABSTRACT: A singular category in a repository;


use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Class qw( File Dir );
use MooseX::ClassAttribute;
use Gentoo::Overlay::Types qw( :all );
use namespace::autoclean;




has name    => ( isa => Str,                     required,   ro );
has overlay => ( isa => Gentoo__Overlay_Overlay, required,   ro, coerce );
has path    => ( isa => Dir,                     lazy_build, ro );



class_has(
  '_scan_blacklist' => ( isa => HashRef [Str], ro, lazy_build, ),
  traits => [qw( Hash )],
  handles => { '_scan_blacklisted' => 'exists' },
);


sub _build__scan_blacklist {
  my ($self) = shift;
  return { map { $_ => 1 } qw( metadata profiles distfiles eclass licenses packages scripts . .. ) };
}


sub _build_path {
  my ($self) = shift;
  return $self->overlay->default_path( 'category', $self->name );
}


## no critic ( ProhibitBuiltinHomonyms )
sub exists {
  my $self = shift;
  return if not -e $self->path;
  return if not -d $self->path;
  return 1;
}


sub is_blacklisted {
  my $self = shift;
  return $self->_scan_blacklisted( $self->name );
}


sub pretty_name {
  my $self = shift;
  return $self->name . '/::' . $self->overlay->name;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Gentoo::Overlay::Category - A singular category in a repository;

=head1 VERSION

version 0.01000020

=head1 SYNOPSIS

Still limited functionality, more to come.

    my $category = ::Overlay::Category->new(
        name => 'dev-perl',
        overlay => '/usr/portage' ,
    );

    my $category = ::Overlay::Category->new(
        name => 'dev-perl',
        overlay => $overlay_object ,
    );

    $category->exists()  # is the category there, is it a directory?

    $category->is_backlisted() # is the category something dumb like '..' or 'metadata'

    $category->pretty_name()  #  dev-perl/::gentoo

    $category->path()  # /usr/portage/dev-perl

    ::Overlay::Category->_scan_blacklist() # the blacklist

    ::Overlay::Category->_scan_blacklisted('..') # is '..' a blacklisted category

=head1 METHODS

=head2 exists

Does the category exist, and is it a directory?

    $category->exists();

=head2 is_blacklisted

Does the category name appear on a blacklist meaning auto-scan should ignore this?

    ::Category->new( name => '..', overlay => $overlay )->is_blacklisted  # true

=head2 pretty_name

A pretty form of the name.

    $category->pretty_name  # dev-perl/::gentoo

=head1 ATTRIBUTES

=head2 name

The classes short name

    isa => Str, required, ro

L<< C<MooseX::Types::Moose>|MooseX::Types::Moose >>

=head2 overlay

The overlay it is in.

    isa => Gentoo__Overlay_Overlay, required, coerce

L<Gentoo::Overlay::Types/Gentoo__Overlay_Overlay>

=head2 path

The full path to the category

    isa => Dir, lazy_build, ro

L<MooseX::Types::Path::Class/Dir>

=head1 PRIVATE CLASS ATTRIBUTES

=head2 _scan_blacklist

Class-Wide list of blacklisted directory names.

    isa => HashRef[ Str ], ro, lazy_build,

    accessors => _scan_blacklisted

L</_scan_blacklisted>

L<< C<MooseX::Types::Moose>|MooseX::Types::Moose >>

=head1 PRIVATE CLASS ATTRIBUTE ACCESSORS

=head2 _scan_blacklisted

is C<$arg> blacklisted in the Class Wide Blacklist?

    ::Category->_scan_blacklisted( $arg )
       ->
    exists ::Category->_scan_blacklist->{$arg}

L</_scan_blacklist>

=head1 PRIVATE METHODS

=head2 _build_path

Generates the path by asking the overlay what the path should be for the category.

    $category->_build_path();
      ->
    $overlay->default_path('category', $category->name );

=head1 PRIVATE CLASS METHODS

=head2 _build__scan_blacklist

Generates the default list of blacklisted items for the class-wide record.

    ::Category->_build__scan_blacklist()

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

