#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <dirent.h>
#include <string.h>
typedef struct
{
    unsigned char red, green, blue;
} PPMPixel;

typedef struct
{
    unsigned char gray;
} PGMPixel;

typedef struct
{
    int x, y;
    PPMPixel *data;
} PPMImage;

typedef struct
{
    int x, y;
    PGMPixel *data;
} PGMImage;

#define CREATOR "V"
#define RGB_COMPONENT_COLOR 255

static PPMImage *readPPM(const char *filename)
{

    char buff[16];
    PPMImage *img;
    FILE *fp;
    int c, rgb_comp_color;
    //open PPM file for reading
    fp = fopen(filename, "rb");
    if (!fp)
    {
        fprintf(stderr, "Unable to open file '%s'\n", filename);
        exit(1);
    }

    //read image format
    if (!fgets(buff, sizeof(buff), fp))
    {
        perror(filename);
        exit(1);
    }

    //check the image format
    if (buff[0] != 'P' || buff[1] != '6')
    {
        fprintf(stderr, "Invalid image format (must be 'P6')\n");
        exit(1);
    }

    //alloc memory form image
    img = (PPMImage *)malloc(sizeof(PPMImage));
    if (!img)
    {
        fprintf(stderr, "Unable to allocate memory\n");
        exit(1);
    }

    //check for comments
    c = getc(fp);
    while (c == '#')
    {
        while (getc(fp) != '\n')
            ;
        c = getc(fp);
    }

    ungetc(c, fp);
    //read image size information
    if (fscanf(fp, "%d %d", &img->x, &img->y) != 2)
    {
        fprintf(stderr, "Invalid image size (error loading '%s')\n", filename);
        exit(1);
    }
    //read rgb component
    if (fscanf(fp, "%d", &rgb_comp_color) != 1)
    {
        fprintf(stderr, "Invalid rgb component (error loading '%s')\n", filename);
        exit(1);
    }

    //check rgb component depth
    if (rgb_comp_color != RGB_COMPONENT_COLOR)
    {
        fprintf(stderr, "'%s' does not have 8-bits components\n", filename);
        exit(1);
    }

    while (fgetc(fp) != '\n')
        ;
    //memory allocation for pixel data
    img->data = (PPMPixel *)malloc(img->x * img->y * sizeof(PPMPixel));

    if (!img)
    {
        fprintf(stderr, "Unable to allocate memory\n");
        exit(1);
    }

    //read pixel data from file
    if (fread(img->data, 3 * img->x, img->y, fp) != img->y)
    {
        fprintf(stderr, "Error loading image '%s'\n", filename);
        exit(1);
    }
    fclose(fp);
    return img;
}
void writePGM(const char *filename, PGMImage *gry)
{
    FILE *fp;
    //open file for output
    fp = fopen(filename, "wb");
    if (!fp)
    {
        fprintf(stderr, "Unable to open file '%s'\n", filename);
        exit(1);
    }

    //write the header file
    //image format
    fprintf(fp, "P5\n");

    //comments
    fprintf(fp, "# Created by %s\n", CREATOR);
    //image size
    fprintf(fp, "%d %d\n", gry->x, gry->y);
    // rgb component depth
    fprintf(fp, "%d\n", RGB_COMPONENT_COLOR);

    // pixel data
    fwrite(gry->data, gry->x, gry->y, fp);
    fclose(fp);
}

static PGMImage *changeColorPPM(PPMImage *img)
{
    PGMImage *gry;
    int i, grayValue;
    double graymapval;
    if (img)
    {
        gry = (PGMImage *)malloc(sizeof(PGMImage));
        gry->x = img->x;
        gry->y = img->y;
        gry->data = (PGMPixel *)malloc(gry->x * gry->y * sizeof(PGMPixel));
        clock_t start = clock();

        for (i = 0; i < img->x * img->y; i++)
        {
            graymapval = 0.3 * (img->data[i].red) + 0.59 * (img->data[i].green) + 0.11 * (img->data[i].blue);
            grayValue = (unsigned char)(((unsigned int)graymapval) % (RGB_COMPONENT_COLOR + 1));
            gry->data[i].gray = grayValue;
        }
        clock_t end = clock();
        double total_time_taken = ((double)(end - start)) / CLOCKS_PER_SEC;
        printf("%f\n", total_time_taken * 1000);
    }
    return gry;
}

int main()
{
    char nameppm[] = "JX0.ppm";
    char namepgm[] = "JX0.pgm";
    for (int i = 0; i <= 9; i++)
    {
        char str[10];
        sprintf(str, "%d", i);
        nameppm[1] = i + '0';
        namepgm[1] = i + '0';
        PPMImage *image;
        PGMImage *grayImage;
        image = readPPM(nameppm);
        printf("%d\t", i);
        grayImage = changeColorPPM(image);
        writePGM(namepgm, grayImage);
        free(image->data);
        free(image);
        free(grayImage->data);
        free(grayImage);
    }
    return 0;
}