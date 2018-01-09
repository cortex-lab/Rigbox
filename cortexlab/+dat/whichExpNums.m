function [expNums, blocks, hasBlock, pars, isMpep, tl, hasTimeline] = ...
    whichExpNums(mouseName, thisDate)
% [expNums, blocks, hasBlock, pars, isMpep, tl, hasTimeline] = ...
%     whichExpNums(mouseName, thisDate)
%
% Attempt to automatically determine what experiments of what types were
% run for a subject on a given date. 
%
% Returns:
% - expNums - list of the experiment numbers that exist
% - blocks - cell array of the Block structs
% - hasBlock - boolean array indicating whether each experiment had a block
% - pars - cell array of parameters structs
% - isMpep - boolean array of whether the experiment was mpep type
% - tl - cell array of Timeline structs
% - hasTimeline - boolean array of whether timeline was present for each
% experiment
%
% Created by NS 2017

rootExp = dat.expFilePath(mouseName, thisDate, 1, 'Timeline', 'master');
expInf = fileparts(fileparts(rootExp));

d = dir(fullfile(expInf, '*'));
expNums = cell2mat(cellfun(@str2num, {d(3:end).name}, 'uni', false));

%% for each expNum, determine what type it is 

hasBlock = false(size(expNums));
isMpep = false(size(expNums));
hasTimeline = false(size(expNums));

blocks = {}; pars = {}; tl = {};

for e = 1:length(expNums)
    % if block, load block and get stimWindowUpdateTimes
    dBlock = dat.expFilePath(mouseName, thisDate, expNums(e), 'block', 'master');
    if exist(dBlock)
        fprintf(1, 'expNum %d has block\n', e);
        load(dBlock)
        blocks{e} = block;
        hasBlock(e) = true;
    end

    % if there is a parameters file, load it and determine whether it is
    % mpep type
    dPars = dat.expFilePath(mouseName, thisDate, expNums(e), 'parameters', 'master');
    if exist(dPars)
        load(dPars)
        pars{e} = parameters;
        if isfield(parameters, 'Protocol')
            isMpep(e) = true;
            fprintf(1, 'expNum %d is mpep\n', e);
        end        
    end
        

    % if there is a timeline, load it 
    dTL = dat.expFilePath(mouseName, thisDate, expNums(e), 'Timeline', 'master');
    if exist(dTL)
        fprintf(1, 'expNum %d has timeline\n', e);        
        load(dTL)
        tl{e} = Timeline;      
        hasTimeline(e) = true;        
    end    
end