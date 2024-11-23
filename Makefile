setup:
	bundle config set path 'vendor/bundle' && bundle install

run:
	bundle exec ruby init.rb

build/doc:
	npx @redocly/cli build-docs -o index.html api.yaml

