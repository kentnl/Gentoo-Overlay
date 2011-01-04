use strict;
use warnings;

package Gentoo::Overlay::Package;
BEGIN {
  $Gentoo::Overlay::Package::VERSION = '0.02004319';
}

# ABSTRACT: Class for Package's in Gentoo Overlays
#
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Class qw( :all );
use MooseX::ClassAttribute;
use Gentoo::Overlay::Types qw( :all  );
use namespace::autoclean;






has name => isa => Gentoo__Overlay_PackageName, required, ro;
has category => isa => Gentoo__Overlay_Category, required, ro, handles => [qw( overlay )];
has path => isa => Dir,
  ro, lazy, default => sub {
  my ($self) = shift;
  return $self->overlay->default_path( 'package', $self->category->name, $self->name );
  };



class_has _scan_blacklist => isa => HashRef [Str],
  ro, lazy,
  traits  => [qw( Hash )],
  handles => { _scan_blacklisted => exists =>, },
  default => sub {
  return { map { $_ => 1 } qw( . .. metadata.xml ) };
  };


## no critic ( ProhibitBuiltinHomonyms )
sub exists {
  my $self = shift;
  return if $self->name eq q{.};
  return if $self->name eq q{..};
  return if not -e $self->path;
  return if not -d $self->path;
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
  my $self = shift;
  return $self->category->name . q{/} . $self->name . q{::} . $self->overlay->name;
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Gentoo::Overlay::Package - Class for Package's in Gentoo Overlays

=head1 VERSION

version 0.02004319

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

=head1 METHODS

=head2 exists

Does the Package exist, and is it a directory?

    $package->exists();

=head2 is_blacklisted

Does the package name appear on a blacklist meaning auto-scan should ignore this?

    ::Package->is_blacklisted('..') # true

=head2 pretty_name

A pretty form of the name

    $package->pretty_name # dev-perl/Moose::gentoo

=head1 ATTRIBUTES

=head2 name

The packages Short name.

    isa => Gentoo__Overlay_PackageName, required, ro

L<< C<PackageName>|Gentoo::Overlay::Types/Gentoo__Overlay_PackageName >>

=head2 category

The category object that this package is in.

    isa => Gentoo__Overlay_Category, required, ro

    accessors => overlay

L<< C<Category>|Gentoo::Overlay::Types/Gentoo__Overlay_Category >>

L</overlay>

=head2 path

The full path to the package.

    isa => Dir, lazy, ro

L<MooseX::Types::Path::Class/Dir>

=head1 ATTRIBUTE ACCESSORS

=head2 overlay

    $package->overlay -> Gentoo::Overlay::Category->overlay

L<Gentoo::Overlay::Category/overlay>

L</category>

=head1 PRIVATE CLASS ATTRIBUTES

=head2 _scan_blacklist

Class-Wide list of blacklisted package names.

    isa => HashRef[ Str ], ro, lazy,

    accessors => _scan_blacklisted

L</_scan_blacklisted>

L<< C<MooseX::Types::Moose>|MooseX::Types::Moose >>

=head1 PRIVATE CLASS ATTRIBUTE ACCESSORS

=head2 _scan_blacklisted

is C<$arg> blacklisted in the Class Wide Blacklist?

    ::Package->_scan_blacklisted( $arg )
       ->
    exists ::Package->_scan_blacklist->{$arg}

L</_scan_blacklist>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

