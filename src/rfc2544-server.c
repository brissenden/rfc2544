/* UDP Server RFC2544 */
/* https://tools.ietf.org/html/rfc2544 */

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <strings.h>
#include <sys/time.h>

#include "rfc2544.h"

int bytes;
long send_frames, rcv_frames, rcv_bytes;

void error(char *msg){
  perror(msg);
  exit(0);
}

void clear_bench(){
	rcv_frames = 0;
	rcv_bytes = 0;
}

void inc_bench(int size){
	rcv_frames++;
	rcv_bytes += size;
}

int main(int argc, char *argv[]){  
	int n, sock, length, fromlen, data[2];
	struct sockaddr_in server;
	struct sockaddr_in from;
	float rcv_buf[1024], send_buf[1024];
	struct timeval tv;
  
  // Exit when wrong number of parameters
	if (argc < 2) {
		fprintf(stderr, "Usage: port\n");
		exit(0);
	}
	
  // Opening socket
	sock = socket(AF_INET, SOCK_DGRAM, 0);
	if (sock < 0) {
		error("OpeningSocketError");
	}

	tv.tv_sec  = 0;
	tv.tv_usec = 10;
	if (setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv)) < 0) {
	  error("SetsockoptError");
	}

	length = sizeof(server);
	bzero(&server,length);
  
	server.sin_family       = AF_INET;
	server.sin_addr.s_addr  = INADDR_ANY;
	server.sin_port         = htons(atoi(argv[1]));
	
  // Binding ip:port address
  if (bind(sock, (struct sockaddr *)&server,length) <0) {
		error("BindingError");
	}
	fromlen = sizeof(struct sockaddr_in);

	bzero(rcv_buf,  1024);
	bzero(send_buf, 1024);
  
  // Listening on sock
  while (1) {
    n = recvfrom(sock, rcv_buf, 1024, 0, (struct sockaddr *)&from, (socklen_t *)&fromlen);
    // When data received
    if (n > 0) {
      data[0] = rcv_buf[0]; // Packet Type
      data[1] = rcv_buf[1]; // Packet Data

      if (data[0] == CMD_DATA) {
        // Count bytes and data
        inc_bench(n);
      } else if (data[0] == CMD_SETUP_SYN) {
        bytes = data[1];
        bytes += HEADERS;

        // Clear stats & send back CMD_SETUP_ACK to sender
        clear_bench();
        send_buf[0] = CMD_SETUP_ACK;
        sendto(sock, send_buf, CMD_SIZE, 0, (struct sockaddr*) &from, fromlen);
        usleep(DELAY);
      } else if (data[0] == CMD_FINISH_SYN) {
        send_frames = data[1];
        
        // Generate report & send back CMD_FINISH_ACK to sender
        // Return rcv_bytes to client to check
        send_buf[0] = CMD_FINISH_ACK;
        send_buf[1] = rcv_bytes;
        sendto(sock, send_buf, CMD_SIZE, 0, (struct sockaddr*) &from,fromlen);

        clear_bench();
        usleep(DELAY);
      } else {
        // Handle unsupported command
        fprintf(stderr, "Unknown CMD: %d\n", data[0]);
      }
    }
  }
  return 0;
}

