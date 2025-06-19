test:
	ledit sml tests/basic.sml

poster:
	ledit sml bin/cli.sml

e2e:
	cd loper && mlton pascal.mlb
	cd loper && ./pascal examples/Output.al
