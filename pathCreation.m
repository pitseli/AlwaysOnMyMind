%% CONSTANTS
clear; format compact;
% Linux
if isunix
    str = './Project/eeglab13_4_4b/plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp';
    indir = './Project';
    kevindir = './Datasets/KevinFormatted/';
    plotdir = './Datasets/plots/';
    processeddir = './Datasets/processed/';
    rawdir = './Datasets/raw/';

elseif ispc
    % Windows
    str = '.\Project\eeglab13_4_4b\plugins\dipfit2.3\standard_BESA\standard-10-5-cap385.elp';
    indir = '.\Project\';
    kevindir = '.\Datasets\KevinFormatted\';
    plotdir = '.\Datasets\plots\';
    processeddir = '.\Datasets\processed\';
    rawdir = '.\Datasets\raw\';
else
    disp('what kind of a computer are you using?')
end

addpath(genpath(indir));
addpath(genpath(kevindir));
addpath(genpath(plotdir));
addpath(genpath(processeddir));
addpath(genpath(rawdir));