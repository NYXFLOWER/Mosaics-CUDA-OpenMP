//
// Created by Hao Xu on 2019-03-07.
//
#include "mosaic_header.cuh"
#include <ctype.h>

#define BUFFER_SIZE 100

/************************ Various Utility Functions ****************************/

/* print error message and exit */
void
error(char *message) {
	fprintf(stderr, "ppm: %s\n", message);
	exit(1);
}

/** check if 2 ** n */
int
is_exp_of_two(unsigned int x) {
	unsigned int t = 1;
	while (1)
	{
		if (t == x) return 1;

		if (t > x) return 0;

		t = t * 2;
	}
}

/************************ PPM I/O Functions ****************************/
static void
skip_comment(FILE *fp) {
	int c = getc(fp);
	while (c == '#') {
		while (getc(fp) != '\n');
		c = getc(fp);
	}
	ungetc(c, fp);
}

/* read either p3 or p6, the output pixel data is a list of unsigned char */
void
read_ppm(const char *img_path, Img *image) {
	// open file
	FILE *fp = fopen(img_path, "rb");
	if (!fp) error("Image file cannot be accessed");

	// local variables
	unsigned int length;
	char buffer[BUFFER_SIZE];

	// get ppm type
	if (!fgets(buffer, BUFFER_SIZE, fp)) error("...");
	PPM ppm_type = (buffer[1] == '6') ? PPM_BINARY : PPM_PLAIN_TEXT;

	// get comment and other three features
	skip_comment(fp);
	if (!fscanf(fp, "%d\n", &image->width)) error("fail to scan width");
	skip_comment(fp);
	if (!fscanf(fp, "%d\n", &image->height)) error("fail to scan height");
	skip_comment(fp);
	if (!fscanf(fp, "%d\n", &image->color_value)) error("fail to scan color range");


	image->num_pixel = image->width * image->height;
	length = 3 * image->num_pixel;

	// get pixel data
	switch (ppm_type) {
	case (PPM_BINARY): {
		image->data = (unsigned char *)malloc(length);
		if (!image->data) error("data cannot be allocated on memory");

		if (fread((void *)image->data, 1, (size_t)length, fp) != length)
			error("cannot read image data from file");
		//            printf("\n");
		//
		//            for(int i = 0; i<100; i++)
		//                printf("%hhu ", image->data[i]);
		break;
	}
	case (PPM_PLAIN_TEXT): {
		int temp_int;
		int i = 0;
		unsigned char * temp_data = image->data = (unsigned char *)malloc(length);
		int data_index = 0;
		while (fscanf(fp, "%d", &temp_int) == 1) {
			temp_data[data_index++] = (unsigned char)temp_int;
			//printf("%hhu %d \n", temp_data[data_index - 1], i++);
		}
		break;
	}
	}

	fclose(fp);
}

void
write_ppm_binary(Img * image, char * file_name) {
	FILE *fp = fopen(file_name, "wb");
	if (!fp) error("file cannot be created or opened");

	// write header
	fprintf(fp, "P6\n%d\n%d\n%d\n", image->width, image->height, image->color_value);

	// write pixel data
	unsigned int length = 3 * image->width * image->height;
	if (fwrite((void *)image->data, 1, (size_t)length, fp) != length)
		error("data cannot be written to file");
}

void write_ppm_text(Img * image, char * file_name) {
	FILE *fp = fopen(file_name, "w");

	//  write header
	fprintf(fp, "P3\n%d\n%d\n%d\n", image->width, image->height, image->color_value);

	// format all data into string and write it into file 
	unsigned char * temp = image->data;
	for (unsigned int i = 1; i < image->height; i++)
	{
		for (unsigned int j = 1; j < image->width; j++)
		{
			fprintf(fp, "%d %d %d\t", (int)temp++, (int)temp++, (int)temp++);
		}
		fprintf(fp, "%d %d %d\n", (int)temp++, (int)temp++, (int)temp++);
	}
	fprintf(fp, "%d %d %d", (int)temp++, (int)temp++, (int)temp);

	fclose(fp);
}

/************************ Mosaic Function ****************************/
void
compute_mosaic_info(unsigned int cell_size, Img * image, Mosaic * mos) {
	mos->cell_size = cell_size;

	// the numbers of mosaic cell in each row and column, as well as their remain pixels
	mos->cell_num_height = image->height / cell_size;
	mos->cell_remain_height = image->height % cell_size;
	mos->cell_num_weight = image->width / cell_size;
	mos->cell_remain_weight = image->width % cell_size;

	// calculate the total number of mosaic cell
	mos->cell_main_num = mos->cell_num_height * mos->cell_num_weight;
	mos->cell_num = mos->cell_main_num;
	if (mos->cell_remain_weight != 0) mos->cell_num += mos->cell_num_height;
	if (mos->cell_remain_height != 0) mos->cell_num += mos->cell_num_weight + 1;

	// calculate the number of pixel in each mosaic cell
	mos->pixcel_num = cell_size * cell_size;

}

