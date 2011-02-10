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

    $category->pretty_name()  #  dev-perl/::gentoo

    $category->path()  # /usr/portage/dev-perl

    ::Overlay::Category->is_blacklisted('..') # is '..' a blacklisted category


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

    isa => Gentoo__Overlay_CategoryName, required, ro

L<< C<CategoryName>|Gentoo::Overlay::Types/Gentoo__Overlay_CategoryName >>

=cut

=attr overlay

The overlay it is in.

    isa => Gentoo__Overlay_Overlay, required, coerce

L<Gentoo::Overlay::Types/Gentoo__Overlay_Overlay>

=cut

=attr path

The full path to the category

    isa => Dir, lazy, ro

L<MooseX::Types::Path::Class/Dir>

=cut

has name => isa => Gentoo__Overlay_CategoryName, required, ro;
has overlay => isa => Gentoo__Overlay_Overlay, required, ro, coerce;
has path => isa => Dir,
  lazy, ro, default => sub {
  my ($self) = shift;
  return $self->overlay->default_path( category => $self->name );
  };

=p_attr _packages

    isa => HashRef[ Gentoo__Overlay_Package ], lazy_build, ro

    accessors => _has_package , package_names,
                 packages, get_package

L</_has_package>

L</package_names>

L</packages>

L</get_package>

=cut

=p_attr_acc _has_package

    $category->_has_package('Moose');

L</_packages>

=cut

=attr_acc package_names

    for( $category->package_names ){
        print $_;
    }

L</_packages>

=cut

=attr_acc packages

    my %packages = $category->packages;

L</_packages>

=cut

=attr_acc get_package

    my $package = $category->get_package('Moose');

L</_packages>

=cut

has _packages => isa => HashRef [Gentoo__Overlay_Package],
  lazy_build, ro,
  traits  => [qw( Hash )],
  handles => {
  _has_package  => exists   =>,
  package_names => keys     =>,
  packages      => elements =>,
  get_package   => get      =>,
  };

=p_method _build__packages

Generates the package Hash-Table, by scanning the category directory.

L</_packages>

=cut

sub _build__packages {
  my ($self) = shift;
  require Gentoo::Overlay::Package;

  my $dir = $self->path->open();
  my %out;
  while ( defined( my $entry = $dir->read() ) ) {
    next if Gentoo::Overlay::Package->is_blacklisted($entry);
    my $p = Gentoo::Overlay::Package->new(
      name     => $entry,
      category => $self,
    );
    next unless $p->exists;
    $out{$entry} = $p;
  }
  return \%out;
}

=pc_attr _scan_blacklist

Class-Wide list of blacklisted directory names.

    isa => HashRef[ Str ], ro, lazy

    accessors => _scan_blacklisted

L</_scan_blacklisted>

L<< C<MooseX::Types::Moose>|MooseX::Types::Moose >>

=cut

=pc_attr_acc _scan_blacklisted

is C<$arg> blacklisted in the Class Wide Blacklist?

    ::Category->_scan_blacklisted( $arg )
       ->
    exists ::Category->_scan_blacklist->{$arg}


L</_scan_blacklist>

=cut

class_has _scan_blacklist => isa => HashRef [Str],
  ro, lazy,
  traits  => [qw( Hash )],
  handles => { _scan_blacklisted => exists =>, },
  default => sub {
  return { map { $_ => 1 } qw( metadata profiles distfiles eclass licenses packages scripts . .. ) };
  };

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

Does the category name appear on a blacklist meaning auto-scan should ignore this?

    ::Category->is_blacklisted('..') # true

    ::Category->is_blacklisted('metadata') # true

=cut

sub is_blacklisted {
  my ( $self, $name ) = @_;
  if ( not defined $name ) {
    $name = $self->name;
  }
  return $self->_scan_blacklisted($name);
}

=method pretty_name

A pretty form of the name.

    $category->pretty_name  # dev-perl/::gentoo

=cut

sub pretty_name {
  my $self = shift;
  return $self->name . '/::' . $self->overlay->name;
}

=begin Pod::Coverage

iterate

=end Pod::Coverage

=cut

sub iterate {
  my ( $self, $what, $callback ) = @_;
  if ( $what eq 'packages' ) {
    my %packages     = $self->packages();
    my $num_packages = scalar keys %packages;
    my $last_package = $num_packages - 1;
    my $offset       = 0;
    for my $pname ( sort keys %packages ) {
      local $_ = $packages{$pname};
      $self->$callback(
        {
          package_name => $pname,
          package      => $packages{$pname},
          num_packages => $num_packages,
          last_package => $last_package,
          package_num  => $offset,
        }
      );
      $offset++;
    }
    return;
  }
  return exception(
    ident   => 'bad iteration method',
    message => 'The iteration method %{what_method}s is not a known way to iterate.',
    payload => { what_method => $what, },
  );
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
