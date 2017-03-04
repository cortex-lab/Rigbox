
function [expNums, blocks, hasBlock, pars, isMpep, tl, hasTimeline] = ...
    whichExpNums(mouseName, thisDate)


rootExp = dat.expFilePath(mouseName, thisDate, 1, 'Timeline', 'master');
expInf = fileparts(fileparts(rootExp));

d = dir(fullfile(expInf, '*'));
expNums = cell2mat(cellfun(@str2num, {d(3:end).name}, 'uni', false));

%% for each expNum, determine what type it is 

hasBlock = false(size(expNums));
isMpep = false(size(expNums));
hasTimeline = false(size(expNums));

for e = 1:length(expNums)
    % if block, load block and get stimWindowUpdateTimes
    dBlock = dat.expFilePath(mouseName, thisDate, expNums(e), 'block', 'master');
    if exist(dBlock)
        fprintf(1, 'expNum %d has block\n', e);
        load(dBlock)
        blocks{e} = block;
        hasBlock(e) = true;
    end

    dPars = dat.expFilePath(mouseName, thisDate, expNums(e), 'parameters', 'master');
    if exist(dPars)
        load(dPars)
        pars{e} = parameters;
        if isfield(parameters, 'Protocol')
            isMpep(e) = true;
            fprintf(1, 'expNum %d is mpep\n', e);
        end        
    end
        

    % if there is a timeline, load it and get photodiode events, mpep UDP
    % events.
    dTL = dat.expFilePath(mouseName, thisDate, expNums(e), 'Timeline', 'master');
    if exist(dTL)
        fprintf(1, 'expNum %d has timeline\n', e);        
        load(dTL)
        tl{e} = Timeline;      
        hasTimeline(e) = true;        
    end    
end