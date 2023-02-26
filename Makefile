# Add logic to tasks.py. This file is only for ease of running when using IDEs and editors

BUILDDIR = build

init:
	invoke init

plan:
	invoke plan

apply:
	invoke apply

destroy-plan:
	invoke destroy

destroy:
	invoke destroy --no-dryrun

output:
	invoke output

lock-provider:
	invoke lock-provider

clean:
	rm -rf build terraform/.terraform

$(BUILDDIR):
	mkdir $(BUILDDIR)
