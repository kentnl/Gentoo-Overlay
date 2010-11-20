use strict;
use warnings;

package Gentoo::Overlay::Walk;

# ABSTRACT: Iterate over categories/files in a Gentoo Overlay

use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Class qw( File Dir );
use MooseX::ClassAttribute;
use IO::Dir;
use Carp qw();

class_has scan_blacklist => (
  isa => HashRef [Bool],
  is => 'rw',
  lazy_build => 1,
  traits     => [qw( Hash )],
  handles    => { _blacklisted => 'exists', }
);

has 'overlay' => (
  isa      => Dir,
  is       => 'ro',
  required => 1,
  coerce   => 1,
);

has 'overlay_name' => (
  isa        => Str,
  lazy_build => 1,
  is         => 'ro',
);

has 'profile_dir' => (
  isa        => Dir,
  is         => 'ro',
  lazy_build => 1,
);

has categories => (
  isa => ArrayRef [Dir],
  is => 'ro',
  lazy_build => 1,
);

sub _build_profile_dir {
  my ($self) = shift;
  my $pd = $self->overlay->subdir('profiles');
  if ( !-d -e $pd ) {
    Carp::croak( "No profile directory '$pd' for overlay at '" . $self->overlay . "'" );
  }
  return $pd;
}

sub _build_overlay_name {
  my ($self) = shift;
  my $file = $self->profile_dir->file('repo_name');
  if ( !-f -e $file ) {
    Carp::croak( "No file 'repo_name' located at '$file', expected for '" . $self->overlay . "'" );
  }
  return scalar $file->slurp( chomp => 1, iomode => '<:raw' );
}

sub _build_scan_blacklist {
  return { map { $_ => 1 } qw( metadata profiles distfiles eclass licenses packages scripts . .. .git .svn      ) };
}

sub _build_categories {
  my ($self) = shift;
  my $file = $self->profile_dir->file('categories');
  if ( !-f -e $file ) {
    Carp::carp( "No 'categories' file for overlay '" . $self->overlay_name . "', using dir listing instead" );
    return $self->_build_categories__scan();
  }
  return $self->_build_categories__file($file);
}

sub _build_categories__file {
  my ( $self, $file ) = @_;
  my @out = ();
  foreach( $file->slurp( chomp => 1 , iomode => '<:raw' ) ){
      my $file = $self->overlay->subdir($_);
      if ( ! -e $file ){
        Carp::carp("category $_ is listed in categories file, but does not exist.");
        next;
      }
      if ( ! -d $file ){
        Carp::carp("category $_ is listed in categories file, but it is not a directory.");
        next;
      }
      push @out , $file;
  }
  return \@out;
}

sub _build_categories__scan {
  my ($self) = @_;
  my @out = ();
  tie my %dir, 'IO::Dir', $self->overlay->absolute->stringify;
  foreach ( keys %dir ) {
    next if $self->_blacklisted($_);
    next unless -d $dir{$_};
    push @out, $self->overlay->subdir($_);
  }
  return \@out;
}

1;
