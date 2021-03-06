% Change Directory to Location of this mfile
[pathstr,name,ext] = fileparts(which(mfilename));
cd(pathstr);


%% Load Inverter Parameters
inverter.EfficiencyMatrix = dlmread('..\Test Files\invEffMatrix.txt', '\t')*0.01; %Efficiency Matrix is typically in %, hence the factor of 0.01
inverter.Power = dlmread('..\Test Files\invEffPower.txt', '\t');
inverter.Voltage = dlmread('..\Test Files\invEffVoltage.txt', '\t');
invParams = dlmread('..\Test Files\invParams.txt', '\t');
    inverter.ParasiticPower = invParams(1);
    inverter.DCRating = invParams(2);
    inverter.TrackMaxEff = invParams(3);
    inverter.TrackRelativeEff = invParams(4);

    
%% Visualise Inverter Efficiency Curve and Show Parameters
figInverter = figure('units','normalized','outerposition',[0 0 1 1], 'color', [1 1 1], 'name', 'Inverter Specification');
surfc(inverter.Power, inverter.Voltage, inverter.EfficiencyMatrix);
xlabel('Power [W]');
ylabel('Voltage [V]');
zlabel('Efficieny');
shading interp;
% screen2jpeg('..\Output Files\figInverter.jpg');


%% String Power Data --> ts impp vmpp
stringPower = dlmread('..\Test Files\stringOutput.txt', '\t');
    stringOutput.timestamps = datetime(stringPower(:,1),'ConvertFrom','excel');
    stringOutput.impp = stringPower(:,2)
    stringOutput.vmpp = stringPower(:,3)
    stringOutput.pmpp = stringOutput.impp.*stringOutput.vmpp

    
%% Visualise String Output Power
figDCOutput = figure('units','normalized','outerposition',[0 0 1 1], 'color', [1 1 1], 'name', 'PV DC Output');
plot(stringOutput.timestamps, stringOutput.pmpp);
xlabel('DateTime');
ylabel('Power [W]');
% screen2jpeg('..\Output Files\figDCOutput.jpg');


%% Model Inverter Behaviour

% Calculate MPPT Tracking Efficiency
% % Caculate Relative Power to Max Tracking Efficiency
relativeSystemDCPowerChange = stringOutput.pmpp - inverter.DCRating;
% % Set All Relatives to Negative
relativeSystemDCPowerChange(relativeSystemDCPowerChange>0) = -1*relativeSystemDCPowerChange(relativeSystemDCPowerChange>0);
% % Determine Algorthmic Efficiency (Approximation for Averaged Input Data)
mpptEfficiency = inverter.TrackMaxEff - relativeSystemDCPowerChange*inverter.TrackRelativeEff;
% Calculated MPPT Tracked System Power
trackedSystemPower = stringOutput.pmpp.*mpptEfficiency;


%% Visualise MPPT Tracking Efficiencies
figMPPTEffs = figure('units','normalized','outerposition',[0 0 1 1], 'color', [1 1 1], 'name', 'MPPT Efficiencies');
histogram(mpptEfficiency);
xlabel('Efficiency');
ylabel('Frequency [h]');
% screen2jpeg('..\Output Files\figMPPTEffs.jpg');


%% Calculate AC Power Output
% Deduct Parasitic Power
parasiticFilteredPower = trackedSystemPower;
parasiticFilteredPower(parasiticFilteredPower<inverter.ParasiticPower) = 0;
% Interpolate AC Efficiencies from Inverter Specification
inversionEfficiencies = interp2(inverter.Power,inverter.Voltage,inverter.EfficiencyMatrix,parasiticFilteredPower,stringOutput.vmpp, 'linear');
inversionEfficiencies(inversionEfficiencies<0) = 0;
% Calculate AC Power Output
systemACPower = inversionEfficiencies.*parasiticFilteredPower;

% Calculate Full AC Power Efficiencies
acEfficiencies = systemACPower./stringOutput.pmpp;

%% Visualise PV to AC Power Efficiencies
figACEffs = figure('units','normalized','outerposition',[0 0 1 1], 'color', [1 1 1], 'name', 'PV DC to AC Efficiencies');
histogram(acEfficiencies);
xlabel('Efficiency');
ylabel('Frequency [h]');
% screen2jpeg('..\Output Files\figACEffs.jpg');


%% PV Power to AC Efficiency Correlation
figDCACCor = figure('units','normalized','outerposition',[0 0 1 1], 'color', [1 1 1], 'name', 'DC Power Against AC Efficiencies');
scatter(stringOutput.pmpp, acEfficiencies);
xlabel('DC Power [W]');
ylabel('Inverted Efficiency %');
% screen2jpeg('..\Output Files\figDCACCor.jpg');