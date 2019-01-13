package App::acbegpx2garmin;

use strict;
use warnings;
use Exporter qw(import);
use Carp;
use Switch;
use Params::Check qw(check);

our @EXPORT = qw(run);

our $VERSION = 0.01;
our $VERBOSE = 0;
our $DEBUG   = 0;

use File::Spec;
use File::Find;
use File::Copy;
use File::Basename;

use Getopt::Long;

use LWP::Simple;
use IO::Prompter;


use constant DEBUG => 0;
use constant DOWNLOADS => File::Spec->catfile($ENV{HOME}, 'Downloads');

sub run {
    # Preferences
    my @search_dirs = ($ENV{HOME});
    my $interactive;
    read_acbe_cal();
    my ($base_dir, $device) = find_usb_device(device_mark => 'GARMIN');

    # Find NewFiles
    my $dir_new_files = File::Spec->catfile($base_dir, 'Garmin', 'NewFiles');
    print "Preparing copy GPX file to GARMIN in $dir_new_files...\n";
    croak "Error 04 - cannot found directory '$dir_new_files'.\n" unless (-d $dir_new_files);

    # Find gpx_files
    my @gpx_files;
    my $search_gpx_files = sub {
        return unless (-f $_);
        if (m/\.gpx$/i) {
            return if ($File::Find::dir =~ m/archive/i);
            print "\tFound GPX File '$_' on computer\n";
            push @gpx_files, $File::Find::name;
        }
    };
    find($search_gpx_files, @search_dirs);

    # Apply to each GPX
    foreach my $file_selected (@gpx_files) {
        my $target = File::Spec->catfile($dir_new_files, basename($file_selected));
    
        if ($interactive) {
            interactive_move($file_selected, $target);
            next;
        }
        print "\tCopying '$file_selected'...\n";
        move($file_selected, $target) or croak "Error 05 - Cannot move file '$file_selected' => '$target': $!\n";
    }

    # End with USB
    eject_usb_device($device);

}

