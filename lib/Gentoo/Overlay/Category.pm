use strict;
use warnings;

package Gentoo::Overlay::Category;

# ABSTRACT: A singular category in a repository;

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


=cut

use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Class qw( File Dir );
use MooseX::ClassAttribute;
use Gentoo::Overlay::Types qw( :all );
use namespace::autoclean;

=attr name

The classes short name

    isa => Str, required, ro

L<MooseX::Types::Moose>

=cut

=attr overlay

The overlay it is in.

    isa => Gentoo__Overlay_Overlay, required, coerce

L<Gentoo::Overlay::Types/Gentoo__Overlay_Overlay>

=cut

=attr path

The full path to the category

    isa => Dir, lazy_build, ro

L<MooseX::Types::Path::Class/Dir>

=cut

has name    => ( isa => Str,                     required,   ro );
has overlay => ( isa => Gentoo__Overlay_Overlay, required,   ro, coerce );
has path    => ( isa => Dir,                     lazy_build, ro );

=pc_attr _scan_blacklist

Class-Wide list of blacklisted directory names.

    isa => HashRef[ Str ], ro, lazy_build,

    accessors => _scan_blacklisted

L</_scan_blacklisted>

L<MooseX::Types::Moose>

=cut

=pc_attr_acc _scan_blacklisted

is C<$arg> blacklisted in the Class Wide Blacklist?

    ::Category->_scan_blacklisted( $arg )
       ->
    exists ::Category->_scan_blacklist->{$arg}


L</_scan_blacklist>

=cut

class_has(
  '_scan_blacklist' => ( isa => HashRef [Str], ro, lazy_build, ),
  traits => [qw( Hash )],
  handles => { '_scan_blacklisted' => 'exists' },
);

=pc_method _build__scan_blacklist

Generates the default list of blacklisted items for the classwide record.

    ::Category->_build__scan_blacklist()

=cut

sub _build__scan_blacklist {
  my ($self) = shift;
  return { map { $_ => 1 } qw( metadata profiles distfiles eclass licenses packages scripts . .. ) };
}

=p_method _build_path

Generates the path by asking the overlay what the path should be for the category.

    $category->_build_path();
      ->
    $overlay->default_path('category', $category->name );

=cut

sub _build_path {
  my ($self) = shift;
  return $self->overlay->default_path( 'category', $self->name );
}

=method exists

Does the category exist, and is it a directory?

    $category->exists();

=cut

## no critic ( ProhibitBuiltinHomonyms )
sub exists {
  my $self = shift;
  return if not -e $self->path;
  return if not -d $self->path;
  return 1;
}

=method is_blacklisted

Does the category name appear on a blacklist meaning autoscan should ignore this?

    ::Category->new( name => '..', overlay => $overlay )->is_blacklisted  # true

=cut

sub is_blacklisted {
  my $self = shift;
  return $self->_scan_blacklisted( $self->name );
}

=method pretty_name

A pretty form of the name.

    $category->pretty_name  # dev-perl/::gentoo

=cut

sub pretty_name {
  my $self = shift;
  return $self->name . '/::' . $self->overlay->name;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
