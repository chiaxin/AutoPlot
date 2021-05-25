use strict;
use warnings;
package Parse;
use Config::Tiny;
use File::Basename;
use File::Spec;
use FindBin;
use Data::Dumper;

my $ConfigFile = File::Spec->catfile(dirname($FindBin::Bin), "setup.ini");

our %PlottingMaps = ();
our $MaxNumber = 0;
our $PlotTotal = 0;
our $PlotSize = 32;
our $Buckets = 128;
our $Threads = 2;
our $Memory = 4096;
our $Interval = 7200;

sub test
{
    my $pointer = {};
    $pointer->{Configuration} = $ConfigFile;
    $pointer->{plotting} = \%PlottingMaps;
    $pointer->{settings} = {
        size     => $PlotSize,
        buckets  => $Buckets,
        threads  => $Threads,
        memory   => $Memory,
        interval => $Interval,
        max      => $MaxNumber,
        total    => $PlotTotal
    };
    print Dumper($pointer);
    return $pointer;
}

sub check_plot_size
{
    my $size = shift;
    if ($size >= 32 && $size <= 35) {
        $PlotSize = $size;
    } else {
        printf "Plot Size must between 32 ~ 35 ! current : %d\n", $size;
    }
}

sub check_buckets
{
    my %valid_buckets = (
        32  => 1,
        64  => 1,
        128 => 1,
        256 => 1
    );
    my $buckets = shift;
    if (exists $valid_buckets{$buckets}) {
        $Buckets = $buckets;
    } else {
        printf "Buckets value must in %s ! current : %s\n",
            ( join ",", sort keys %valid_buckets ),
            $buckets
        ;
    }
}

sub parsing
{
    if (-f $ConfigFile) {
        my $config = Config::Tiny->read($ConfigFile, 'utf8');
        foreach ( keys %{ $config } ) {
            if (m/^[A-Z]:\\/) {
                # Get destination folders if exists.
                $PlottingMaps{$_} = [split ",", $config->{$_}->{farm}];
                # Get number of destination folder(s).
                my $size_of_farm = scalar @{ $PlottingMaps{$_} };
                # If no any destination found. delete it.
                # Get max number between each plot task.
                unless ($size_of_farm) {
                    delete $PlottingMaps{$_};
                } else {
                    $PlotTotal += $size_of_farm;
                    $MaxNumber = $size_of_farm if $MaxNumber < $size_of_farm;
                }
            } elsif (m/Setting/) {
                my $setting = $config->{Setting};
                check_plot_size($setting->{size}) if exists $setting->{size};
                if (exists $setting->{memory}) {
                    $Memory = $setting->{memory};
                }
                check_buckets($setting->{buckets}) if exists $setting->{buckets};
                if (exists $setting->{threads}) {
                    $Threads = $setting->{threads};
                }
                if (exists $setting->{interval}) {
                    $Interval = $setting->{interval};
                }
            } else {
                printf "Unknown setting : " . $_ . "\n";
            }
        }
    } else {
        printf "Configuration file : %s is not found!\n", $ConfigFile;
    }
}

parsing;

1;