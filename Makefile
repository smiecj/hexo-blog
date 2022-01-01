npm_install:
	rm -rf node_modules && npm install --force

run:
	@if [ ! -d "node_modules" ]; then npm install --force; fi
	@if [ ! -d "themes/butterfly" ]; then git submodule update --init --recursive; fi
	hexo clean
	hexo g
	hexo server -w -p 31313

deploy:
	hexo clean
	hexo generate
	hexo deploy