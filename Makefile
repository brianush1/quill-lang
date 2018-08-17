all:
	lua ./bootstrap/qcc.lua -p=./compiler -e ./tests/working/Complex.ql -o=./tests/output/Complex