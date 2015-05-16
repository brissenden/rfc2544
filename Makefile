bench_rfc2544:
	gcc -Wall -g3 -I include src/rfc2544-server.c -o bin/server
	gcc -Wall -g3 -I include src/rfc2544-throughput.c -o bin/throughput

clean:
	rm bin/*
