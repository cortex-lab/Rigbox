function plot2AUFCwithOri(ax, block)

[block.trial(arrayfun(@(a)isempty(a.orientationLeft), block.trial)).orientationLeft] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.orientationRight), block.trial)).orientationRight] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.contrastLeft), block.trial)).contrastLeft] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.contrastRight), block.trial)).contrastRight] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.response), block.trial)).response] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.repeatNum), block.trial)).repeatNum] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.feedback), block.trial)).feedback] = deal(nan);

ori = [];
ori(1,:) = [block.trial.orientationLeft];
ori(2,:) = [block.trial.orientationRight];

contrast = [];
contrast(1,:) = [block.trial.contrastLeft];
contrast(2,:) = [block.trial.contrastRight];

response = [block.trial.response];
repeatNum = [block.trial.repeatNum];
incl = ~any(isnan([ori;response;repeatNum]));
ori = ori(:,incl);
response = response(incl);
repeatNum = repeatNum(incl);
% if any(structfun(@isnan, block.trial(end))) % strip incomplete trials
%   ori = ori(:,1:end-1);
%   response = response(1:end-1);
%   repeatNum = repeatNum(1:end-1);
% end
respTypes = unique(response);
numRespTypes = numel(respTypes);

if any(contrast(1,:)>0 & contrast(2,:)>0)
    
    % mode for plotting task with two stimuli at once
    oValsLeft = unique(ori(1,:));
    oValsRight = unique(ori(2,:));
    nOL = numel(oValsLeft);
    nOR = numel(oValsRight);
    %     pedVals = cVals(1:end-1);
    %     numPeds = numel(pedVals);
    
    respTypes = unique(response);
    numRespTypes = numel(respTypes);
    numTrials = nan(1, nOL, nOR);
    numChooseR = nan(numRespTypes, nOL, nOR);
    psychoM = nan(numRespTypes, nOL, nOR);
    for r = 1:numRespTypes
        for o1 = 1:nOL
            for o2 = 1:nOR
                incl = repeatNum==1&ori(1,:)==oValsLeft(o1)&ori(2,:) == oValsRight(o2);
                numTrials(1,o1,o2) = sum(incl);
                numChooseR(r,o1,o2) = sum(response==respTypes(r)&incl);
                
                psychoM(r,o1,o2) = numChooseR(r,o1,o2)/numTrials(1,o1,o2);
                %psychoMCI(r, c,las) = 1.96*sqrt(psychoM(r, c,las)*(1-psychoM(r, c,las))/numTrials(1,c,las));
            end
        end
    end
    cla(ax)
    psychoMCmap = reshape(permute(psychoM, [2 1 3]), numRespTypes*nOR, nOL)';
    psychoMCmap(isnan(psychoMCmap))=-1;
    imagesc(ax, psychoMCmap)
    colormap(psy.colormap_pinkgreyscale)
    
    set(ax, 'XTick', 1:nOR*numRespTypes, 'XTickLabel', oValsRight(repmat(1:nOR, [1 numRespTypes])));
    set(ax, 'YTick', 1:nOL, 'YTickLabel', oValsLeft(1:nOL));
    
    for r = 1:numRespTypes-1
        plot(ax, nOR*r+[0.5 0.5], [0.5 nOL+0.5], 'Color', [0.8 0.8 0.8], 'LineWidth', 2.0);
    end
    
    xlim(ax, [0.5 nOR*numRespTypes+0.5])
    ylim(ax, [0.5 nOL+0.5])
    caxis(ax, [-1 1]);
    axis(ax, 'image')
else
    ori = diff(ori, [], 1);
    oVals = unique(ori);
    colors = iff(numRespTypes>2,[0 1 1; 0 1 0; 1 0 0], [0 1 1; 1 0 0]);
    psychoM = zeros(numRespTypes,length(oVals));
    psychoMCI = zeros(numRespTypes,length(oVals));
    numTrials = zeros(1,length(oVals));
    numChooseR = zeros(numRespTypes, length(oVals));
    for r = 1:numRespTypes
        for o = 1:length(oVals)
            incl = repeatNum==1&ori==oVals(o);
            numTrials(o) = sum(incl);
            numChooseR(r,o) = sum(response==respTypes(r)&incl);
            
            psychoM(r, o) = numChooseR(r,o)/numTrials(o);
            psychoMCI(r, o) = 1.96*sqrt(psychoM(r, o)*(1-psychoM(r, o))/numTrials(o));
        end
        errorbar(ax, oVals, 100*psychoM(r,:), 100*psychoMCI(r,:),...
            '-o', 'Color', colors(r,:), 'LineWidth', 1.0);
    end
    
    ylim(ax, [-1 101]);
    xdata = oVals(~isnan(oVals));
    if numel(xdata) > 1
        xlim(ax, xdata([1 end]));
    end
    
end
end
