use strict;
use warnings;

package Gentoo::Overlay::Ebuild;

BEGIN {
  $Gentoo::Overlay::Ebuild::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Overlay::Ebuild::VERSION = '1.0.1';
}

# FILENAME: Ebuild.pm
# CREATED: 02/08/11 18:38:11 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: A Class for Ebuilds in Gentoo Overlays

use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Class qw( File Dir );
use MooseX::ClassAttribute;
use Gentoo::Overlay::Types qw( :all );
use namespace::autoclean;

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

## no critic ( ProhibitBuiltinHomonyms )
sub exists {
  my $self = shift;
  return if $self->name eq q{.};
  return if $self->name eq q{..};
  return if not -e $self->path;
  return if not -f $self->path;
  return 1;
}

sub is_blacklisted {
  my ( $self, $name ) = @_;
  if ( not defined $name ) {
    $name = $self->name;
  }
  return $self->_scan_blacklisted($name);
}

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

__END__

=pod

=head1 NAME

Gentoo::Overlay::Ebuild - A Class for Ebuilds in Gentoo Overlays

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

  my $ebuild = Overlay::Ebuild->new(
    name => 'Moose-2.0.0.ebuild',
    package => $package_object,
  );

  $ebuild->exists();  #  Ebuild listed exists.

  print $ebuild->pretty_name # =dev-perl/Moose-2.0.0::gentoo

  print $ebuild->path # /usr/portage/dev-perl/Moose/Moose-2.0.0.ebuild

=head1 METHODS

=head2 exists

Does the Ebuild exist, and is it a file?

    $ebuild->exists();

=head2 is_blacklisted

Does the ebuild name appear on a blacklist meaning auto-scan should ignore this?

    ::Ebuild->is_blacklisted('..') # true

=head2 pretty_name

A pretty form of the name

    $ebuild->pretty_name # =dev-perl/Moose-2.0.0::gentoo

=head1 ATTRIBUTES

=head2 name

The Ebuilds short name

  isa => Gentoo__Overlay_EbuildName, required, ro

L<< C<EbuildName>|Gentoo::Overlay::Types/Gentoo__Overlay_EbuildName >>

=head2 package

The package object this ebuild is within.

  isa => Gentoo__Overlay_EbuildName, required, ro

  accessors => overlay category

L<< C<Package>|Gentoo::Overlay::Types/Gentoo__Overlay_Package >>

L</overlay>

L</category>

=head2 path

The full path to the ebuild.

    isa => File, lazy, ro

L<MooseX::Types::Path::Class/File>

=head1 ATTRIBUTE ACCESSORS

=head2 overlay

  $ebuild->overlay -> Gentoo::Overlay::Package->overlay

L<Gentoo::Overlay::Package/overlay>

L</package>

=head2 overlay

  $ebuild->category -> Gentoo::Overlay::Package->category

L<Gentoo::Overlay::Package/category>

L</package>

=head1 PRIVATE CLASS ATTRIBUTES

=head2 _scan_blacklist

Class-Wide list of blacklisted ebuild names.

    isa => HashRef[ Str ], ro, lazy,

    accessors => _scan_blacklisted

L</_scan_blacklisted>

L<< C<MooseX::Types::Moose>|MooseX::Types::Moose >>

=head1 PRIVATE CLASS ATTRIBUTE ACCESSORS

=head2 _scan_blacklisted

is C<$arg> blacklisted in the Class Wide Blacklist?

    ::Ebuild->_scan_blacklisted( $arg )
       ->
    exists ::Ebuild->_scan_blacklist->{$arg}

L</_scan_blacklist>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
