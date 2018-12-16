#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::acbegpx2garmin' ) || print "Bail out!\n";
}

diag( "Testing App::acbegpx2garmin $App::acbegpx2garmin::VERSION, Perl $], $^X" );
