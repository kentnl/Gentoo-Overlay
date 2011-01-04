use strict;
use warnings;

package Gentoo::Overlay::Package;

# ABSTRACT: Class for Package's in Gentoo Overlays
#
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Class qw( :all );
use MooseX::ClassAttribute;
use Gentoo::Overlay::Types qw( :all  );
use namespace::autoclean;

=head1 SYNOPSIS

    my $package = Overlay::Package->new(
        name => 'Moose',
        category => $category_object,
    );

    $package->exists() # Moose exists

    print $package->pretty_name() # dev-perl/Moose::gentoo

    print $package->path() # /usr/portage/dev-perl/Moose

    ::Package->is_blacklisted("..") # '..' is not a valid package name
    ::Package->is_blacklisted('metadata.xml') # is not a valid directory

=cut

=attr name

The packages Short name.

    isa => Gentoo__Overlay_PackageName, required, ro

L<< C<PackageName>|Gentoo::Overlay::Types/Gentoo__Overlay_PackageName >>

=cut

=attr category

The category object that this package is in.

    isa => Gentoo__Overlay_Category, required, ro

    accessors => overlay

L<< C<Category>|Gentoo::Overlay::Types/Gentoo__Overlay_Category >>

L</overlay>

=cut

=attr_acc overlay

    $package->overlay -> Gentoo::Overlay::Category->overlay

L<Gentoo::Overlay::Category/overlay>

L</category>

=cut

=attr path

The full path to the package.

    isa => Dir, lazy, ro

L<MooseX::Types::Path::Class/Dir>

=cut

has name => isa => Gentoo__Overlay_PackageName, required, ro;
has category => isa => Gentoo__Overlay_Category, required, ro, handles => [qw( overlay )];
has path => isa => Dir,
  ro, lazy, default => sub {
  my ($self) = shift;
  return $self->overlay->default_path( 'package', $self->category->name, $self->name );
  };

=pc_attr _scan_blacklist

Class-Wide list of blacklisted package names.

    isa => HashRef[ Str ], ro, lazy,

    accessors => _scan_blacklisted

L</_scan_blacklisted>

L<< C<MooseX::Types::Moose>|MooseX::Types::Moose >>

=cut

=pc_attr_acc _scan_blacklisted

is C<$arg> blacklisted in the Class Wide Blacklist?

    ::Package->_scan_blacklisted( $arg )
       ->
    exists ::Package->_scan_blacklist->{$arg}


L</_scan_blacklist>

=cut

class_has _scan_blacklist => isa => HashRef [Str],
  ro, lazy,
  traits  => [qw( Hash )],
  handles => { _scan_blacklisted => exists =>, },
  default => sub {
  return { map { $_ => 1 } qw( . .. metadata.xml ) };
  };

=method exists

Does the Package exist, and is it a directory?


    $package->exists();

=cut

## no critic ( ProhibitBuiltinHomonyms )
sub exists {
  my $self = shift;
  return if $self->name eq q{.};
  return if $self->name eq q{..};
  return if not -e $self->path;
  return if not -d $self->path;
  return 1;
}

=method is_blacklisted

Does the package name appear on a blacklist meaning auto-scan should ignore this?

    ::Package->is_blacklisted('..') # true

=cut

sub is_blacklisted {
  my ( $self, $name ) = @_;
  if ( not defined $name ) {
    $name = $self->name;
  }
  return $self->_scan_blacklisted($name);
}

=method pretty_name

A pretty form of the name

    $package->pretty_name # dev-perl/Moose::gentoo

=cut

sub pretty_name {
  my $self = shift;
  return $self->category->name . q{/} . $self->name . q{::} . $self->overlay->name;
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
