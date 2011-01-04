use strict;
use warnings;

package Gentoo::Overlay::Category;
BEGIN {
  $Gentoo::Overlay::Category::VERSION = '0.02004319';
}

# ABSTRACT: A singular category in a repository;


use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Class qw( File Dir );
use MooseX::ClassAttribute;
use Gentoo::Overlay::Types qw( :all );
use IO::Dir;
use namespace::autoclean;




has name => isa => Gentoo__Overlay_CategoryName, required, ro;
has overlay => isa => Gentoo__Overlay_Overlay, required, ro, coerce;
has path => isa => Dir,
  lazy, ro, default => sub {
  my ($self) = shift;
  return $self->overlay->default_path( category => $self->name );
  };






has _packages => isa => HashRef [Gentoo__Overlay_Package],
  lazy_build, ro,
  traits  => [qw( Hash )],
  handles => {
  _has_package  => exists   =>,
  package_names => keys     =>,
  packages      => elements =>,
  get_package   => get      =>,
  };

sub _build__packages {
  my ($self) = shift;
  require Gentoo::Overlay::Package;
  ## no critic ( ProhibitTies )
  tie my %dir, 'IO::Dir', $self->path->stringify;
  my %out;
  for ( sort keys %dir ) {
    next if Gentoo::Overlay::Package->is_blacklisted($_);
    my $p = Gentoo::Overlay::Package->new(
      name     => $_,
      category => $self,
    );
    next unless $p->exists;
    $out{$_} = $p;
  }
  return \%out;
}



class_has _scan_blacklist => isa => HashRef [Str],
  ro, lazy,
  traits  => [qw( Hash )],
  handles => { _scan_blacklisted => exists =>, },
  default => sub {
  return { map { $_ => 1 } qw( metadata profiles distfiles eclass licenses packages scripts . .. ) };
  };


## no critic ( ProhibitBuiltinHomonyms )
sub exists {
  my $self = shift;
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

version 0.02004319

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

    $category->pretty_name()  #  dev-perl/::gentoo

    $category->path()  # /usr/portage/dev-perl

    ::Overlay::Category->is_blacklisted('..') # is '..' a blacklisted category

=head1 METHODS

=head2 exists

Does the category exist, and is it a directory?

    $category->exists();

=head2 is_blacklisted

Does the category name appear on a blacklist meaning auto-scan should ignore this?

    ::Category->is_blacklisted('..') # true

    ::Category->is_blacklisted('metadata') # true

=head2 pretty_name

A pretty form of the name.

    $category->pretty_name  # dev-perl/::gentoo

=head1 ATTRIBUTES

=head2 name

The classes short name

    isa => Gentoo__Overlay_CategoryName, required, ro

L<< C<CategoryName>|Gentoo::Overlay::Types/Gentoo__Overlay_CategoryName >>

=head2 overlay

The overlay it is in.

    isa => Gentoo__Overlay_Overlay, required, coerce

L<Gentoo::Overlay::Types/Gentoo__Overlay_Overlay>

=head2 path

The full path to the category

    isa => Dir, lazy, ro

L<MooseX::Types::Path::Class/Dir>

=head1 ATTRIBUTE ACCESSORS

=head2 package_names

    for( $category->package_names ){
        print $_;
    }

L</_packages>

=head2 packages

    my %packages = $category->packages;

L</_packages>

=head2 get_package

    my $package = $category->get_package('Moose');

L</_packages>

=head1 PRIVATE ATTRIBUTES

=head2 _packages

    isa => HashRef[ Gentoo__Overlay_Package ], lazy_build, ro

    accessors => _has_package , package_names,
                 packages, get_package

L</_has_package>

L</package_names>

L</packages>

L</get_package>

=head1 PRIVATE ATTRIBUTE ACCESSORS

=head2 _has_package

    $category->_has_package('Moose');

L</_packages>

=head1 PRIVATE CLASS ATTRIBUTES

=head2 _scan_blacklist

Class-Wide list of blacklisted directory names.

    isa => HashRef[ Str ], ro, lazy

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

=head2 _build__packages

Generates the package Hash-Table, by scanning the category directory.

L</_packages>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

