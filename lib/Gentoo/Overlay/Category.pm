use strict;
use warnings;

package Gentoo::Overlay::Category;

# ABSTRACT: A singluar category in a repository;

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
  return $self->overlay->_default_path( 'category', $self->name );
}

sub exists {
  my $self = shift;
  return if not -e $self->path;
  return if not -d $self->path;
  return 1;
}

sub is_blacklisted {
    my $self =shift;
    return $self->_scan_blacklisted( $self->name );
}

sub pretty_name {
    my $self = shift;
    return $self->name . '/::' . $self->overlay->name;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
