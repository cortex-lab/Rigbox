function learned = isLearned(ref)
learned = false;
subject = dat.parseExpRef(ref);
expRef = dat.listExps(subject);
j = 1;
pooledCont = [];
pooledIncl = [];
pooledChoice = [];
for i = length(expRef)-1:-1:1
  p = dat.expFilePath(expRef{i}, 'block', 'master');
  if exist(p,'file')==2
    % Block doesn't exist
    p = fileparts(p);
  else
    fprintf('No block file for session %s: skipping\n', expRef{i})
    continue
  end
  try
    % If trial side prob uneven, the subject must have learned
    probabilityLeft = readNPY(fullfile(p,'_ibl_trials.probabilityLeft.npy'));
    if any(probabilityLeft~=0.5)
      fprintf('Asymmetric trials already introduced\n')
      learned = true;
      return
    end
    feedback = readNPY(fullfile(p,'_ibl_trials.feedbackType.npy'));
    contrastLeft = readNPY(fullfile(p,'_ibl_trials.contrastLeft.npy'));
    contrastRight = readNPY(fullfile(p,'_ibl_trials.contrastRight.npy'));
    incl = readNPY(fullfile(p,'_ibl_trials.included.npy'));
    choice = readNPY(fullfile(p,'_ibl_trials.choice.npy'));
  catch
    warning('isLearned:ALFLoad:MissingFiles', ...
      'Unable to load files for session %s', expRef{i})
    continue
  end
  % If there are fewer than 4 contrasts, subject can't have learned
  contrast = diff([contrastLeft,contrastRight],[],2);
  if ~any(contrast==0)
    fprintf('Low contrasts not yet introduced\n')
    return
  end
  perfOnEasy = sum(feedback==1 & abs(contrast > 0.25)) / sum(abs(contrast > 0.25));
  if length(feedback) > 200 && perfOnEasy > 0.8
    pooledCont = [pooledCont; contrast];
    pooledIncl = [pooledIncl; incl];
    pooledChoice = [pooledChoice; choice];
    if j < 3
      j = j+1;
    else
      % All three sessions meet criteria
      contrastSet = unique(pooledCont);
      nn = arrayfun(@(c)sum(pooledCont==c & pooledIncl), contrastSet);
      pp = arrayfun(@(c)sum(pooledCont==c & pooledIncl & pooledChoice==-1), contrastSet)./nn;
      pars = psy.mle_fit_psycho([contrastSet';nn';pp'], 'erf_psycho',...
        [mean(contrastSet), 3, 0.05],...
        [min(contrastSet), 10, 0],...
        [max(contrastSet), 30, 0.4]);
      if abs(pars(1)) < 16 && pars(2) < 19 && pars(3) < 0.2
        learned = true;
      else
        fprintf('Fit parameter values below threshold\n')
        return
      end
    end
  else
    fprintf('Low trial count or performance at high contrast\n')
    return
  end
end
end