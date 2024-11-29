clc;clear;close all;
if exist('log.txt', 'file') 
    delete('log.txt');
end
diary('log.txt');
%% ############### User Defined ###############
% Data file name
FileName = 'SYM-2-IV-01.dat';




%% ############### diary off ###############
diary off;