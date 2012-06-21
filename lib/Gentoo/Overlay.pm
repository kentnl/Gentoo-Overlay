use strict;
use warnings;

package Gentoo::Overlay;
BEGIN {
  $Gentoo::Overlay::VERSION = '0.03000000';
}

# ABSTRACT: Tools for working with Gentoo Overlays

use Moose;

use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Class qw( File Dir );
use MooseX::ClassAttribute;
use namespace::autoclean;
use Carp qw();
use Gentoo::Overlay::Category;
use Gentoo::Overlay::Types qw( :all );
use Gentoo::Overlay::Exceptions qw( :all );



has 'path' => isa => Dir,
  ro, coerce, default => sub {
  exception(
    ident   => 'path parameter required',
    message => '%{package}s requires the \'path\' attribute passed during construction',
    payload => { package => __PACKAGE__ }
  );
  };


has 'name' => isa => Gentoo__Overlay_RepositoryName, ro, lazy_build;


sub _build_name {
  my ($self) = shift;
  my $f = $self->default_path( repo_name => );
  if ( ( !-e $f ) or ( !-f $f ) ) {
    exception(
      ident   => 'no repo_name',
      message => qq[No repo_name file for overlay at: %{overlay_path}s\n Expects:%{expected_path}s}],
      payload => {
        overlay_path  => $self->path->stringify,
        expected_path => $f->stringify,
      }
    );
  }
  return scalar $f->slurp( chomp => 1, iomode => '<:raw' );
}


has _profile_dir => isa => Dir, ro, lazy_build;


sub _build__profile_dir {
  my ($self) = shift;
  my $pd = $self->default_path( profiles => );
  if ( ( !-e $pd ) or ( !-d $pd ) ) {
    exception(
      ident   => 'no profile directory',
      message => qq[No profile directory for overlay at: %{overlay_path}s\n  Expects:%{expected_path}s],
      payload => {
        overlay_path  => $self->path->stringify,
        expected_path => $pd->stringify,
      }
    );
  }
  return $pd->absolute;
}






has _categories => isa => HashRef [Gentoo__Overlay_Category],
  ro, lazy_build,
  traits  => [qw( Hash )],
  handles => {
  _has_category  => exists   =>,
  category_names => keys     =>,
  categories     => elements =>,
  get_category   => get      =>,
  };


sub _build__categories {
  my ($self) = @_;
  my $cf = $self->default_path('catfile');
  if ( ( !-e $cf ) or ( !-f $cf ) ) {
    warning(
      ident   => 'no category file',
      message => "No category file for overlay %{name}s, expected: %{category_file}s. \n Falling back to scanning",
      payload => {
        name          => $self->name,
        category_file => $cf->stringify
      }
    );
    goto $self->can('_build___categories_scan');
  }
  goto $self->can('_build___categories_file');
}


class_has _default_paths => isa => HashRef [CodeRef],
  ro, lazy, default => sub {
  return {
    'profiles'  => sub { shift->path->subdir('profiles') },
    'repo_name' => sub { shift->_profile_dir->file('repo_name') },
    'catfile'   => sub { shift->_profile_dir->file('categories') },
    'category'  => sub { shift->path->subdir(shift) },
    'package'   => sub { shift->default_path( 'category', shift )->subdir(shift) },
  };

  };


sub default_path {
  my ( $self, $name, @args ) = @_;
  if ( !exists $self->_default_paths->{$name} ) {
    exception(
      ident   => 'no default path',
      message => q[No default path '%{name}s'],
      payload => { path => $name }
    );
  }
  return $self->_default_paths->{$name}->( $self, @args );
}


sub _build___categories_file {
  my ($self) = shift;
  my %out;
  for my $cat ( $self->default_path('catfile')->slurp( chomp => 1, iomode => '<:raw' ) ) {
    my $category = Gentoo::Overlay::Category->new(
      name    => $cat,
      overlay => $self,
    );
    if ( !$category->exists ) {
      exception(
        ident   => 'missing category',
        message => q[category %{category_name}s is not an existing directory (%{expected_path}s) for overlay %{overlay_name}s ],
        payload => {
          category_name => $category->name,
          expected_path => $category->path->stringify,
          overlay_name  => $self->name,
        }
      );
      next;
    }
    $out{$cat} = $category;
  }
  return \%out;
}


sub _build___categories_scan {
  my ($self) = shift;
  my %out;
  my $dir = $self->path->absolute->open();
  while ( defined( my $entry = $dir->read() ) ) {
    my $cat = $entry;
    next if Gentoo::Overlay::Category->is_blacklisted($cat);

    my $category = Gentoo::Overlay::Category->new(
      overlay => $self,
      name    => $cat,
    );
    next unless $category->exists();
    $out{$cat} = $category;
  }
  return \%out;

}


