use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use File::Spec;
use File::Temp qw/tempfile/;
use Data::Dumper;
use libs::ChiaPlot;
use libs::Parse;

$ChiaPlot::Memory = $Parse::Memory;
$ChiaPlot::Threads= $Parse::Threads;

my $Interval_parallel = $Parse::Interval;
my $Plotting_Limit = $Parse::MaxNumber;
my %Pairs = %Parse::PlottingMaps;
my @BatchFiles = ();

sub scan
{
    my $new_file_counter = 0;
    my @list = (keys %Pairs);
    for (my $idx = 0; $idx < scalar(@list); $idx++) {
        my $plot = $list[$idx];
        my $interval_counter = 0;
        my $plot_temporary = $plot;
        my $plot_destinations = $Pairs{$plot};
        $BatchFiles[$idx] = [];
        for my $dest (@{$plot_destinations}) {
            my $farm = $dest;
            my $plotter = ChiaPlot->new($plot_temporary, $farm);
            if ($plotter->is_temp_enough()) {
                print "Chia Plot Buffer is Ready : " . $plotter->{temp_disk} . "\n";
                if ($plotter->is_dest_enough()) {
                    print "Chia Plot Farm is Ready : " . $plotter->{dest_disk} . "\n";
                    my ($fileHandle, $filename) = tempfile(SUFFIX => ".bat");
                    print "[Chia] ${filename} has been created.\n";
                    print $fileHandle "\@ECHO OFF\n";
                    print $fileHandle "TITLE " . $plotter->get_title() . "\n";
                    print $fileHandle $plotter->get_create_command() . "\n";
                    print $fileHandle "rem Next Plotting.\n";
                    print $fileHandle "start $filename\n";
                    print $fileHandle "exit\n";
                    close $fileHandle;
                    push @{$BatchFiles[$idx]}, $filename;
                    $new_file_counter += 1;
                    $interval_counter += 1;
                }
                else {
                    warn "[Chia] Farm disk is no enough space.\n";
                }
            }
            else {
                warn "[Chia] Plot disk is no enough space.\n";
            }
        }
    }
    return $new_file_counter;
}

sub run
{
    scan;
    for (my $n = 0 ; $n < $Plotting_Limit ; $n++) {
        print ("[Chia] Try to plotting :: " . (${n} + 1) . "\n");
        for (my $idx = 0 ; $idx < scalar(@BatchFiles) ; $idx++) {
            my $size_of_dest = scalar(@{$BatchFiles[$idx]});
            if ($n < $size_of_dest) {
                system "start " . $BatchFiles[$idx]->[$n];
            }
        }
        print "Wait for next plot ... (${Interval_parallel}) seconds.\n";
        sleep $Interval_parallel;
    }
    print "Chia Plot Deploy Completed.\n";
    sleep(10);
}

run;