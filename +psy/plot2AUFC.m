function plot2AUFC(ax, block)

% numCompletedTrials = block.numCompletedTrials;

[block.trial(arrayfun(@(a)isempty(a.contrast), block.trial)).contrast] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.response), block.trial)).response] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.repeatNum), block.trial)).repeatNum] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.feedback), block.trial)).feedback] = deal(nan);
contrast = [block.trial.contrast];
response = [block.trial.response];
repeatNum = [block.trial.repeatNum];
% feedback = [block.trial.feedback];
if any(structfun(@isempty, block.trial(end))) % strip incomplete trials
    contrast = contrast(1:end-1);
    response = response(1:end-1);
    repeatNum = repeatNum(1:end-1);
end
respTypes = unique(response);
numRespTypes = numel(respTypes);

cVals = unique(contrast);

psychoM = zeros(numRespTypes,length(cVals));
psychoMCI = zeros(numRespTypes,length(cVals));
numTrials = zeros(1,length(cVals));
numChooseR = zeros(numRespTypes, length(cVals));
for r = 1:numRespTypes
    for c = 1:length(cVals)
        incl = repeatNum==1&contrast==cVals(c);
        numTrials(c) = sum(incl);
        numChooseR(r,c) = sum(response==respTypes(r)&incl);
        
        psychoM(r, c) = numChooseR(r,c)/numTrials(c);
        psychoMCI(r, c) = 1.96*sqrt(psychoM(r, c)*(1-psychoM(r, c))/numTrials(c));
        
    end
end

colors = [0 1 1
          1 0 0
          0 1 0];%hsv(numRespTypes);
% hsv(3)

for r = 1:numRespTypes
    
    xdata = 100*cVals;
    ydata = 100*psychoM(r,:);
%     errBars = 100*psychoMCI(r,:);
    
    plot(ax, xdata, ydata, '-o', 'Color', colors(r,:), 'LineWidth', 1.0);
    
    % set all NaN values to 0 so the fill function can proceed just
    % skipping over those points. 
%     ydata(isnan(ydata)) = 0;
%     errBars(isnan(errBars)) = 0;
    
    %TODO:update to use plt.hshade
%     fillhandle = fill([xdata xdata(end:-1:1)],...
%       [ydata+errBars ydata(end:-1:1)-errBars(end:-1:1)], colors(r,:),...
%       'Parent', ax);
%     set(fillhandle, 'FaceAlpha', 0.15, 'EdgeAlpha', 0);
    %,...
      
    
%     hold on;

    
end
ylim(ax, [-1 101]);
xdata = xdata(~isnan(xdata));
if numel(xdata) > 1
  xlim(ax, xdata([1 end])*1.1);
end