package Local::Utils;

use strict;
use warnings;
use Exporter qw(import);
use Carp;
use Switch;
use Params::Check qw(check);

our @EXPORT = qw(get_month_number_from_month_name write_data_to_file);

our $VERSION = 0.01;
our $VERBOSE = 0;
our $DEBUG   = 0;

sub get_month_number_from_month_name {
    my $month_name = shift @_;
    
    switch ($month_name) {
        case m/^ja/i      {return '01'}
        case m/^f/i       {return '02'}
        case m/^mar/i     {return '03'}
        case m/^a[pv]/i   {return '04'}
        case m/^ma[iy]/i  {return '05'}
        case m/^jui?n/i   {return '06'}
        case m/^jui?l/i   {return '07'}
        case m/^a/i       {return '08'}
        case m/^sep/i     {return '09'}
        case m/^oct/i     {return '10'}
        case m/^nov/i     {return '11'}
        case m/^d/i       {return '12'}
    }
    
    croak "Error 700 - Invalid month name '$month_name'.\n";
}

sub write_data_to_file {
    my ($data_aref, $file) = @_;
    
    open my $wh, '>', $file or croak "Error 301 - Cannot write file '$file': $!\n";
    print $wh @{$data_aref};
    close $wh;
    
    return;
}

1; # End
__END__

=pod

=head1 NAME

Local::Utils - Some generic utilataries subroutines

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Local::Utils;
    
    # Works for english and french
    my $month_number = get_month_number_from_month_name("janvier");

    my @data = ["some data\n", "other data\n"];
    my $file_name = '/tmp/toto.txt';
    write_data_to_file(\@data, $file_name);

=head1 EXPORT

    get_month_number_from_month_name
    write_data_to_file

=head1 SUBROUTINES/METHODS

=head2 my $month_number = get_month_number_from_month_name($month_name)

Return month_number from $month_name with two digits

=head2 write_data_to_file(\@data, $file_name)

Write @data in $file_name

=head1 AUTHOR

Laurent Bendavid, C<< <laurent.bendavid at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-acbegpx2garmin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-acbegpx2garmin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Local::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-acbegpx2garmin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-acbegpx2garmin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-acbegpx2garmin>

=item * Search CPAN

L<http://search.cpan.org/dist/App-acbegpx2garmin/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Laurent Bendavid.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


