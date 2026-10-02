.PHONY: all compile clean

all: compile

compile:
	erlc -o ebin src/topology.erl src/worker.erl src/project2.erl

clean:
	rm -rf ebin/*.beam erl_crash.dump

