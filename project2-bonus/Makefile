.PHONY: all compile clean

all: compile

compile:
	erlc -o ebin src/topology.erl src/worker_bonus.erl src/project2_bonus.erl

clean:
	rm -rf ebin/*.beam erl_crash.dump