sub iterate {
  my ( $self, $what, $callback ) = @_;
  if ( $what eq 'categories' ) {
    my %categories     = $self->categories();
    my $num_categories = scalar keys %categories;
    my $last_category  = $num_categories - 1;
    my $offset         = 0;
    for my $cname ( sort keys %categories ) {
      local $_ = $categories{$cname};
      $self->$callback(
        {
          category_name  => $cname,
          category       => $categories{$cname},
          num_categories => $num_categories,
          last_category  => $last_category,
          category_num   => $offset,
        }
      );
      $offset++;
    }
    return;
  }
  if ( $what eq 'packages' ) {
    $self->iterate(
      'categories' => sub {
        my (%cconfig) = %{ $_[1] };
        $cconfig{category}->iterate(
          'packages' => sub {
            my %pconfig = %{ $_[1] };
            $self->$callback( { ( %cconfig, %pconfig ) } );
          }
        );
      }
    );
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


__END__
=pod

=head1 NAME

Gentoo::Overlay - Tools for working with Gentoo Overlays

=head1 VERSION

version 0.03000000

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

=head1 METHODS

=head2 default_path

Useful function to easily wrap the class-wide method with a per-object sugar.

    $overlay->default_path('profiles');
    ->
    ::Overlay->_default_paths->{'profiles'}->($overlay);
    ->
    $overlay->path->subdir('profiles')


    $overlay->default_path('category','foo');
    ->
    ::Overlay->_default_path('category')->( $overlay, 'foo' );
    ->
    $overlay->path->subdir('foo')

    $overlay->default_path('repo_name');
    ->
    ::Overlay->_default_path('repo_name')->( $overlay );
    ->
    $overlay->_profile_dir->file('repo_name')

They're class wide functions, but they need individual instances to work.

=head1 ATTRIBUTES

=head2 path

Path to repository.

    isa => Dir, ro, required, coerce

L<MooseX::Types::Path::Class/Dir>

=head2 name

Repository name.

    isa => Gentoo__Overlay_RepositoryName, ro, lazy_build

L<< C<RepositoryName>|Gentoo::Overlay::Types/Gentoo__Overlay_RepositoryName >>

L</_build_name>

=head1 ATTRIBUTE ACCESSORS

=head2 category_names

Returns a list of the names of all the categories.

    my @list = sort $overlay->category_names();

L</_categories>

=head2 categories

Returns a hash of L<< C<Category>|Gentoo::Overlay::Category >> objects.

    my %hash = $overlay->categories;
    print $hash{dev-perl}->pretty_name; # dev-perl/::gentoo

L</_categories>

=head2 get_category

Returns a Category Object for a given category name

    my $cat = $overlay->get_category('dev-perl');

L</_categories>

=head1 PRIVATE ATTRIBUTES

=head2 _profile_dir

Path to the profile sub-directory.

    isa => Dir, ro, lazy_build

L<MooseX::Types::Path::Class/Dir>

L</_build__profile_dir>

=head2 _categories

The auto-generating category hash backing

    isa => HashRef[ Gentoo__Overlay_Category ], ro, lazy_build

L</_build__categories>

L</_has_category>

L</category_names>

L</categories>

L</get_category>

L<Gentoo::Overlay::Types/Gentoo__Overlay_Category>

L<< C<MooseX::Types::Moose>|MooseX::Types::Moose >>

=head1 PRIVATE ATTRIBUTE ACCESSORS

=head2 _has_category

Returns if a named category exists

    $overlay->_has_category("dev-perl");

L</_categories>

=head1 PRIVATE CLASS ATTRIBUTES

=head2 _default_paths

Class-wide list of path generators.

    isa => HashRef[ CodeRef ], ro, lazy_build

L</_build__default_paths>

=head1 PRIVATE METHODS

=head2 _build_name

Extracts the repository name out of the file 'C<repo_name>'
in C<$OVERLAY/profiles/repo_name>

    $overlay->_build_name

L</name>

=head2 _build__profile_dir

Verifies the existence of the profile directory, and returns the path to it.

    $overlay->_build__profile_dir

L</_profile_dir>

=head2 _build__categories

Generates the Category Hash-Table, either by reading the categories index ( new, preferred )
or by traversing the directory ( old, discouraged )

    $category->_build_categories;

L</_categories>

L</_build___categories_scan>

L</_build___categories_file>

=head2 _build___categories_file

Builds the category map using the 'categories' file found in the overlays profile directory.

    $overlay->_build___categories_file

=head2 _build___categories_scan

Builds the category map the hard way by scanning the directory and then skipping things
that are files and/or blacklisted.

    $overlay->_build___categories_scan

=for Pod::Coverage iterate

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

