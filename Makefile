.PHONY: test test_postcodes

test: test_postcodes

test_postcodes:
	bundle exec ./postcodes.rb --test

clean:
	rm -rf rblib
	rm -rf configuration.yml