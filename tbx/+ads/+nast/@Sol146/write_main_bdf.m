function write_main_bdf(obj,filename,includes)
arguments
    obj
    filename string
    includes (:,1) string
end
    fid = fopen(filename,"w");
    mni.printing.bdf.writeFileStamp(fid)
    %% Case Control Section
    mni.printing.bdf.writeComment(fid,'This file contain the main cards + case control for a 146 solution')
    mni.printing.bdf.writeHeading(fid,'Case Control');
    mni.printing.bdf.writeColumnDelimiter(fid,'8');
    println(fid,'NASTRAN BARMASS=1');
    println(fid,'NASTRAN NLINES=999999');
    println(fid,'NASTRAN QUARTICDLM=1');
    println(fid,'SOL 146');
    println(fid,'TIME 10000');
    println(fid,'CEND');
    mni.printing.bdf.writeHeading(fid,'Case Control')
    println(fid,'ECHO=NONE');
    fprintf(fid,'SPC=%.0f\n',obj.SPC_ID);
    println(fid,'RESVEC = YES');
    println(fid,'GROUNDCHECK=YES');
    println(fid,'K2PP = STIFF');   
    println(fid,sprintf('SDAMP = %.0f',obj.SDAMP_ID));
    println(fid,sprintf('FREQ = %.0f',obj.FREQ_ID));
    println(fid,sprintf('TSTEP = %.0f',obj.TSTEP_ID));
    println(fid,sprintf('METHOD = %.0f',obj.EigR_ID));
    
    % println(fid,'VECTOR(SORT1,REAL)=ALL');
    
    % check if any of the gusts are turbulence cases
    turbCount = 0;
    for i = 1:length(obj.Gusts)
        turbCount = turbCount + isa(obj.Gusts(i), 'ads.nast.gust.Turb');
    end
    
    % if any gusts are turbulence cases then we'll want the Power Spectral Density Function (PSDF) in output.
    if turbCount > 0
        outRqstStr = '(SORT1,REAL,PSDF)';
    else
        outRqstStr = '(SORT1,REAL)';
    end

    % write output requests.
    if ~isempty(obj.DispIDs)
        if any(isnan(obj.DispIDs))
            mni.printing.cases.SET(1,obj.EPoint_ID).writeToFile(fid);
        else
            mni.printing.cases.SET(1,[obj.DispIDs,obj.EPoint_ID]).writeToFile(fid);
        end
        println(fid,['DISPLACEMENT', outRqstStr, ' = 1']);
    else
        println(fid,['DISPLACEMENT', outRqstStr,' = ALL']);
    end
    if ~isempty(obj.ForceIDs)
        if any(isnan(obj.ForceIDs))
            println(fid,['FORCE', outRqstStr, ' = NONE']);
        else
            mni.printing.cases.SET(2,obj.ForceIDs).writeToFile(fid);
            println(fid,['FORCE', outRqstStr, ' = 2']);
        end
    else
        println(fid,['FORCE', outRqstStr, ' = ALL']);
    end
    % Add in a case to print stresses if we want them. Can use similar syntax for strain...
    if ~isempty(obj.StressIDs)
        if any(isnan(obj.StressIDs))
            println(fid,['STRESS', outRqstStr, ' = NONE']);
        else
            mni.printing.cases.SET(3,obj.StressIDs).writeToFile(fid);
            println(fid,['STRESS', outRqstStr, ' = 3']);
        end
    else
        println(fid,['STRESS', outRqstStr, ' = ALL']);
    end
    
    println(fid,'MONITOR = ALL');    
    
    % write gust subcases
    for i = 1:length(obj.Gusts)
        obj.Gusts(i).write_subcase(fid,i);
    end

    %% Bulk Data
    mni.printing.bdf.writeHeading(fid,'Begin Bulk')
    println(fid,'BEGIN BULK');
    
    % include files
    for i = 1:length(includes)
        mni.printing.cards.INCLUDE(includes(i)).writeToFile(fid);
    end
    % genric options 
    mni.printing.cards.PARAM('POST','i',0).writeToFile(fid);
    mni.printing.cards.PARAM('AUTOSPC','s','YES').writeToFile(fid);
    mni.printing.cards.PARAM('GRDPNT','i',0).writeToFile(fid);
    mni.printing.cards.PARAM('BAILOUT','i',-1).writeToFile(fid);
    % mni.printing.cards.PARAM('OPPHIPA','i',1).writeToFile(fid);
    mni.printing.cards.PARAM('AUNITS','r',0.1019716).writeToFile(fid);
    mni.printing.cards.PARAM('GUSTAERO','i',-1).writeToFile(fid);
    mni.printing.cards.MDLPRM('HDF5','i',0).writeToFile(fid);

    %write Boundary Conditions
    mni.printing.bdf.writeComment(fid, 'SPCs')
    mni.printing.cards.SPCADD(obj.SPC_ID,obj.SPCs).writeToFile(fid);
       
    %create eigen solver and frequency bounds
    mni.printing.bdf.writeComment(fid,'Eigen Decomposition Method')
    mni.printing.bdf.writeColumnDelimiter(fid,'8');
    mni.printing.cards.EIGR(obj.EigR_ID,'MGIV','F1',0,...
         'F2',obj.FreqRange(2),'NORM','MAX')...
         .writeToFile(fid);
%     mni.printing.cards.EIGR(10,'MGIV','ND',42,'NORM','MAX')...
%         .writeToFile(fid);
    fclose(fid);
end
function println(fid,string)
fprintf(fid,'%s\n',string);
end
