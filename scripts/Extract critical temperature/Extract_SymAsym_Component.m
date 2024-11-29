clc;clear;close all;
if exist('log.txt', 'file') 
    delete('log.txt');
end
diary('log.txt');
%% ############### User Defined ###############
% Data file name
NegPosSweepFileName = 'SYM-2-IV-01.dat';
PosNegSweepFileName = 'SYM-2-IV.dat';

% Magnetic fields in Oersted (Oe)a
FieldH = {-12500; -12000; -11000; -10000; -9000; -8000; -7000; -6000; -5000; 
    -4000; -3000; -2000; -1000; -900; -800; -700; -600; -500; -400; -300; 
    -200; -100; 0; 100; 200; 300; 400; 500; 600; 700; 800; 900; 1000; 2000; 
    3000; 4000; 5000; 6000; 7000; 8000; 9000; 10000; 11000; 12000; 12500};

% set up whether use the current folder
UseExistingFolder = false;  % true or false


%% ############### diary off ###############
diary off;