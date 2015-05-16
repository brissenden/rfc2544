bench_rfc2544:
	gcc -Wall -g3 -I include src/rfc2544-server.c -o bin/server
	gcc -Wall -g3 -I include src/rfc2544-client.c -o bin/client

clean:
	rm bin/*
