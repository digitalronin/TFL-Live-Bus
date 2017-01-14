server:
	bundle exec shotgun config.ru -p 4567

deploy:
	git push heroku master
