use 5.006;
use strict;
use warnings;

package Gentoo::Overlay::Ebuild;

our $VERSION = '2.000000';

# ABSTRACT: A Class for Ebuilds in Gentoo Overlays

# AUTHORITY

use Moose qw( has );
use MooseX::Has::Sugar qw( required ro lazy );
use MooseX::Types::Moose qw( HashRef Str );
use MooseX::Types::Path::Tiny qw( File Dir );
use MooseX::ClassAttribute qw( class_has );
use Gentoo::Overlay::Types qw( Gentoo__Overlay_EbuildName Gentoo__Overlay_Package );
use namespace::autoclean;

=head1 SYNOPSIS

  my $ebuild = Overlay::Ebuild->new(
    name => 'Moose-2.0.0.ebuild',
    package => $package_object,
  );

  $ebuild->exists();  #  Ebuild listed exists.

  print $ebuild->pretty_name # =dev-perl/Moose-2.0.0::gentoo

  print $ebuild->path # /usr/portage/dev-perl/Moose/Moose-2.0.0.ebuild

=attr name

The Ebuilds short name

  isa => Gentoo__Overlay_EbuildName, required, ro

L<< C<EbuildName>|Gentoo::Overlay::Types/Gentoo__Overlay_EbuildName >>

=cut

=attr package

The package object this ebuild is within.

  isa => Gentoo__Overlay_EbuildName, required, ro

  accessors => overlay category

L<< C<Package>|Gentoo::Overlay::Types/Gentoo__Overlay_Package >>

L</overlay>

L</category>

=cut

=attr_acc overlay

  $ebuild->overlay -> Gentoo::Overlay::Package->overlay

L<Gentoo::Overlay::Package/overlay>

L</package>

=cut

=attr_acc overlay

  $ebuild->category -> Gentoo::Overlay::Package->category

L<Gentoo::Overlay::Package/category>

L</package>

=cut

=attr path

The full path to the ebuild.

    isa => File, lazy, ro

L<MooseX::Types::Path::Tiny/File>

=cut

has name => ( isa => Gentoo__Overlay_EbuildName, required, ro );
has package => (
  isa => Gentoo__Overlay_Package,
  required, ro,
  handles => [qw( overlay category )],
);

has path => (
  isa => File,
  ro,
  lazy,
  default => sub {
    my ($self) = shift;
    return $self->overlay->default_path( 'ebuild', $self->category->name, $self->package->name, $self->name );
  },
);

=pc_attr _scan_blacklist

Class-Wide list of blacklisted ebuild names.

    isa => HashRef[ Str ], ro, lazy,

    accessors => _scan_blacklisted

L</_scan_blacklisted>

L<< C<MooseX::Types::Moose>|MooseX::Types::Moose >>

=cut

=pc_attr_acc _scan_blacklisted

is C<$arg> blacklisted in the Class Wide Blacklist?

    ::Ebuild->_scan_blacklisted( $arg )
       ->
    exists ::Ebuild->_scan_blacklist->{$arg}


L</_scan_blacklist>

=cut

class_has _scan_blacklist => (
  isa => HashRef [Str],
  ro,
  lazy,
  traits  => [qw( Hash )],
  handles => { _scan_blacklisted => exists =>, },
  default => sub {
    return { map { $_ => 1 } qw( . .. ChangeLog Manifest metadata.xml ) };
  },
);

=method exists

Does the Ebuild exist, and is it a file?


    $ebuild->exists();

=cut

## no critic ( ProhibitBuiltinHomonyms )
sub exists {
  my $self = shift;
  return if q{.} eq $self->name;
  return if q{..} eq $self->name;
  return unless $self->path->exists;
  return if $self->path->is_dir;
  return 1;
}

=method is_blacklisted

Does the ebuild name appear on a blacklist meaning auto-scan should ignore this?

    ::Ebuild->is_blacklisted('..') # true

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

    $ebuild->pretty_name # =dev-perl/Moose-2.0.0::gentoo

=cut

sub pretty_name {
  my $self     = shift;
  my $filename = $self->name;
  ## no critic (RegularExpressions)
  $filename =~ s/\.ebuild$//;
  return q{=} . $self->category->name . q{/} . $filename . q{::} . $self->overlay->name;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

