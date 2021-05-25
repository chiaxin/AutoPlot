use strict;
use warnings;
package Farming;
use FindBin;
use lib $FindBin::Bin;
use Plot;
use Config::Tiny;
use File::Spec;
use File::Basename;
use Data::Dumper;

my @Plots = ();
my $ConfigFile = File::Spec->catfile(dirname($FindBin::Bin), "setup.ini");
my $Config = Config::Tiny->read($ConfigFile, 'utf8');
my @FarmPlace = grep { -d $_ } split ",", $Config->{ Farming }->{ main };

foreach my $place (@FarmPlace) {
    push @Plots, grep { $_->{is_valid} } map { Plot->new($_) } <${place}\\*.plot>;
}

sub get_farms
{
    print $_ . "\n" foreach @FarmPlace;
}

sub get_plots
{
    print $_->{id} . "\n" foreach @Plots;
}

sub find_duplicated
{
    my %seen;
    my @duplicated_plots = ();
    foreach my $plot (@Plots) {
        next unless $seen{$plot->{id}}++;
    }
    print "\nSearch duplicated chia plot(s) ...\n";
    print "=================================\n";
    my $counter = 1;
    foreach my $id (keys %seen) {
        next if $seen{$id} == 1;
        printf " [%d] Duplicated plots below (%d) : \n", $counter,$seen{$id};
        foreach my $plot (@Plots) {
            if ($plot->{id} eq $id) {
                printf $plot->{file_path} . "\n";
                push @duplicated_plots, $plot->{file_path};
            }
        }
        print "=================================\n";
        $counter++;
    }
    if (!scalar @duplicated_plots) {
        print "Congratulations! No any duplicated plots !\n";
        print "Search Directories : \n";
        get_farms();
    }
    return @duplicated_plots;
}

1;
