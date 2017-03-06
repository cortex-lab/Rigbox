function plot2ADCwithAlt(ax, block)

numCompletedTrials = block.numCompletedTrials;
contrast = zeros(1,numCompletedTrials);
resp = zeros(1,numCompletedTrials);
repeatNum = zeros(1,numCompletedTrials);

conds = [block.trial.condition];
resp = [block.trial.responseMadeID];
repeatNum = [conds.repeatNum];
contrast = psy.visualContrasts(block.trial);
if size(contrast, 1) > 1
  contrast = diff(contrast, [], 1);
else
  contrast = sign([conds.cueOrientation]).*contrast;
end

if isfield(conds, 'targetAltitude')
    useAlt = true;
    lowAltTrials = [conds.targetAltitude]==min([conds.targetAltitude]);
    highAltTrials = [conds.targetAltitude]>min([conds.targetAltitude]);
    
else
    useAlt = false;
end

% for t = 1:block.numCompletedTrials
%     
%     if block.trial(t).condition.visCueContrast(1)>0
%         contrast(t) = -block.trial(t).condition.visCueContrast(1);
%     elseif block.trial(t).condition.visCueContrast(2)>0
%         contrast(t) = block.trial(t).condition.visCueContrast(2);
%     else
%         contrast(t) = 0;
%     end
%     
%     if isfield(conds, 'cueOrientation')
%       contrast(t) = -sign(block.trial(t).condition.cueOrientation)*contrast(t);
%     end
%     
% %     resp(t) = block.trial(t).responseMadeID;
%     repeatNum(t) = block.trial(t).condition.repeatNum;    
% 
% end

respTypes = unique(resp(resp>0));
numRespTypes = numel(respTypes);

cVals = unique(contrast);

if useAlt
    % count zero contrast trials for both high and low
    lowAltTrials(contrast==0) = true;
    highAltTrials(contrast==0) = true; 
end

psychoM = zeros(numRespTypes,length(cVals));
psychoMCI = zeros(numRespTypes,length(cVals));
numTrials = zeros(1,length(cVals));
numChooseR = zeros(numRespTypes, length(cVals));
for r = 1:numRespTypes
    for c = 1:length(cVals)
        
        if ~useAlt
            incl = repeatNum==1&contrast==cVals(c);
            numTrials(c) = sum(incl);
            numChooseR(r,c) = sum(resp==respTypes(r)&incl);

            psychoM(r, c) = numChooseR(r,c)/numTrials(c);
            psychoMCI(r, c) = 1.96*sqrt(psychoM(r, c)*(1-psychoM(r, c))/numTrials(c));

        else
            incl = repeatNum==1&contrast==cVals(c)&lowAltTrials;
            numTrials(1,c,1) = sum(incl);
            numChooseR(r,c,1) = sum(resp==respTypes(r)&incl);
            
            psychoM(r, c,1) = numChooseR(r,c,1)/numTrials(1,c,1);
            psychoMCI(r, c,1) = 1.96*sqrt(psychoM(r, c,1)*(1-psychoM(r, c,1))/numTrials(1,c,1));
            
            incl = repeatNum==1&contrast==cVals(c)&highAltTrials;
            numTrials(1,c,2) = sum(incl);
            numChooseR(r,c,2) = sum(resp==respTypes(r)&incl);
            
            psychoM(r, c,2) = numChooseR(r,c,2)/numTrials(1,c,2);
            psychoMCI(r, c,2) = 1.96*sqrt(psychoM(r, c,2)*(1-psychoM(r, c,2))/numTrials(1,c,2));
        end
    end
end

% colors = [0 1 1
%           1 0 0
%           0 1 0];%hsv(numRespTypes);
% hsv(3)

colors(1,:) = [0 0.5 1];
colors(2,:) = [1 0.5 0];
colors(3,:) = [0.2 0.2 0.2];

for r = 1:numRespTypes
    
    xdata = 100*cVals;
    
    if ~useAlt
        ydata = 100*psychoM(r,:);
        errBars = 100*psychoMCI(r,:);

        plot(ax, xdata, ydata, '-o', 'Color', colors(r,:), 'LineWidth', 2.0);
        plot(ax, xdata, ydata+errBars, ':', 'Color', colors(r,:), 'LineWidth', 1.0);
        plot(ax, xdata, ydata-errBars, ':', 'Color', colors(r,:), 'LineWidth', 1.0);
    
    else
        ydata = 100*psychoM(r,:,1);
        errBars = 100*psychoMCI(r,:,1);
        plot(ax, xdata, ydata, '-o', 'Color', colors(r,:), 'LineWidth', 2.0);
%         plot(ax, xdata, ydata+errBars, ':', 'Color', colors(r,:), 'LineWidth', 1.0);
%         plot(ax, xdata, ydata-errBars, ':', 'Color', colors(r,:), 'LineWidth', 1.0);
        
        ydata = 100*psychoM(r,:,2);
        errBars = 100*psychoMCI(r,:,2);
        plot(ax, xdata, ydata, ':o', 'Color', colors(r,:), 'LineWidth', 2.0);
%         plot(ax, xdata, ydata+errBars, ':', 'Color', colors(r,:)/2, 'LineWidth', 1.0);
%         plot(ax, xdata, ydata-errBars, ':', 'Color', colors(r,:)/2, 'LineWidth', 1.0);
    end
        
    % set all NaN values to 0 so the fill function can proceed just
    % skipping over those points. 
    ydata(isnan(ydata)) = 0;
    errBars(isnan(errBars)) = 0;
    
    %TODO:update to use plt.hshade
%     fillhandle = fill([xdata xdata(end:-1:1)],...
%       [ydata+errBars ydata(end:-1:1)-errBars(end:-1:1)], colors(r,:),...
%       'Parent', ax);
%     set(fillhandle, 'FaceAlpha', 0.15, 'EdgeAlpha', 0);
    %,...
      
    
%     hold on;

    
end
ylim(ax, [-1 101]);
if numel(xdata) > 1
  xlim(ax, xdata([1 end])*1.1);
end
