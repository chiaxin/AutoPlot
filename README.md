# Chia block-chain Auto Plot and Check use Perl Script

## Usage

### Configuration

* The configuration file is "setup.ini"

Setup your temporary directory and destinations.
```ini
[D:\ChiaPlots]
farm = E:\Chia,F:\Chia,G:\Chia

[M:\ChiaPlots]
farm = H:\Chia,J:\Chia
```
In the first line,
It will create 3 task parallel to E:\Chia, F:\Chia and G:\Chia,  
using D:\ChiaPlots as plotting temporary directory.

In the second line,
It will create 2 task parallel to H:\Chia and J:\Chia,  
using M:\ChiaPlots as plotting temporary directory.

### Auto Plot

ms_continuous_plot.bat

### Check Duplicated Plots

ms_check_duplicated_plot.bat