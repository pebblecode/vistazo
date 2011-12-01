web: bundle exec thin -R config.ru start -p $PORT -e $RACK_ENV

# For development purposes, not used by heroku
dev: bundle exec shotgun --server=thin config.ru -p 6100