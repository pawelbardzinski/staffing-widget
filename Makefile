BRANCH=$(shell git rev-parse --abbrev-ref HEAD)

deploy:
	pushd CloudCode; parse deploy

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

calabash_iphone:
	DEVICE_TARGET="A0C9E3CB-108E-431D-AE78-1828A2C4960D" cucumber --tags @iphone

calabash_ipad:
	DEVICE_TARGET="24D24ABE-CC74-4989-8300-A19AC6AE5E3B" cucumber --tags @ipad
