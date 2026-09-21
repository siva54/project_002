# GNU Make; native Windows uses the Python launcher, macOS/Linux use python3.
ifeq ($(OS),Windows_NT)
PYTHON ?= py -3
else
PYTHON ?= python3
endif
GODOT ?=
ARGS ?=
.DEFAULT_GOAL := help
.NOTPARALLEL:
.PHONY: help doctor play editor import check test smoke

help:
	@$(PYTHON) -c "print('make play | editor | check | test | smoke | import | doctor\nOverrides: GODOT=executable PYTHON=python-command ARGS=extra-arguments')"

doctor play editor import:
	@$(PYTHON) tools/project.py --godot "$(GODOT)" $@ $(ARGS)

test: check

check smoke:
	@$(PYTHON) tools/project.py --godot "$(GODOT)" $@ $(ARGS)
