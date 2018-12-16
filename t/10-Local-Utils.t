#!perl -T
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Local::Utils' ) || print "Bail out!\n";
}

diag( "Testing Local::Utils $Local::Utils::VERSION, Perl $], $^X" );
