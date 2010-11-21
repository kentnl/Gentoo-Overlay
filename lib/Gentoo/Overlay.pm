use strict;
use warnings;

package Gentoo::Overlay;

# ABSTRACT: Tools for working with Gentoo Overlays

use Moose;

use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Class qw( File Dir );
use namespace::autoclean;
use IO::Dir;
use Carp qw();
use Gentoo::Overlay::Category;
use Gentoo::Overlay::Types qw( :all );

=head1 SYNOPSIS

  my $overlay = Gentoo::Overlay->new( path => '/usr/portage' );

  my $name       = $overlay->name();
  my %categories = $overlay->categories();

  print "Overlay $name 's categories:\n";
  for( sort keys %categories ){
    printf "%30s : %s", $_, $categories{$_};
  }

  # Overlay gentoo 's categories:
  #  .....
  #  dev-lang      : /usr/portage/dev-lang
  #  .....

There will be more features eventually, this is just a first release.

=cut

=attr path

Path to repository.

=cut

=attr name

Repository name.

=cut

has 'path' => ( isa => Dir, ro, required, coerce );
has 'name' => ( isa => Str, ro, lazy_build );

=p_attr _profile_dir

=cut

=p_attr _categories

=cut

=p_attr_acc _has_category

=cut

=attr_acc category_names

=cut

=attr_acc categories

=cut

=attr_acc get_category

=cut

has '_profile_dir' => ( isa => Dir, ro, lazy_build );
has(
  '_categories' => ( isa => HashRef [Gentoo__Overlay_Category], ro, lazy_build ),
  traits        => [qw( Hash )],
  handles       => {
    '_has_category'  => 'exists',
    'category_names' => 'keys',
    'categories'     => 'elements',
    'get_category'   => 'get',
  }
);

=p_attr _default_paths

=cut


has(
  '_default_paths' => ( isa => HashRef [CodeRef], ro, lazy_build ),
);

=method default_path

=cut

=p_method _build__default_paths

=cut

sub default_path {
  my ( $self, $name, @args ) = @_;
  if ( !exists $self->_default_paths->{$name} ) {
    Carp::croak("No default path '$name'");
  }
  return $self->_default_paths->{$name}->( $self, @args );
}

sub _build__default_paths {
  return {
    'profiles'  => sub { shift->path->subdir('profiles') },
    'repo_name' => sub { shift->_profile_dir->file('repo_name') },
    'catfile'   => sub { shift->_profile_dir->file('categories') },
    'category'  => sub { shift->path->subdir(shift) },
  };
}


=p_method _build__profile_dir

=cut

sub _build__profile_dir {
  my ($self) = shift;
  my $pd = $self->default_path('profiles');
  if ( ( !-e $pd ) or ( !-d $pd ) ) {
    Carp::croak( sprintf qq{No profile directory for overlay at: %s\n  Expects:%s}, $self->path->stringify, $pd->stringify, );
  }
  return $pd->absolute;
}

=p_method _build_name

=cut

sub _build_name {
  my ($self) = shift;
  my $f = $self->default_path('repo_name');
  if ( ( !-e $f ) or ( !-f $f ) ) {
    Carp::croak( sprintf qq{No repo_name file for overlay at: %s\n Expects:%s}, $self->path->stringify, $f->stringify );
  }
  return scalar $f->slurp( chomp => 1, iomode => '<:raw' );
}

=p_method _build___categories_file

=cut

sub _build___categories_file {
  my ($self) = shift;
  my %out;
  for my $cat ( $self->default_path('catfile')->slurp( chomp => 1, iomode => '<:raw' ) ) {
    my $category = Gentoo::Overlay::Category->new(
      name    => $cat,
      overlay => $self,
    );
    if ( !$category->exists ) {
      Carp::carp(
        sprintf q{category %s is not an existing directory (%s) for overlay %s},
        $category->name, $category->path->stringify,
        $self->name,
      );
      next;
    }
    $out{$cat} = $category;
  }
  return \%out;
}

=p_method _build___categories_scan

=cut

sub _build___categories_scan {
  my ($self) = shift;
  my %out;
  ## no critic ( ProhibitTies )
  tie my %dir, 'IO::Dir', $self->path->absolute->stringify;
  for my $cat ( sort keys %dir ) {
    my $category = Gentoo::Overlay::Category->new(
        overlay => $self,
        name => $cat,
    );
    next unless $category->exists();
    next if $category->is_blacklisted();
    $out{$cat} = $category;
  }
  return \%out;

}

=p_method _build__categories

=cut

sub _build__categories {
  my ($self) = shift;
  my $cf = $self->default_path('catfile');
  if ( ( !-e $cf ) or ( !-f $cf ) ) {
    Carp::carp( sprintf qq{No category file for overlay %s, expected: %s. \n Falling back to scanning},
      $self->name, $cf->stringify );
    return $self->_build___categories_scan();
  }
  return $self->_build___categories_file();
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

