/*
 * RCS (Reverse Computer Screen) by Einar Saukas
 *
 * http://www.worldofspectrum.org
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_SIZE  6912
#define SECTOR1   2048
#define ATTRIB1    256

unsigned char input_data[MAX_SIZE+1];
unsigned char output_data[MAX_SIZE];
size_t file_size;

void convert(int decode_mode) {
    int sector;
    int row;
    int lin;
    int col;
    int i;

    i = 0;

    /* transform bitmap area */
    for (sector=0; sector < file_size/SECTOR1; sector++) {
        for (col=0; col < 32; col++) {
            for (row=0; row < 8; row++) {
                for (lin=0; lin < 8; lin++) {
                    if (decode_mode) {
                        output_data[(((((sector<<3)+lin)<<3)+row)<<5)+col] = input_data[i++];
                    } else {
                        output_data[i++] = input_data[(((((sector<<3)+lin)<<3)+row)<<5)+col];
                    }
                }
            }
        }
    }

    /* just copy attributes */
    for (; i < file_size; i++) {
        output_data[i]=input_data[i];
    }
}

int main(int argc, char *argv[]) {
    int forced_mode = 0;
    int decode_mode = 0;
    char *input_name = NULL;
    char *output_name = NULL;
    FILE *ifp;
    FILE *ofp;
    size_t bytes_read;
    int i;

    printf("RCS: Reverse Computer Screen by Einar Saukas\n");

    /* process command-line arguments */
    for (i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-f")) {
            forced_mode = 1;
        } else if (!strcmp(argv[i], "-d")) {
            decode_mode = 1;
        } else if (input_name == NULL) {
            input_name = argv[i];
        } else if (output_name == NULL) {
            output_name = argv[i];
        } else {
            input_name = NULL;
            break;
        }
    }

    /* validate command-line arguments */
    if (input_name == NULL) {
         fprintf(stderr, "Usage: %s [-f] [-d] input [output]\n"
                         "  -f      Force overwrite of output file\n"
                         "  -d      Decode from RCS to SCR\n", argv[0]);
         exit(1);
    }
    if (output_name == NULL) {
        output_name = (char *)malloc(strlen(input_name)+5);
        strcpy(output_name, input_name);
        strcat(output_name, decode_mode ? ".scr" : ".rcs");
    }

    /* open input file */
    ifp = fopen(input_name, "rb");
    if (!ifp) {
         fprintf(stderr, "Error: Cannot access input file %s\n", input_name);
         exit(1);
    }

    /* read input file */
    file_size = 0;
    while ((bytes_read = fread(input_data+file_size, sizeof(char), MAX_SIZE+1-file_size, ifp)) > 0) {
        file_size += bytes_read;
    }

    /* close input file */
    fclose(ifp);

    /* generate output file */
    if (file_size > 0 && file_size <= MAX_SIZE && (file_size%SECTOR1 == 0 || file_size%(SECTOR1+ATTRIB1) == 0)) {
        convert(decode_mode);
    } else {
        fprintf(stderr, "Error: Invalid input file %s\n", input_name);
        exit(1);
    }

    /* check output file */
    if (!forced_mode && fopen(output_name, "rb") != NULL) {
         fprintf(stderr, "Error: Already existing output file %s\n", output_name);
         exit(1);
    }

    /* create output file */
    ofp = fopen(output_name, "wb");
    if (!ofp) {
         fprintf(stderr, "Error: Cannot create output file %s\n", output_name);
         exit(1);
    }

    /* write output file */
    if (fwrite(output_data, sizeof(char), file_size, ofp) != file_size) {
         fprintf(stderr, "Error: Cannot write output file %s\n", output_name);
         exit(1);
    }

    /* close output file */
    fclose(ofp);

    /* done! */
    printf("%scoded %s screen with%s attributes!\n", decode_mode ? "De" : "En",
        file_size/SECTOR1 == 1 ? "1/3" : file_size/SECTOR1 == 2 ? "2/3" : "full",
        file_size%SECTOR1 == 0 ? "out" : "");

    return 0;
}
