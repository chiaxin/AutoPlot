use strict;
use warnings;
package Plot;
use Config::Tiny;
use File::Spec;
use File::Basename;

my $ConfigFile = File::Spec->catfile(dirname($FindBin::Bin), "setup.ini");
my $Config = Config::Tiny->read($ConfigFile, 'utf8');

my $QPlotFileName = qr/
    plot-
    k(?<Size>\d\d)-
    (?<Year>\d\d\d\d)-
    (?<Month>\d\d)-
    (?<Day>\d\d)-
    (?<Hours>\d\d)-
    (?<Minute>\d\d)-
    (?<Id>\w+)\.plot
/x;

sub new
{
    my $class = shift;
    my $self = {
        file_path => shift,
        is_valid  => 0
    };

    $self->{base} = basename $self->{file_path};

    if ($self->{base} =~ m/$QPlotFileName/) {
        $self->{size} = $+{Size};
        $self->{year} = $+{Year};
        $self->{month}= $+{Month};
        $self->{day}  = $+{Day};
        $self->{hours}= $+{Hours};
        $self->{min}  = $+{Minute};
        $self->{id}   = $+{Id};
        $self->{is_valid} = 1;
    } else {
        $self->{is_valid} = 0;
    }
    bless $self, $class;
    return $self;
}

sub get_id
{
    return $_[0]->{id} if scalar @_ && exists $_[0]->{id};
    return undef;
}

sub is_eq
{
    my $self = shift;
    my $other= shift;
    if ($self->{id} eq $other->{id}) {
        return 1;
    }
    return 0
}

1;