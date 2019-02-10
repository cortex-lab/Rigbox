disp('Updating queued Alyx posts...')
posts = dirPlus(getOr(dat.paths, 'localAlyxQueue', 'C:/localAlyxQueue'));
posts = posts(endsWith(posts, 'put'));
newPosts = cellfun(@(str)[str(1:end-3) 'patch'], posts, 'uni', 0);
status = cellfun(@movefile, posts, newPosts);
assert(all(status), 'Unable to rename queued Alyx files, please do this manually')