/* UDP Client RFC2544 */
/* https://tools.ietf.org/html/rfc2544 */

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <strings.h>
#include <math.h>
#include <sys/time.h>

#include "rfc2544.h"

void error(char *);

void error(char *msg){
  perror(msg);
  exit(0);
}

int main(int argc, char *argv[]) {
	int i, y, sock, length, n, data[2], status, bytes, it;
	long send_frames, rcv_bytes, send_bytes;
	struct sockaddr_in server;
	struct hostent *hp;
	float rcv_buf[1024], send_buf[1024];
	int ok = 0;
	float udelay;
	struct timeval tv;
  	
	if (argc != 4) {
		printf("Usage: SERVER PORT BYTES\n");
	  exit(1);
	}
  
  // Initialize socket
	sock = socket(AF_INET, SOCK_DGRAM, 0);
	if (sock < 0) {
    error("InitializeSocketError");
	}
  
	tv.tv_sec  = 5;
	tv.tv_usec = 0;
	
  // Set timeout options to sock
  if (setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv)) < 0) {
    error("SetsockoptError");
	}

  // Define server address and port
	server.sin_family = AF_INET;
	hp = gethostbyname(argv[1]);
	if (hp == 0) {
    error("UnknownHostError");
	}
  
	bcopy((char *)hp->h_addr, (char *)&server.sin_addr, hp->h_length);
	server.sin_port = htons(atoi(argv[2]));
	length = sizeof(struct sockaddr_in);

	bytes = atoi(argv[3]);
	bytes -= HEADERS;
	
  printf("###### Network packet will have %d data bytes \n", bytes);

	bzero(rcv_buf,  1024);
	bzero(send_buf, 1024);
	
	status = SETUP;
	udelay = ONE_SECOND;
	y = 2.0; // divider

	while(!ok) {
		if (status == SETUP) {
      // Sending CMD_SETUP_SYN and check response
			send_buf[0] = CMD_SETUP_SYN;
			send_buf[1] = bytes;
      
			sendto(sock, send_buf, CMD_SIZE, 0, (const struct sockaddr*) &server, length);    
			usleep(DELAY);

    	n = recvfrom(sock, rcv_buf, 1024, 0, (struct sockaddr *)&server, (socklen_t *)&length);
    	if (n < 0) {
    	  if (DEBUG) {
          fprintf(stderr, "Recvfrom error\n");
        }
    	}else {
        // Check if packet was received by server
      	data[0] = rcv_buf[0];
      	if (data[0] == CMD_SETUP_ACK) {
  				status = SEND;
  			}
    	}
		}else if (status == SEND) {
			send_frames = 0;
			it = ONE_SECOND / udelay; // how many packet to send
			send_bytes = 0;
			
      // Sending data to server
			for (i = 0; i < it; ++i) {
				send_buf[0] = CMD_DATA;
				n = sendto(sock, send_buf, bytes, 0, (const struct sockaddr *)&server, length);
				if (n < 0) {
					error("SendError\n");
				} else {
					send_frames++;
					send_bytes += n;
				}
				usleep(udelay);
			}
      
      // Sending is finished
			status = FINISH;
		} else if (status == FINISH) {
      // Sending to server that client has finished
			send_buf[0] = CMD_FINISH_SYN;
			send_buf[1] = send_frames;

			sendto(sock, send_buf, CMD_SIZE, 0, (const struct sockaddr*) &server, length);
			usleep(DELAY);

    	n = recvfrom(sock, rcv_buf, 1024, 0, (struct sockaddr *)&server, (socklen_t *)&length);
    	if (n < 0) {
    	  if (DEBUG) {
          fprintf(stderr, "RecvfromError\n");
        }
      }
      // When server received FINISH_SYN
      // Fetch received bytes from server
    	data[0] = rcv_buf[0];
    	data[1] = rcv_buf[1];
    	if (data[0] == CMD_FINISH_ACK) {
				status    = SETUP;
				rcv_bytes = data[1];
			}

      float Bbs = (send_bytes + (send_frames * HEADERS));
      float Kbs = Bbs/1024;
      float Mps = Kbs/1024;
			fprintf(stdout,"%f Mb/s | %f KB/s | %f B/s | PPS: %lu \n", Mps, Kbs, Bbs, send_frames);

			if (status == SETUP) {
				if (rcv_bytes == send_bytes) {
					if (y > 1) {
            // Set smaller dalay and more packet to send
						udelay = udelay / y;
            if (DEBUG) {
              printf("### UP ### Set smaller dalay and more packet to send. Delay: %f Y: %d\n", udelay, y);
            }
					} else {
            // Finish
						ok = 1;
					}
				} else {
          // Set more delay because of lost packets
					udelay = udelay * y;
					y = y / 2; // set smaller divider
          if (DEBUG) {
            printf("### LOW ### Set higher delay because of packets lost. Delay: %f Y: %d\n", udelay, y);
          }
				}
			}
		}
	}
	return 0;
}