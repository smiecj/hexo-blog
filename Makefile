run:
	hexo g
	hexo server -w -p 31313

deploy:
	hexo clean
	hexo generate
	hexo deploy