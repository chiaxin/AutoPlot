@ECHO OFF

SET CURRENT=%~dp0
perl %CURRENT%\pl\check_duplicated_plots.pl

PAUSE