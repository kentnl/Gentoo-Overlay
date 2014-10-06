use 5.006;
use strict;
use warnings;

package Gentoo::Overlay::Exceptions;

our $VERSION = '2.000000';

# ABSTRACT: A custom Exception class for Gentoo which also has warning-style semantics instead of failure

# AUTHORITY

use Moose qw( has with );
use MooseX::Types::Moose qw( HashRef Str );
use Sub::Exporter::Progressive -setup => { exports => [ 'exception', 'warning', ] };

use Readonly qw( Readonly );

Readonly our $W_SILENT  => 'silent';
Readonly our $W_WARNING => 'warning';
Readonly our $W_FATAL   => 'fatal';

our $WARNINGS_ARE = $W_WARNING;

=begin Pod::Coverage

as_string exception warning

=end Pod::Coverage

=cut

has 'payload' => (
  is       => 'ro',
  isa      => HashRef,
  required => 1,
  default  => sub { {} },
);

sub as_string {
  my ($self) = @_;
  ## no critic (RegularExpressions)
  return join q{}, $self->message, qq{\n\n  }, ( join qq{\n*  }, ( split /\n/, $self->stack_trace ) ), qq{\n};
}

use overload ( q{""} => 'as_string' );

## no critic (Subroutines::RequireArgUnpacking)
sub exception {
  return __PACKAGE__->throw(@_);
}

sub warning {

  # This code is because warnings::register sucks.
  # You can't do long-distance warning-changes that behave
  # similar to exceptions.
  #
  # warnings::register can only be toggled in the direcltly
  # preceeding scope.

  return if ( $WARNINGS_ARE eq $W_SILENT );
  if ( $WARNINGS_ARE eq $W_WARNING ) {
    ## no critic ( ErrorHandling::RequireCarping )
    return warn __PACKAGE__->new(@_);
  }
  return __PACKAGE__->throw(@_);
}

with(
  'Throwable',
  'Role::Identifiable::HasIdent',
  'Role::Identifiable::HasTags',
  'Role::HasMessage::Errf' => {
    lazy    => 1,
    default => sub { shift->ident },
  },
  'StackTrace::Auto',
  'MooseX::OneArgNew' => {
    type     => Str,
    init_arg => 'ident',
  },
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );    # Mx::OneArg's fault.

no Moose;

1;
