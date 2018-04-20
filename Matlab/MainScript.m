% Change Directory to Locationn of This mfile
[pathstr,name,ext] = fileparts(which(mfilename));
cd(pathstr);

inverter.EfficiencyMatrix = dlmread('..\Test Files\invEffMatrix.txt', '\t')*0.01;
inverter.Power = dlmread('..\Test Files\invEffPower.txt', '\t');
inverter.Voltage = dlmread('..\Test Files\invEffVoltage.txt', '\t');
invParams = dlmread('..\Test Files\invParams.txt', '\t');
    inverter.ParasiticPower = invParams(1);
    inverter.DCRating = invParams(2);
    inverter.TrackMaxEff = invParams(3);
    inverter.TrackRelativeEff = invParams(4);
    
dcPower = dlmread('..\Test Files\dcPower.txt', '\t');

relativeSystemDCPowerChange = dcPower - invDCRating;
relativeSystemDCPowerChange(relativeSystemDCPowerChange>0) = 0;
mpptEfficiency = invTrackMaxEff - relativeSystemDCPowerChange*invTrackRelativeEff;
trackedSystemPower = dcPower.*mpptEfficiency;

trackedSystemVoltage = modVmpp*numModulesPerString*vTempFactor;

parasiticFilteredPower = trackedSystemPower;
parasiticFilteredPower(parasiticFilteredPower<invParasiticPower) = 0;
invEfficiency = interp2(invEffPower,invEffVoltage,invEffMatrix,parasiticFilteredPower,trackedSystemVoltage, 'linear');
systemACPower = invEfficiency.*parasiticFilteredPower;