sub replace_month_name_by_number {
    my $month_name = shift @_;
    
    switch ($month_name) {
        case m/^ja/      {return '01'}
        case m/^f/       {return '02'}
        case m/^mar/     {return '03'}
        case m/^av/      {return '04'}
        case m/^mai/     {return '05'}
        case m/^juin/    {return '06'}
        case m/^juil/    {return '07'}
        case m/^a/       {return '08'}
        case m/^sep/     {return '09'}
        case m/^oct/     {return '10'}
        case m/^nov/     {return '11'}
        case m/^d/       {return '12'}
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

sub read_acbe_cal {
    my $url_acbe_cal = "http://acbe.ffct.org/Calendrier";
    my $content = LWP::Simple::get($url_acbe_cal) or croak "Error 400 - Cannot get '$url_acbe_cal': $!\n";
    
    DEBUG && carp "DEBUG - HTTP: $content\n";
    URL: while ($content =~ m{
        <td[^>]*>\w+\s+(\d+)\s+(\S+)\s+(\d+)</td><td[^>]*>([\dh]+).*? # la date
        <a\s+href="              # le starter de lien
        (\S+openrunner[^"]+)     # le lien openrunner
        "[^>]*>                  # la fin du de la balise de lien
        <img\s+title="Open\w+\s+ # l'image avec un titre
        ([^"]+)                  # le nom du titre
        }xgms) {
        my ($day, $month, $year, $time, $openrunner_url, $name) = ($1, $2, $3, $4, $5, $6);
        
        print "Work with track '$openrunner_url:\n";
        
        $month = replace_month_name_by_number($month);
        my $id = "${name}_$year-$month-${day}_${time}";
        my ($openrunner_id) = ($openrunner_url =~ m{/(\d+)$});
        
        my $gpx_track_url = "https://www.openrunner.com/route/$openrunner_id/gpx?type=0";
        
        print "\tDownload track $openrunner_id from $name plan $day/$month/$year, $time\n";
        my $gpx_file = File::Spec->catfile(DOWNLOADS, "${name}-${openrunner_id}.gpx");
        my $code     = LWP::Simple::getstore($gpx_track_url, $gpx_file);
        print "\tDownload track $openrunner_id done with code $code\n";
        if ($code != 200) {
            carp "Error $code - Cannot download $gpx_track_url\n";
            unlink $gpx_file;
            next URL;
        }
        
        if (-f $gpx_file) {
            my @gpx;
            print "\tRewrite track '$gpx_file' - change title...\n";
            open my $fh, $gpx_file or croak "Error 300 - Cannot open file '$gpx_file': $!\n";
            while (<$fh>) {
                s{<name>(\d+)-([^<]+)</name>}{<name>$2-$1-${openrunner_id}</name>} if (m{<name>});
                push @gpx, $_;
            }
            close $fh;
            
            write_data_to_file(\@gpx, $gpx_file);
            print "\tRewrite track '$gpx_file' done.\n";
        }
    }
}

sub find_usb_device {
    my %args = @_;
    
    my ($device_mark, $retry);
    my $template = {
        device_mark => { required => 1, store => \$device_mark, },
        retry       => { allow => [0-100], default => 5, store => \$retry },
    };
    my $parsed = check($template, \%args, $VERBOSE) or croak "Error 1000 - Invalid argument.\n";
    
    my $find_device_mark;
    print "Detect '$device_mark':\n";
    ATTEMPT: for (my $i = 0; $i < $retry; $i++) {
        print "\tScan USB for '$device_mark'...\n";
        open my $ch, '-|', 'lsusb' or croak "Error 600 - Cannot scan usb with lsusb: $!\n";
        while (<$ch>) {
            if (m{$device_mark}i) {
                print "\tFound $device_mark\n";
               $find_device_mark++; 
               last ATTEMPT;
            }
        }
        close $ch;
        sleep 10;
    }
    croak "Error 601 - Device '$device_mark' not found.\n" unless ($find_device_mark);
    
    my $find_fs_mounted;
    my $find_device;

    print "\tChecking '$device_mark' block device...\n";
    open my $ch, '-|', 'lsblk', '-o', 'RM,TYPE,NAME,MOUNTPOINT' or croak "Error 602 - Cannot lsblk: $!\n";
    DEVICE: while (<$ch>) {
        DEBUG && carp "DEBUG_BLK: $_";
        if (my ($device, $fs_name) = m{1\s+disk\s+(\w+)\s*(\S*)\s*$}) {
            DEBUG && carp "DEBUG: $_ : $device $fs_name\n";
            $find_device = $device;
            if ($fs_name and $fs_name =~ m/$device_mark/) {
                $find_fs_mounted = $fs_name;
                last DEVICE;
            }
        }
    }
    close $ch;
    
    croak "Error 603 - no device found with lsblk.\n" unless ($find_device);
    $find_device = '/dev/'.$find_device;
    print "\tFound block device '$find_device'\n";
    
    if ($find_fs_mounted) {
        print "\tDevice mounted at $find_fs_mounted\n";
        return ($find_fs_mounted, $find_device);
    }
    
    print "\tMounting device '$find_device'...\n";
    open my $ch2, '-|', 'udisksctl', 'mount', '-b', $find_device or croak "Error 604 - Cannot mount '$find_device': $!\n";
    while (<$ch2>) {
        if (m{Mounted $find_device at (\S+)\.$}) {
            $find_fs_mounted = $1;
        }
    }
    close $ch2;
    
    croak "Error 605 - Cannot succeed to mount '$device_mark'.\n" unless $find_fs_mounted;
    
    print "\tDevice mounted at $find_fs_mounted\n";
    return ($find_fs_mounted, $find_device);
}

sub eject_usb_device {
    my ($device) = @_;
    
    system('udisksctl', 'unmount', '-b', $device);
    system('udisksctl', 'power-off', '-b', $device);
}

sub interactive_move {
    my ($file_selected, $target) = @_;
    
    my $action = prompt 'Choose action', -menu => [qw(Add Delete Skip)], '>';
    switch ($action) {
        case 'Add' {
            move($file_selected, $target) or croak "Error 05 - Cannot move file '$file_selected' => '$target': $!\n";        
        }
        case 'Delete' {
            unlink($file_selected) or croak "Error 06 - Cannot remove file '$file_selected': $!\n";
        }
    }
    return;
}

1; # End of App::acbegpx2garmin

__END__

=pod

=head1 NAME

App::acbegpx2garmin - The great new App::acbegpx2garmin!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use App::acbegpx2garmin;

    my $foo = App::acbegpx2garmin->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut


=head1 AUTHOR

Laurent Bendavid, C<< <laurent.bendavid at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-acbegpx2garmin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-acbegpx2garmin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::acbegpx2garmin


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


