npm_install:
	rm -rf node_modules && npm install --force

run:
	hexo clean
	hexo g
	hexo server -w -p 31313

deploy:
	hexo clean
	hexo generate
	hexo deploy