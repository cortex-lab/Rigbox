function psychDat = an(subject, dates, dateRange)
% plots the psychometic data from the blocks entered.
%  
% allBlocks         Block structure or cell array of structs
% figDestination    String; Path where fig is to be saved or 'none'
%
% psychoDat         Struct containing expRef, contrasts, response made,
%                   feedback, repeat numbers and response times

%% Initialize & collect data
% if isa(allBlocks, 'struct')
%     allBlocks = {allBlocks};
% elseif ~isa(allBlocks, 'struct')&&~isa(allBlocks, 'cell')
%     error('allBlocks must be a single block structure or a cell array of blocks');
% end
%% 
if nargin < 1
    error('Error in plotting psychometric: Must specify at least the subject');
end
if nargin < 2
   dates = 'last';
end
if nargin < 3
   dateRange = true;
end

% if nargin < 6
%    makeFig = false;
% end    
% define path to save figure
% if makeFig 
%     figDestination = ['\\zserver.cortexlab.net\Data\behavior\ChoiceWorld\' subject '\'];
% else
%     figDestination = 'none';
% end

% get list of references and dates for subject
[expRef, expDate] = dat.listExps(subject);

% convert the date(s) to vector of datenums
if ~isa(dates,'numeric')&&~isa(dates,'cell')
    switch lower(dates(1:3))
      case 'las' % last x sessions
          if numel(dates)>4; dates = expDate(end-str2double(dates(5:end))+1:end);
          else; dates = expDate(end);
          end
      case 'tod'; dates = floor(now); % today
      case 'yes'; dates = floor(now)-1; % yesterday
      case 'all'; dates = expDate; % all sessions
      otherwise, dates = sort(datenum(dates)); % specific date
    end
elseif isa(dates,'cell')
    dates = sort(datenum(dates));
end

% get date nums between specified range
if numel(dates)==2&&dateRange==1
    dates = sort(dates);
    dates = dates(1):dates(2);
end
if size(dates,2)>size(dates,1)
    dates = dates';
end

% find paths to existing block files
idx = cell2mat(arrayfun(@(x)find(expDate==x), dates, 'UniformOutput',0));
filelist = mapToCell(@(r) dat.expFilePath(r, 'block', 'master'),expRef(idx));
existfiles = cell2mat(mapToCell(@(l) file.exists(l), filelist));

% useful info about analysis
figDestination = 'none';

% load block files 
allBlocks = cellfun(@load,filelist(existfiles));
if isempty(allBlocks)
    disp('No blocks to process');
    return
end

%%
% Make sure expDef is consistant across blocks
expDef = arrayfun(@(b){b.block.expDef},allBlocks);
if ~all(strcmp(expDef{1},expDef))
    warning('Not all blocks the same experiment definition');
    return
end
[~, expDef] = fileparts(expDef{1});
% Extract events and paramsValues structures from blocks.  NB: putting into
% cell array here as some blocks may have a different set of field names.  
% Can later cat with catStructs
events = arrayfun(@(b){b.block.events},allBlocks); 
paramVals = arrayfun(@(b){b.block.paramsValues},allBlocks);
numCompletedTrials = cellfun(@(S) {length(S.responseValues)}, events);

% remove incomplete trials
events = cellfun(@(e,n) removeIncompleteTrials(e,n), events, numCompletedTrials, 'UniformOutput', 0);
paramVals = cellfun(@(S,n) S(1:n), paramVals, numCompletedTrials, 'UniformOutput', 0);

% % remove last n trials
% nRemoved = 10;
% [events, trim] = cellfun(@(e,n) trimTrials(e,nRemoved,n), events, numCompletedTrials, 'UniformOutput', 0);
% paramVals = cellfun(@(S,n) S(1:n), paramVals, trim, 'UniformOutput', 0);

paramVals = catStructs(paramVals);
events = catStructs(events);
% events = iff(all(class(events)=='cell'), catStructs(events), events);
resp = [events.responseValues];
trialEndTimes = [events.endTrialTimes];
numCompletedTrials = sum(cell2mat(numCompletedTrials));
if strcmp(expDef, 'vanillaChoiceworld')
    rt = [events.responseTimes]-[events.interactiveOnTimes];
    contrast = [events.trialContrastValues].*[events.trialSideValues];
    correct = [events.hitValues];
    leftResp = events.trialSideValues==-1&correct==1;
    resp = double(resp);
    resp(leftResp(1:numCompletedTrials)) = -1;
    inc = ~events.repeatTrialValues;
    respWindow = Inf;
    repeatNum = [events.missValues];
elseif strcmp(expDef, 'advancedChoiceWorld')
    correct = events.feedback;
    rt = [events.responseTimes]-[events.stimulusOnTimes]-[paramVals.interactiveDelay];
    contrast = [paramVals.targetContrast];
    inc = events.repeatNumValues == 1;
    respWindow = [paramVals.responseWindow];
    repeatNum = [events.repeatNum];
end

expRef = arrayfun(@(b){b.block.expRef},allBlocks); 


if numCompletedTrials == 0
    psychDat = struct(...
        'expRef',{''},...
        'subject','',...
        'orientation','',...
        'contrast',[],...
        'resp',[],...
        'repeatNum',[],...
        'rt',[],...
        'rewardSize',[],...
        'adapterContrast', []);
    return
else
    psychDat.expRef = expRef;
    psychDat.subject = subject;
    psychDat.contrast = contrast;
    psychDat.resp = resp;
    psychDat.rt = rt;
end

if isempty(figDestination); return; end

%% Some processing
respTypes = unique(resp);
numRespTypes = numel(respTypes);
cDiff = iff(size(contrast,1)==2, diff(contrast, 1, 1), contrast);
cVals = unique(cDiff);
perf = sum(sign(cDiff)==resp&inc)/sum(inc)*100;
psychoM = zeros(numRespTypes,length(cVals));
psychoMCI = zeros(numRespTypes,length(cVals));
meanRTs = zeros(numRespTypes,length(cVals));
meanRTsCIlow = zeros(numRespTypes,length(cVals));
meanRTsCIup = zeros(numRespTypes,length(cVals));
numTrials = zeros(1,length(cVals));
numChooseR = zeros(numRespTypes, length(cVals));
for r = 1:numRespTypes
    for c = 1:length(cVals) %For the number of unique contrasts
        incl = inc&cDiff==cVals(c); %Logical array of trials that aren't repeats of each contrast
        numTrials(c) = sum(incl); %Number of trails is equal to number of non-repeat trials
        numChooseR(r,c) = sum(resp==respTypes(r)&incl);

        psychoM(r, c) = numChooseR(r,c)/numTrials(c);
        psychoMCI(r, c) = 1.96*sqrt(psychoM(r, c)*(1-psychoM(r, c))/numTrials(c));
        
        q = quantile(rt(resp==respTypes(r)&incl), 3);
        meanRTs(r, c) = q(2);
        meanRTsCIlow(r, c) = q(2)-q(1);
        meanRTsCIup(r, c) = q(3)-q(2);
    end
end

%% Colours
if numRespTypes > 2
    colors(1,:) = [0.9290    0.6940    0.1250]; % Yellow (Stim on left, turns right - correct resp)
    colors(3,:) = [0.4940    0.1840    0.5560]; % Magenta (Stim on right, turns left - correct resp)
    colors(2,:) = [0.4660    0.6740    0.1880];
else
    colors(1,:) = [0.9290    0.6940    0.1250]; % Yellow (Stim on left, turns right - correct resp)
    colors(2,:) = [0.4940    0.1840    0.5560]; % Magenta (Stim on right, turns left - correct resp)
end

%% Plotting
expRefMod = allBlocks(1).block.expRef; expRefMod(expRefMod=='_') = '-';
f(1) = figure('Name', expRefMod, 'NumberTitle', 'Off');
datacursormode  on;
dcm_obj = datacursormode(f(1));
set(dcm_obj,'UpdateFcn',{@dispTrialN,[cVals; numTrials], {meanRTs, psychoM, cVals}})
trialNumber = 1:numCompletedTrials; % for reation time plot x-axis

for i = 1:numRespTypes
    r = respTypes(i);
    subplot(3,1,1);
    plotWithErr(cVals, psychoM(i,:), psychoMCI(i,:), colors(i,:)); hold on
    plot(cVals, psychoM(i,:), 'ko');
    
    % Reation time plot
    subplot(3,1,2);
    plot(trialNumber(inc&resp==r&sign(cDiff)==-1), rt(inc&resp==r&sign(cDiff)==-1),'<', 'MarkerEdgeColor', colors(i,:))
    hold on;
    plot(trialNumber(inc&resp==r&sign(cDiff)==1), rt(inc&resp==r&sign(cDiff)==1),'>', 'MarkerEdgeColor', colors(i,:))
    plot(trialNumber(inc&resp==r&sign(cDiff)==0), rt(inc&resp==r&sign(cDiff)==0),'^', 'MarkerEdgeColor', colors(i,:))
    xlabel('trial number');
    ylabel('response time (sec)');
end

subplot(3,1,1);
%     legend({'Left' 'Right'}, 'Location', 'EastOutside');
plot([cVals(1) cVals(end)], [0.5 0.5], 'k:');
ylim([0 1]);
xlim([cVals(1) cVals(end)]*1.1);
xlabel('contrast');
ylabel('proportion choose R');
title([expRefMod ', numTrials = ' num2str(numCompletedTrials) ', perf = ' num2str(perf,3) '%']);

subplot(3,1,2);
if length(respWindow > 1); respWindow = mean(respWindow); end %#ok<ISMT>
plot([1 numCompletedTrials], [respWindow respWindow], 'k:');
if max(rt > 10)
    ylim([0 10]);
else
    ylim([0 max(rt)+((max(rt)/100)*10)]);
end
xlim([1 numCompletedTrials]);

subplot(3,1,3);
slidingPerf = perfSlidingWindow(20, correct);

trialEndTimes = trialEndTimes./60;
xMax = max(trialEndTimes) + 0.2;

plot([0 xMax], [60 60], 'c:');
hold on
plot([0 xMax], [75 75], 'c:');
sw = plot(trialEndTimes, slidingPerf,'k');
drawnow
repeatColour = zeros(4,length(correct));
repeatColour(1,:) = repeatNum*(255/10);
repeatColour(repeatColour==(255/10)) = 0;
repeatColour(4,:) = ones(1,length(correct));
repeatColour(1,:) = (repeatNum>1)*255;
set(sw.Edge, 'ColorBinding', 'interpolated', 'ColorData', uint8(repeatColour));
hold off
xlim([0 xMax]);
ylim([40 100]);
xlabel('Time in minutes');
ylabel({'Performance (%)'; 'incl. repeats'});


%% Save Plots
figName = fullfile(figDestination, [allBlocks(1).block.expRef '_psychometric']);
type = 'png';
if ~any(strcmp(figDestination, {'none' ''}))
    if ~exist(figDestination, 'dir')
        mkdir(figDestination);
    end
    
    switch type
        case 'fig'
            savefig(f,[figName '.fig']);
        case {'jpg' 'png' 'jpeg'}
            if numel(f)>1
                for i = 1:length(f)
                    saveSameSize(f(i),'file',[figName '(' num2str(i) ')'],'format',type)
                end
            else
                saveSameSize(f,'file',figName,'format',type)
            end
        otherwise
            error('Format not supported.  Figure not saved.');
    end
end

%% Helper functions
function S = removeIncompleteTrials(S, completedTrials)
    lengths = structfun(@length, S);
    names = fieldnames(S);
    names = names(lengths == completedTrials+1);
    s = cellfun(@(x) x(1:completedTrials), pick(S, names), 'UniformOutput', 0);
    for n = 1:length(s)
        S.(names{n}) = s{n};
    end
end

function output_txt = dispTrialN(~, event_obj, trialNums, rtData)
% Display the position of the data cursor as date string
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).

