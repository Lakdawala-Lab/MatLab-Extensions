# Matlab-Extensions

This directory contains matlab scripts that can be used as XTension plugins with the image processing software Imaris from BitPlane. Also included are MATLAB scripts that can read excel files with data output by the XTension scripts. 

To use these extensions for analysis of images, simply copy the '.m' files with names starting with "XT" into your Imaris MATLAB XTensions directory. In Windows, this is usually found under 

> C:\Program Files\Bitplane\Imaris x64 8.4.1\XT\matlab\ 

or replace 'C:\Program Files\Bitplane\Imaris x64 8.4.1' with the directory in which you can find your Imaris installation. 

Once copied, restart Imaris, or under Preferences>CustomTools>Xtension Folders, re-choose the above mentioned directory and the new scripts will show up under "Tools" . For example, the XTSpotsColocalizeFISH.m will appear under "Tools", denoted by the pink cog, when a "Spots" object is selected and under Image Processing>Spots Functions.

The following scripts are useful for finding colocalized spots across multiple microscopy channels in images obtained from techniques such as fluorescence in-situ hybridization (FISH). Feel free to use these scripts in your analysis and modify them as needed. 

A detailed explanation of what each script does can be found in the comments at the beginning of each script file. In brief, here is what the following files do:

Filename | Function
---------|---------
XTSpotsColocalizeFISH.m | finds colocalized spots from a collection of up to 3 spot objects.
XTSpotsColocalizeFISH4.m | finds colocalized spots from a collection of up to 4 spot objects.
XTExportSpotsXLS.m | export spot and track information from a time-resolved Imaris dataset
XTTrackConnectStartAndEnd.m | identify split/merge locations and make missing connections in Imaris
node_network_analysis.m | use XLS file exported by XTExportSpotsXLS.m to analyse as a directed graph in MATLAB

The following scripts are useful for analysing diSPIM datasets, which includes removing timepoint-to-timepoint intensity flicker, computing cumulative frequency graphs (and CF<sub>50</sub> values), arrest coefficients. More details below.

Filename | Function
---------|---------
XTTrackPlotArrCoeff.m	| Calculates Arrest coefficients within Imaris and outputs analysis to an excel file
plot_arr_coeff_from_xlsx.m | Reads excel output from XTTrackPlotArrCoeff and calculates overall arrest coefficient for the cell
plot_track_stats_from_batch_exports.m | Reads batch exports of various motion parameters output by Imaris and plots cumulative frequency graphs to calculate CF<sub>50</sub> parameter.
rem_flicker.m | Poor alignment generates two views with disparate data intensity. Registration and subsequent fusion can generate intensity flicker from timepoint to timepoint. This Matlab script renormalizes the overall intensity so that spots maintain intensity over time and they can be reliably tracked using Imaris tracking algorithms. 
