use strict;
use warnings;

package Gentoo::Overlay::Package;

# ABSTRACT: Class for Package's in Gentoo Overlays
#
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Class qw( :all );
use Gentoo::Overlay::Types qw( :all  );
use namespace::autoclean;

has name => ( isa => Str, required, ro );
has
  category => ( isa => Gentoo__Overlay_Category, required, ro, ),
  ( handles => [qw( overlay )] );
has path => ( isa => Dir, lazy_build, ro );

sub _build_path {
  my ($self) = shift;
  return $self->overlay->default_path( 'package', $self->category->name, $self->name );
}

sub exists {
  my $self = shift;
  return if $self->name eq '.';
  return if $self->name eq '..';
  return if not -e $self->path;
  return if not -d $self->path;
  return 1;
}

sub pretty_name {
  my $self = shift;
  return $self->category->name . '/' . $self->name . '::' . $self->overlay->name;
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
