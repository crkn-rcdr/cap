# History

This repository contains files previously managed in Canadiana's private subversion repository. The following command was used to clone the repository:

````
git svn clone --trunk=cap/trunk --tags=cap/tags --branches=cap/branches --authors-file=/data/svn/authors.txt --no-metadata file:///data/svn/c7a cap
cd cap
git remote add origin git@github.com:crkn-rcdr/cap.git
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch CAP/conf/mysql/cap_content.sql' --prune-empty --tag-name-filter cat -- --all
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch CAP/conf/mysql/cap_content.sql.gz' --prune-empty --tag-name-filter cat -- --all
git push -u origin master
git show-ref | grep refs/remotes | grep -v '@' | grep -v refs/original/ | grep -v remotes/origin/tags | perl -ne 'print "refs/remotes/origin/$1:refs/heads/origin/$1 " if m!refs/remotes/origin/(.*)!' | xargs git push origin
````

We decided not to push historical tags, only the branches.

The cap_content.sql* file was removed as it was too large for GitHub, but also not a relevant file to keep in the repository.  It is still archived in subversion, if for any reason we wanted to look at it.
