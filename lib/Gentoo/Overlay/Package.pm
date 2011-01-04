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

has name => isa => Gentoo__Overlay_PackageName, required, ro;
has category => isa => Gentoo__Overlay_Category, required, ro, handles => [qw( overlay )];
has path => isa => Dir,
  ro, lazy, default => sub {
  my ($self) = shift;
  return $self->overlay->default_path( 'package', $self->category->name, $self->name );
  };

=pc_attr _scan_blacklist

Class-Wide list of blacklisted directory names.

    isa => HashRef[ Str ], ro, lazy_build,

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

sub pretty_name {
  my $self = shift;
  return $self->category->name . q{/} . $self->name . q{::} . $self->overlay->name;
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
