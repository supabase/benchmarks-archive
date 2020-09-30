REPO_DIR=$(shell pwd)

help:

	@echo "\nDATABASE\n"
	@echo "make migrations.new    	# create a new migrations file"
	@echo "make migrations.up     	# runs all the migrations in database/migration which haven't been recorded in the schema_migrations table"
	@echo "make migrations.down   	# rolls back the migration with the latest version number"


	@echo "\nHELPERS\n"
	@echo "AWS_PROFILE=supabase make encrypt.env        # encrypts env vars"
	@echo "AWS_PROFILE=supabase make decrypt.env		# decrypt env vars"
	@echo "tree											# output a tree of folders in this repo (requires tree to be installed)"


#########################
# Database
#########################


migrations.new:
	cd "$(REPO_DIR)"/ && \
	dbmate new RENAME;
	@echo "\n\nMake sure to rename the file with a useful description!"

migrations.up:
	dbmate --migrations-dir $(REPO_DIR)/db/migrations --no-dump-schema migrate;

migrations.down:
	dbmate --migrations-dir "$(REPO_DIR)"/db/migrations --no-dump-schema rollback


#########################
# Helpers
#########################


encrypt.env:
	sops -e ./.env > ./.enc.env

decrypt.env:
	sops -d .enc.env > .env

tree:
	tree -L 2 -I 'README.md|node_modules|cucumber.js|package*|docker*'

