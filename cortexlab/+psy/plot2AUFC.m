function plot2AUFC(ax, block)
[block.trial(arrayfun(@(a)isempty(a.contrastLeft), block.trial)).contrastLeft] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.contrastRight), block.trial)).contrastRight] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.response), block.trial)).response] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.repeatNum), block.trial)).repeatNum] = deal(nan);
[block.trial(arrayfun(@(a)isempty(a.feedback), block.trial)).feedback] = deal(nan);
contrast = [];
contrast(1,:) = [block.trial.contrastLeft];
contrast(2,:) = [block.trial.contrastRight];
% contrast = diff(contrast);
response = [block.trial.response];
repeatNum = [block.trial.repeatNum];
incl = ~any(isnan([contrast;response;repeatNum]));
contrast = contrast(:,incl);
response = response(incl);
repeatNum = repeatNum(incl);
% if any(structfun(@isnan, block.trial(end))) % strip incomplete trials
%   contrast = contrast(:,1:end-1);
%   response = response(1:end-1);
%   repeatNum = repeatNum(1:end-1);
% end
respTypes = unique(response);
numRespTypes = numel(respTypes);

if any(contrast(1,:)>0 & contrast(2,:)>0)
  
  % mode for plotting task with two stimuli at once
  cValsLeft = unique(contrast(1,:));
  cValsRight = unique(contrast(2,:));
  nCL = numel(cValsLeft);
  nCR = numel(cValsRight);
  %     pedVals = cVals(1:end-1);
  %     numPeds = numel(pedVals);
  
  respTypes = unique(response);
  numRespTypes = numel(respTypes);
  numTrials = nan(1, nCL, nCR);
  numChooseR = nan(numRespTypes, nCL, nCR);
  psychoM = nan(numRespTypes, nCL, nCR);
  for r = 1:numRespTypes
    for c1 = 1:nCL
      for c2 = 1:nCR
        incl = repeatNum==1&contrast(1,:)==cValsLeft(c1)&contrast(2,:) == cValsRight(c2);
        numTrials(1,c1,c2) = sum(incl);
        numChooseR(r,c1,c2) = sum(response==respTypes(r)&incl);
        
        psychoM(r,c1,c2) = numChooseR(r,c1,c2)/numTrials(1,c1,c2);
        %psychoMCI(r, c,las) = 1.96*sqrt(psychoM(r, c,las)*(1-psychoM(r, c,las))/numTrials(1,c,las));
      end
    end
  end
  cla(ax)
  psychoMCmap = reshape(permute(psychoM, [2 1 3]), numRespTypes*nCR, nCL)';
  psychoMCmap(isnan(psychoMCmap))=-1;
  imagesc(ax, psychoMCmap)
  colormap(psy.colormap_pinkgreyscale)
  
  set(ax, 'XTick', 1:nCR*numRespTypes, 'XTickLabel', cValsRight(repmat(1:nCR, [1 numRespTypes])));
  set(ax, 'YTick', 1:nCL, 'YTickLabel', cValsLeft(1:nCL));
  
  for r = 1:numRespTypes-1
    plot(ax, nCR*r+[0.5 0.5], [0.5 nCL+0.5], 'Color', [0.8 0.8 0.8], 'LineWidth', 2.0);
  end
  
  xlim(ax, [0.5 nCR*numRespTypes+0.5])
  ylim(ax, [0.5 nCL+0.5])
  caxis(ax, [-1 1]);
  axis(ax, 'image')
else
  contrast = diff(contrast, [], 1);
  cVals = unique(contrast);
  colors = iff(numRespTypes>2,[0 1 1; 0 1 0; 1 0 1], [0 1 1; 1 0 1]);
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
    errorbar(ax, 100*cVals, 100*psychoM(r,:), 100*psychoMCI(r,:),...
      '-o', 'Color', colors(r,:), 'LineWidth', 1.0);
  end
  
  ylim(ax, [-1 101]);
  xdata = cVals(~isnan(cVals))*100;
  if numel(xdata) > 1
    xlim(ax, xdata([1 end])*1.1);
  end
end
end
