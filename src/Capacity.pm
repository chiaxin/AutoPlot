use warnings;
use strict;
package Capacity;

use constant GiB => 1024 * 1024 * 1024;

my $Plot32kNeedGiBSize = 239;
my $Plot33kNeedGibSize = 521;
my $Plot34kNeedGiBSize = 1041;
my $Plot35kNeedGiBSize = 2175;
my $Farm32kNeedGiBSize = 101.4;
my $Farm33kNeedGiBSize = 208.8;
my $Farm34kNeedGiBSize = 429.8;
my $Farm35kNeedGiBSize = 884.1;
my $PlotTempSizeMap = {
    32 => $Plot32kNeedGiBSize,
    33 => $Plot33kNeedGibSize,
    34 => $Plot34kNeedGiBSize,
    35 => $Plot35kNeedGiBSize
};
my $FarmPlotSizeMap = {
    32 => $Farm32kNeedGiBSize,
    33 => $Farm33kNeedGiBSize,
    34 => $Farm34kNeedGiBSize,
    35 => $Farm35kNeedGiBSize
};

sub need_temp_size
{
    my $size = shift;
    if ($size >= 32 && $size <= 35) {
        return $PlotTempSizeMap->{$size};
    }
    return -1;
}

sub need_farm_size
{
    my $size = shift;
    if ($size >= 32 && $size <= 35) {
        return $FarmPlotSizeMap->{$size};
    }
    return -1;
}

sub is_enough
{
    my $need = shift;
    my $temp = shift;
    if ($need < $temp) {
        return 1;
    }
    return 0;
}

sub get_free_space
{
    my $space = shift;
    if ( $space !~ m/^[A-Z]$/ ) {
        warn "Invalid disk : " . $space . "\n";
        return -1;
    }
    my $lines = do {
        open my $fh, "-|", "wmic logicaldisk where \"DeviceID='${space}:'\" get FreeSpace /format:value";
        local $/;
        <$fh>;
    };
    if ($lines =~ m/FreeSpace=(?<Cap>\d+)/) {
        return sprintf "%0.2f", $+{Cap} / GiB;
    } else {
        warn "Failed to get disk capacity : " . $space . "\n";
        return -2;
    }
}

sub is_plotting
{
    # example : is_plotting(32, "M");
    my $size = shift;
    my $disk = shift;
    my $space = get_free_space($disk);
    my $need = need_temp_size($size);
    print "[Plot] ${disk} current size : ${space} GiB\n";
    print "[Plot] ${size} k need size : ${need} GiB\n";
    return is_enough($need, $space);
}

sub is_farm
{
    # example : is_farm(32, "D");
    my $size = shift;
    my $disk = shift;
    my $space = get_free_space($disk);
    my $need = need_farm_size($size);
    print "[Farm] ${disk} current size : ${space} GiB\n";
    print "[Farm] ${size} k need size : ${need} GiB\n";
    return is_enough($need, $space);
}

1;