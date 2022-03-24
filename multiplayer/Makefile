.PHONY: db_test

MAKEFLAGS += -j2

export

rate ?= 2
conns ?= 10
delay ?= 60
duration ?=60

db_test: subs load

subs:
	@DURATION=$(duration) DELAY=$(delay) k6 run scripts/latencydbSubs.js --vus=$(conns)

load:
	@sleep $(delay); RATE=$(rate) DURATION=$(duration) ./k6 run scripts/latencydbLoader.js