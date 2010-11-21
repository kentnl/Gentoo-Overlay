#!/usr/bin/perl

use strict;
use warnings;

use Gentoo::Overlay;

my $overlay = Gentoo::Overlay->new( path => '/usr/portage' );

my %categories = $overlay->categories;

for( sort keys %categories ){
    print $categories{$_}->pretty_name, "\n";
}
