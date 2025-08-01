classdef Sol103 < handle
    %FLUTTERSIM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % generic aero parameters
        Name = 'SOL103';

        % freqeuency & Structural Damping Info
        FreqRange = [0.01,50];
        NFreq = 500;
        LModes = 20;
        ModalDampingPercentage = 0;

        EigR_ID = 1;
        SPC_ID = 2;
        SPCs = [];

        %CoM and constraint Paramters
        g = 9.81;
        Grav_Vector = [0;0;1];

        WriteToF06 = true; % if false minimises whats written to f06.

        % CoM Info for Boundary Constraints
        isFree = false; % if is Free a Boundary condition will be applied to  the Centre of Mass
        CoM = ads.fe.Constraint.empty;
        DoFs = [];
    end
    
    methods
        function ids = UpdateID(obj,ids)
                obj.EigR_ID = ids.SID;
                obj.SPC_ID = ids.SID + 1;
                ids.SID = ids.SID + 2;
        end
        function str = config_string(obj)
            str = '';
        end


        %% A method to write a .bat file to the same location as the main .bdf which will run the analysis and make NASTRAN 
        % write the result to the appropriate bin folder. This is just a convenience if you want to run the analysis without
        % going via MATLAB.
        function writeJobSubmissionBat(~, binFolder)
            batFile = fullfile(pwd, binFolder, 'Source', 'run103.bat');
            fid = fopen(batFile,'w');
            fprintf(fid, '%s \n', 'nastran sol103.bdf out=..\bin\');
            fclose(fid);
        end    

    end

end

