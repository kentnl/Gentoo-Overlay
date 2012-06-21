use strict;
use warnings;

package Gentoo::Overlay::Exceptions;
BEGIN {
  $Gentoo::Overlay::Exceptions::VERSION = '1.0.0';
}

use Moose;
use MooseX::Types::Moose qw( :all );
use Sub::Exporter ();
use Readonly;

Readonly our $W_SILENT  => 'silent';
Readonly our $W_WARNING => 'warning';
Readonly our $W_FATAL   => 'fatal';

our $WARNINGS_ARE = $W_WARNING;


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

Sub::Exporter::setup_exporter( { exports => [ 'exception', 'warning', ] } );
use Data::Dump qw( dump );
with(
  'Throwable',
  'Role::Identifiable::HasIdent',
  'Role::Identifiable::HasTags',
  'Role::HasMessage::Errf' => {
    lazy    => 1,
    default => sub { shift->ident }
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

__END__
=pod

=head1 NAME

Gentoo::Overlay::Exceptions

=head1 VERSION

version 1.0.0

=for Pod::Coverage as_string exception warning

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

