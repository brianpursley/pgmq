EXTENSION    = pgmq
EXTVERSION   = $(shell grep "^default_version" pgmq.control | sed -E "s/^default_version[[:space:]]*=[[:space:]]*'(.*)'/\1/" | tr -d "'")

DATA 		     = $(wildcard sql/*--*.sql)
PG_CONFIG   ?= pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

all: sql/$(EXTENSION)--$(EXTVERSION).sql META.json Trunk.toml

sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).sql
	cp $< $@

dist: Trunk.toml META.json
	git archive --format zip --prefix=$(EXTENSION)-$(EXTVERSION)/ -o $(EXTENSION)-$(EXTVERSION).zip --add-file META.json --add-file Trunk.toml HEAD sql pgmq.control README.md UPDATING.md Makefile

test:
	cargo test --manifest-path integration_test/Cargo.toml --no-default-features -- --test-threads=1

installcheck: test

run.postgres:
	docker run -d --name pgmq-pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 quay.io/tembo/pgmq-pg:latest

pgxn-zip: dist

META.json:
	sed 's/@@VERSION@@/$(EXTVERSION)/g' META.json.in > META.json

Trunk.toml:
	sed 's/@@VERSION@@/$(EXTVERSION)/g' Trunk.toml.in > Trunk.toml

clean:
	@rm -rf "$(EXTENSION)-$(EXTVERSION).zip"
	@rm -rf "sql/$(EXTENSION)--$(EXTVERSION).sql"
	@rm -rf META.json
	@rm -rf Trunk.toml
