@ECHO OFF

SET CURRENT=%~dp0
perl %CURRENT%\src\check_duplicated_plots.pl

PAUSE