meanRTs = rtData{1};
psychM = rtData{2};
cVals = rtData{3};
pos = get(event_obj,'Position');
m = psychM(:,pos(1)==cVals); % perf for all resp at selected cont 
rt = round(meanRTs(m==pos(2),pos(1)==cVals),2);
rt = rt(~isnan(rt));
h = gca;
axis_title = h.Title.String;
output_txt = {['X: ' num2str(pos(1))], ['Y: ' num2str(pos(2))]};

if ~isempty(axis_title)
  output_txt{end+1} = ['n: ' num2str(trialNums(2,trialNums(1,:)==pos(1)))];
  if ~isempty(rt)
    output_txt{end+1} = ['mean rt: '...
        strjoin(arrayfun(@(x) num2str(x),rt,'UniformOutput',false),', ') 's'];
  end
end
end

function [slidingPerf] = perfSlidingWindow(windowWidth, correct)
    % create sliding window over which calculate performance per time point
    %  window_width = 20; %length of the sliding window, uncomment to change
    %  within function rather than script
    nTrials = length(correct);

    % initialize and start at 0 if first trial wrong and 100 if first trial correct
    slidingPerf = ones(1, nTrials)*correct(1)*100;

    for n = 2:windowWidth
        slidingPerf(n) = ((sum(correct(1:n)))./n).*100;
    end
    for n = (windowWidth+1):nTrials
        slidingPerf(n) = ((sum(correct(n-windowWidth:n)))./windowWidth).*100;
    end
end

end