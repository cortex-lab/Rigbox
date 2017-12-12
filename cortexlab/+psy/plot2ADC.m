function plot2ADC(ax, block)

numCompletedTrials = block.numCompletedTrials;
contrast = zeros(1,numCompletedTrials);
resp = zeros(1,numCompletedTrials);
repeatNum = zeros(1,numCompletedTrials);
rewardOnStim = zeros(1,numCompletedTrials);

trials = [block.trial]; trials = trials(1:numCompletedTrials);

conds = [trials.condition];
resp = [trials.responseMadeID];
repeatNum = [conds.repeatNum];
contrast = psy.visualContrasts(trials);

if isfield(conds, 'rewardOnStimulus')
    rewardOnStim = [conds.rewardOnStimulus];
    laserPower = rewardOnStim(2,:)-rewardOnStim(1,:);
    laserVals = unique(laserPower);
    numLaserConds = length(laserVals);
else
    laserPower = zeros(1,numCompletedTrials);
    laserVals = 0;
    numLaserConds = 1;
end


if size(contrast, 1) > 1
  allContrast = contrast;
  contrast = diff(contrast, [], 1);
else
  contrast = sign([conds.cueOrientation]).*contrast;
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
if any(allContrast(1,:)>0 & allContrast(2,:)>0)
    
    % mode for plotting task with two stimuli at once
    cValsLeft = unique(allContrast(1,:));
    cValsRight = unique(allContrast(2,:));
    nCL = numel(cValsLeft);
    nCR = numel(cValsRight);
%     pedVals = cVals(1:end-1);
%     numPeds = numel(pedVals);
    
    respTypes = unique(resp(resp>0));
    numRespTypes = numel(respTypes);
    
    psychoM = NaN(numRespTypes,nCL, nCR);
    for r = 1:numRespTypes
        for c1 = 1:nCL            
            for c2 = 1:nCR
                incl = repeatNum==1&allContrast(1,:)==cValsLeft(c1)&allContrast(2,:) == cValsRight(c2);
                numTrials(1,c1,c2) = sum(incl);
                numChooseR(r,c1,c2) = sum(resp==respTypes(r)&incl);

                psychoM(r, c2,c1) = numChooseR(r,c1,c2)/numTrials(1,c1,c2);
                %psychoMCI(r, c,las) = 1.96*sqrt(psychoM(r, c,las)*(1-psychoM(r, c,las))/numTrials(1,c,las));
            end
        end
    end
    
    psychoMCmap = reshape(permute(psychoM, [2 1 3]), numRespTypes*nCR, nCL)';
    psychoMCmap(isnan(psychoMCmap))=-1;
    imagesc(psychoMCmap, 'Parent', ax)
    colormap(colormap_pinkgreyscale)
    
    set(ax, 'XTick', 1:nCR*numRespTypes, 'XTickLabel', cValsRight(repmat(1:nCR, [1 numRespTypes])));
    set(ax, 'YTick', 1:nCL, 'YTickLabel', cValsLeft(1:nCL));
    
    for r = 1:numRespTypes-1
        plot(ax, nCR*r+[0.5 0.5], [0.5 nCL+0.5], 'g', 'LineWidth', 2.0);
        
    end
    
    xlim(ax, [0.5 nCR*numRespTypes+0.5])
    ylim(ax, [0.5 nCL+0.5])
    caxis(ax, [-1 1]);
    axis(ax, 'image');
    hold(ax, 'on');
    
else
    
    % mode for plotting task with just one stimulus at a time
    
    respTypes = unique(resp(resp>0));
    numRespTypes = numel(respTypes);

    cVals = unique(contrast);

    psychoM = zeros(numRespTypes,length(cVals), numLaserConds);
    psychoMCI = zeros(numRespTypes,length(cVals), numLaserConds);
    numTrials = zeros(1,length(cVals), numLaserConds);
    numChooseR = zeros(numRespTypes, length(cVals), numLaserConds);
    for r = 1:numRespTypes
        for c = 1:length(cVals)
            for las = 1:numLaserConds
                incl = repeatNum==1&contrast==cVals(c)&laserPower == laserVals(las);
                numTrials(1,c,las) = sum(incl);
                numChooseR(r,c,las) = sum(resp==respTypes(r)&incl);

                psychoM(r, c,las) = numChooseR(r,c,las)/numTrials(1,c,las);
                psychoMCI(r, c,las) = 1.96*sqrt(psychoM(r, c,las)*(1-psychoM(r, c,las))/numTrials(1,c,las));
            end
        end
    end

    colors(1,:) = [0 0.5 1];
    colors(2,:) = [1 0.5 0];
    colors(3,:) = [0.2 0.2 0.2];

    for r = 1:numRespTypes

        xdata = 100*cVals;
        ydata = 100*psychoM(r,:,1);
    %     errBars = 100*psychoMCI(r,:);

        plot(ax, xdata, ydata, 'o--', 'Color', colors(r,:), 'LineWidth',2.0); %hold on;

        if numLaserConds>1
            ydata = 100*psychoM(r,:,2);
            plot(ax, xdata, ydata, '.-', 'Color', colors(r,:), 'LineWidth', 2.0);
        end
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
    if numel(xdata) > 1
      xlim(ax, xdata([1 end])*1.1);
    end
end