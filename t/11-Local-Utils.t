#!perl -T
use strict;
use warnings;
use Test::More;

plan tests => 4;

use Local::Utils;

is(get_month_number_from_month_name('janvier'),'01','get month number lowercase'); 
is(get_month_number_from_month_name('February'),'02','get month number firstuppercase english'); 
is(get_month_number_from_month_name('March'),'03','get month number firstuppercase english'); 
is(get_month_number_from_month_name('AOUT'),'08','get month number uppercase'); 
