use warnings;
use strict;
package ChiaPlot;
use FindBin;
use lib $FindBin::Bin;
use Capacity;
use Data::Dumper;
use File::Spec;
use File::Basename;

my $UserProfile = $ENV{UserProfile};

my @ChiaAppTokens = (
    "${UserProfile}", "AppData", "Local", "chia-blockchain", "app-1.1.5",
    "resources", "app.asar.unpacked", "daemon", "chia.exe"
);
# my $ChiaPlotterDirectory = File::Spec->catfile($UserProfile, ".chia", "mainnet", "plotter");

# Get last chia-blockchain app version for example "app-1.1.5"
my $ChiaLocation = File::Spec->catfile(@ChiaAppTokens[ 0 .. 3 ]);
my @ChiaVersions = sort { $a lt $b } map { basename $_ } <$ChiaLocation\\app-*>;
$ChiaAppTokens[4] = $ChiaVersions[0] if scalar @ChiaVersions;
my $ChiaApp = File::Spec->catfile(@ChiaAppTokens);

# Global Variables
# -k [size] : Define the size of the plot(s).
our $PlotSize= 32;
# -n [number of plots] : The number of plots that will be made.
our $PlotNum = 1;
# -b [memory buffer size MiB] : Define memory/RAM usage.
our $Memory  = 4096;
# -r [number of threads] : 2 is usually optimal, Multithreading is only in phase 1 currently.
our $Threads = 4;
# -u [number of buckets] : More buckets require less RAM but more random seeks to disk.
our $Buckets = 128;

sub new
{
    my $class = shift;
    my $self = {
        temp_dir   => shift,     # Plotting buffer directory
        dest_dir   => shift,     # Farm plot file directory
        public_key => "",        # Public key
        farmer_key => "",        # Farmer key
        pool_key   => "",        # Pool key
        plot_size  => $PlotSize, # Plot Size 32, 33, 34, 35k
        plot_num   => $PlotNum,  # Plotting number
        memory     => $Memory,   # Memory usage (MiB) at least 2500
        threads    => $Threads,  # CPU threads at least 2
        buckets    => $Buckets,  # Bucket - default is 128 (32, 64, 128)
        name       => ""
    };
    $self->{temp_disk} = substr $self->{temp_dir}, 0, 1;
    $self->{dest_disk} = substr $self->{dest_dir}, 0, 1;
    bless $self, $class;
    $self->parsing();
    return $self;
}

sub get_chia_app
{
    return $ChiaApp;
}

sub set_temp
{
    my $self = shift;
    my $temp = shift;
    if (-d $temp) {
        $self->{temp_dir} = $temp;
        $self->{temp_disk} = substr $self->{temp_dir}, 0, 1;
    } else {
        warn "Temporary directory is not found : " . $temp . "\n";
    }
}

sub set_dest
{
    my $self = shift;
    my $dest = shift;
    if (-d $dest) {
        $self->{dest_dir} = shift;
        $self->{dest_disk} = substr $self->{dest_dir}, 0, 1;
    } else {
        warn "Destination directory is not found : " . $dest . "\n";
    }
}

sub is_temp_enough
{
    my $self = shift;
    return Capacity::is_plotting($self->{plot_size}, $self->{temp_disk});
}

sub is_dest_enough
{
    my $self = shift;
    return Capacity::is_farm($self->{plot_size}, $self->{dest_disk});
}

sub set_name
{
    $_[0]->{name} = shift;
}

sub set_plot_num
{
    my $self = shift;
    my $input_plot_num = shift;
    if ($input_plot_num =~ m/\d+/) {
        $self->{plot_num} = $input_plot_num;
    } else {
        warn "Failed to set plot num : ${input_plot_num}";
    }
}

sub plot_num
{
    return $_[0]->{plot_num};
}

sub quote
{
    qq!\"$_[0]\"!;
}

sub parsing
{
    my $self = shift;
    my $lines = do {
        open my $fh, "-|", "${ChiaApp} keys show"; local $/; <$fh>;
    };
    foreach (split "\n", $lines) {
        if (m/^Fingerprint: (?<FingerPrint>\d+)$/) {
            $self->{finger} = $+{FingerPrint};
        }
        if (m/^Master public key \(m\): (?<PublicKey>[a-z0-9]+)$/) {
            $self->{public_key} = $+{PublicKey};
        }
        if (m/^Farmer public key \(m\/\d+\/\d+\/\d+\/\d+\): (?<FarmerPublicKey>[a-z0-9]+)$/) {
            $self->{farmer_key} = $+{FarmerPublicKey};
        }
        if (m/^Pool public key \(m\/\d+\/\d+\/\d+\/\d+\): (?<PoolPublicKey>[a-z0-9]+)$/) {
            $self->{pool_key} = $+{PoolPublicKey};
        }
    }
    return 1;
}

sub show
{
    my $self = shift;
    print("Finger Print : " . $self->{finger}     . "\n");
    print("Public Key : "   . $self->{public_key} . "\n");
    print("Farmer Key : "   . $self->{farmer_key} . "\n");
    print("Pool Key : "     . $self->{pool_key}   . "\n");
}

sub get_title
{
    my $self = shift;
    my @words = ("Chia Plot", $self->{name});
    push @words, $self->{temp_dir}, " to ", $self->{dest_dir}, " --- ";
    push @words, "[mem", $self->{memory} . "]";
    push @words, "[cpu", $self->{threads} . "]";
    push @words, "[size", $self->{plot_size} . "]";
    return join " ", @words;
}

sub get_create_command
{
    my $self = shift;
    (my $chia_app = $ChiaApp) =~ s/\//\\/g;
    my @commands =  (quote($chia_app), "plots", "create");
    push @commands, ("-k", $self->{plot_size});
    push @commands, ("-n", $self->{plot_num});
    push @commands, ("-b", $self->{memory});
    push @commands, ("-f", $self->{farmer_key});
    push @commands, ("-p", $self->{pool_key});
    push @commands, ("-a", $self->{finger});
    push @commands, ("-r", $self->{threads});
    push @commands, ("-u", $self->{buckets});
    push @commands, ("-t", quote($self->{temp_dir}));
    push @commands, ("-d", quote($self->{dest_dir}));
    return join " ", @commands;
}

1;