use strict;
use warnings;

package Gentoo::Overlay::Package;

# ABSTRACT: Class for Package's in Gentoo Overlays
#
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Tiny qw( :all );
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

L<MooseX::Types::Path::Tiny/Dir>

=cut

has name => ( isa => Gentoo__Overlay_PackageName, required, ro, );
has category => ( isa => Gentoo__Overlay_Category, required, ro, handles => [qw( overlay )], );
has path => (
  isa => Path,
  ro,
  lazy,
  default => sub {
    my ($self) = shift;
    return $self->overlay->default_path( 'package', $self->category->name, $self->name );
  },
);

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

class_has _scan_blacklist => (
  isa => HashRef [Str],
  ro,
  lazy,
  traits  => [qw( Hash )],
  handles => { _scan_blacklisted => exists =>, },
  default => sub {
    return { map { $_ => 1 } qw( . .. metadata.xml ) };
  },
);

=p_attr _ebuilds

    isa => HashRef[ Gentoo__Overlay_Ebuild ], lazy_build, ro

    accessors => _has_ebuild , ebuild_names,
                 ebuilds, get_ebuild

L</_has_ebuild>

L</ebuild_names>

L</ebuilds>

L</get_ebuild>

=cut

=p_attr_acc _has_ebuild

    $package->_has_ebuild('Moose-2.0.0.ebuild');

L</_ebuilds>

=cut

=attr_acc ebuild_names

    for( $package->ebuild_names ){
        print $_;
    }

L</_ebuilds>

=cut

=attr_acc ebuilds

    my %ebuilds = $package->ebuilds;

L</_ebuilds>

=cut

=attr_acc get_ebuild

    my $ebuild = $package->get_ebuild('Moose-2.0.0.ebuild');

L</_ebuilds>

=cut

has _ebuilds => (
  isa => HashRef [Gentoo__Overlay_Ebuild],
  lazy_build,
  ro,
  traits  => [qw( Hash )],
  handles => {
    _has_ebuild  => exists   =>,
    ebuild_names => keys     =>,
    ebuilds      => elements =>,
    get_ebuild   => get      =>,
  },
);

=p_method _build__ebuilds

Generates the ebuild Hash-Table, by scanning the package directory.

L</_packages>

=cut

sub _build__ebuilds {
  my ($self) = shift;
  require Gentoo::Overlay::Ebuild;
  my $dir = $self->path->open();
  my %out;
  while ( defined( my $entry = $dir->read() ) ) {
    next if Gentoo::Overlay::Ebuild->is_blacklisted($entry);
    next if -d $entry;
    ## no critic ( RegularExpressions )
    next if $entry !~ /\.ebuild$/;
    my $e = Gentoo::Overlay::Ebuild->new(
      name    => $entry,
      package => $self,
    );
    next unless $e->exists;
    $out{$entry} = $e;
  }
  return \%out;
}

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

=method iterate

  $overlay->iterate( $what, sub {
      my ( $context_information ) = shift;

  } );

The iterate method provides a handy way to do walking across the whole tree stopping at each of a given type.

=over 4

=item * C<$what = 'ebuilds'>

  $overlay->iterate( ebuilds => sub {
      my ( $self, $c ) = shift;
      # $c->{ebuild_name}  # String
      # $c->{ebuild}       # Ebuild Object
      # $c->{num_ebuilds}  # How many ebuild are there to iterate
      # $c->{last_ebuild}  # Index ID of the last ebuild.
      # $c->{ebuild_num}   # Index ID of the current ebuild.
  } );

=back

=cut

sub iterate {
  my ( $self, $what, $callback ) = @_;
  my %method_map = ( ebuilds => _iterate_ebuilds =>, );
  if ( exists $method_map{$what} ) {
    goto $self->can( $method_map{$what} );
  }
  return exception(
    ident   => 'bad iteration method',
    message => 'The iteration method %{what_method}s is not a known way to iterate.',
    payload => { what_method => $what },
  );
}

=p_method _iterate_ebuilds

  $object->_iterate_ebuilds( ignored_value => sub {  } );

Handles dispatch call for

  $object->iterate( ebuilds => sub { } );

=cut

# ebuilds = {/ebuilds }
sub _iterate_ebuilds {
  my ( $self, $what, $callback ) = @_;
  my %ebuilds     = $self->ebuilds();
  my $num_ebuilds = scalar keys %ebuilds;
  my $last_ebuild = $num_ebuilds - 1;
  my $offset      = 0;
  for my $ename ( sort keys %ebuilds ) {
    local $_ = $ebuilds{$ename};
    $self->$callback(
      {
        ebuild_name => $ename,
        ebuild      => $ebuilds{$ename},
        num_ebuilds => $num_ebuilds,
        last_ebuild => $last_ebuild,
        ebuild_num  => $offset,
      }
    );
    $offset++;
  }
  return;

}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
