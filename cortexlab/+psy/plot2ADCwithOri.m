function plot2ADCwithOri(ax, block)

L = block.numCompletedTrials;
conds = [block.trial.condition];
resp = [block.trial.responseMadeID];
repeatNum = [conds.repeatNum];
contrast = psy.visualContrasts(block.trial);
ori = diff([conds.targetOrientation]);
if size(contrast, 1) > 1
  contrast = diff(contrast, [], 1);
else
  contrast = sign([conds.cueOrientation]).*contrast;
end

cVals = unique(contrast);
oVals = unique(ori);
for c = 1:length(cVals)
    oVals = unique(ori(contrast(1:L)==cVals(c)));
    respTypes = unique(resp(contrast(1:L)==cVals(c)&resp(1:L)>0));
    numRespTypes = numel(respTypes);
    psychoM = zeros(numRespTypes,length(oVals));
    psychoMCI = zeros(numRespTypes,length(cVals));
    numTrials = zeros(1,length(oVals));
    numChooseR = zeros(numRespTypes, length(oVals));
    for r = 1:numRespTypes
        for o = 1:length(oVals)
            incl = repeatNum(1:L)==1&contrast(1:L)==cVals(c)&ori(1:L)==oVals(o);
            numTrials(o) = sum(incl);
            numChooseR(r,o) = sum(resp(1:L)==respTypes(r)&incl);

            psychoM(r, o) = numChooseR(r,o)/numTrials(o);
            psychoMCI(r, o) = 1.96*sqrt(psychoM(r, o)*(1-psychoM(r, o))/numTrials(o));
        end
    end
    
    colors = [0 1 1
          1 0 0
          0 1 0];%hsv(numRespTypes);
% hsv(3)

    for r = 1:numRespTypes

        xdata = oVals;
        ydata = 100*psychoM(r,:);
        errBars = 100*psychoMCI(r,:);
        plot(ax, xdata, ydata, '-o', 'Color', colors(r,:), 'LineWidth', 1.0);
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
    end
end
set(ax,'xtick',-45:22.5:45);
ylim(ax, [-1 101]);
if numel(oVals) > 1
  xlim(ax, [min(oVals)-5 max(oVals)+5]);
%   xlim(ax, [-50 50]);
end
