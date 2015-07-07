BRANCH=$(shell git rev-parse --abbrev-ref HEAD)

merge_request:
	open https://www.assembla.com/code/staffing-widget/git/compare/develop...$(BRANCH)

update_branch:
	git checkout develop
	git pull
	git checkout $(BRANCH)
	git merge develop

rebase_branch:
	git checkout develop
	git pull
	git checkout $(BRANCH)
	git rebase develop
