use strict;
use warnings;

package Gentoo::Overlay;
BEGIN {
  $Gentoo::Overlay::VERSION = '0.01000015';
}

# ABSTRACT: Tools for working with Gentoo Overlays

use Moose;

use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Class qw( File Dir );
use MooseX::ClassAttribute;
use namespace::autoclean;
use IO::Dir;
use Carp qw();




has 'path' => ( isa => Dir, ro, required, coerce );
has 'name' => ( isa => Str, ro, lazy_build );



has '_profile_dir' => ( isa => Dir, ro, lazy_build );
has(
  '_categories' => ( isa => HashRef [Dir], ro, lazy_build ),
  traits        => [qw( Hash )],
  handles       => {
    '_has_category'  => 'exists',
    'category_names' => 'keys',
    'categories'     => 'elements',
    'get_category'   => 'get',
  }
);



class_has(
  '_default_paths' => ( isa => HashRef [CodeRef], ro, lazy_build ),
  traits => [qw( Hash )],
);

class_has(
  '_category_scan_blacklist' => ( isa => HashRef [Str], ro, lazy_build, ),
  traits => [qw( Hash )],
  handles => { '_category_scan_blacklisted' => 'exists' },
);



sub _default_path {
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


sub _build__category_scan_blacklist {
  my ($self) = shift;
  return { map { $_ => 1 } qw( metadata profiles distfiles eclass licenses packages scripts . .. ) };
}


sub _build__profile_dir {
  my ($self) = shift;
  my $pd = $self->_default_path('profiles');
  if ( ( !-e $pd ) or ( !-d $pd ) ) {
    Carp::croak( sprintf qq{No profile directory for overlay at: %s\n  Expects:%s}, $self->path->stringify, $pd->stringify, );
  }
  return $pd->absolute;
}


sub _build_name {
  my ($self) = shift;
  my $f = $self->_default_path('repo_name');
  if ( ( !-e $f ) or ( !-f $f ) ) {
    Carp::croak( sprintf qq{No repo_name file for overlay at: %s\n Expects:%s}, $self->path->stringify, $f->stringify );
  }
  return scalar $f->slurp( chomp => 1, iomode => '<:raw' );
}


sub _build___categories_file {
  my ($self) = shift;
  my %out;
  for my $cat ( $self->_default_path('catfile')->slurp( chomp => 1, iomode => '<:raw' ) ) {
    my $file = $self->_default_path( 'category', $cat );
    if ( ( !-e $file ) or ( !-d $file ) ) {
      Carp::carp( sprintf q{category %s is not an existing directory (%s) for overlay %s}, $cat, $file->stringify, $self->name,
      );
      next;
    }
    $out{$cat} = $file;
  }
  return \%out;
}


sub _build___categories_scan {
  my ($self) = shift;
  my %out;
  ## no critic ( ProhibitTies )
  tie my %dir, 'IO::Dir', $self->path->absolute->stringify;
  for my $cat ( sort keys %dir ) {
    next if $self->_category_scan_blacklisted($cat);
    next unless -d $dir{$cat};
    $out{$cat} = $self->_default_path( 'category', $cat );
  }
  return \%out;

}


sub _build__categories {
  my ($self) = shift;
  my $cf = $self->_default_path('catfile');
  if (( !-e $cf ) or ( !-f $cf ) ) {
    Carp::carp( sprintf qq{No category file for overlay %s, expected: %s. \n Falling back to scanning},
      $self->name, $cf->stringify );
    return $self->_build___categories_scan();
  }
  return $self->_build___categories_file();
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=head1 NAME

Gentoo::Overlay - Tools for working with Gentoo Overlays

=head1 VERSION

version 0.01000015

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

=head1 ATTRIBUTES

=head2 path

Path to repository.

=head2 name

Repository name.

=head1 PRIVATE ATTRIBUTES

=head2 _profile_dir

=head2 _categories

=head1 PRIVATE CLASS ATTRIBUTES

=head2 _default_paths

=head2 _category_scan_blacklist

=head1 PRIVATE METHODS

=head2 _default_path

=head2 _build__profile_dir

=head2 _build_name

=head2 _build___categories_file

=head2 _build___categories_scan

=head2 _build__categories

=head1 PRIVATE CLASS METHODS

=head2 _build__default_paths

=head2 _build__category_scan_blacklist

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

