setup:
	bundle install
	npm install -g @redocly/cli

run:
	ruby init.rb

build/doc:
	redocly build-docs -o ./doc/api.html api.yaml

