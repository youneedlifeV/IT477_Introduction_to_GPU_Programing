#include <stdio.h>
#include <cuda.h>
#include <time.h>
#include <stdlib.h>
#include <math.h>
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

static PGMImage *changeColorPPM(PPMImage *img, double* ttt)
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
        *ttt = (((double)(end - start))/CLOCKS_PER_SEC)*1000;
    }
    return gry;
}

__global__ void toGRAY(unsigned char* R, unsigned char* G, unsigned char* B, unsigned char* GRAY, long long n){
        int tid = blockIdx.x*blockDim.x + threadIdx.x;
        if(tid<n) {
                GRAY[tid] = (unsigned char)(((unsigned int)(0.3 * (R[tid]) + 0.59 * (G[tid]) + 0.11 * (B[tid]))) % (256));
            
        }
}

int main()
{       
    char nameppm[] = "JX0.ppm";
    char namepgm[] = "JX0.pgm";
    double serialTime[10];
    double ttt;
    printf("Serial Computation Time: \n");
    printf("I\tTime\n");
    for (int i = 0; i <= 9;i++)
{
    char str[10];
    sprintf(str, "%d", i);
    nameppm[1] = i + '0';
    namepgm[1] = i + '0';
    PPMImage *image;
    PGMImage *grayImage;
    image = readPPM(nameppm);
    double ttt;
    grayImage = changeColorPPM(image,&ttt);
    printf("%d\t%f\n",i,ttt);
    serialTime[i] = ttt;
    writePGM(namepgm, grayImage);
    free(image->data);
    free(image);
    free(grayImage->data);
    free(grayImage);
}
    long long len;
        long long lenb, mx, mn;
        mx = pow(2,10);
        mn = pow(2,0);
        lenb = mn;
    double getTime[11][12];
    getTime[0][0]=0;
    int ii=0;
    for(; lenb<=mx; lenb*=2) {
        
    for (int i = 0; i <= 9;i++) {
        unsigned char *R,*G,*B,*GRAY,*dR,*dG,*dB,*dGRAY;
        char str[10];
        sprintf(str, "%d", i);
        nameppm[1] = i + '0';
        namepgm[1] = i + '0';
        PPMImage *img;
        PGMImage *gry;

        img = readPPM(nameppm);
        len = (img->x * img->y);
        gry = (PGMImage *)malloc(sizeof(PGMImage));
        gry->x = img->x;
        gry->y = img->y;
        gry->data = (PGMPixel *)malloc(gry->x * gry->y * sizeof(PGMPixel));

        R = (unsigned char*)malloc(len*sizeof(unsigned char));
        G = (unsigned char*)malloc(len*sizeof(unsigned char));
        B = (unsigned char*)malloc(len*sizeof(unsigned char));
        GRAY = (unsigned char*)malloc(len*sizeof(unsigned char));
        cudaMalloc((void**)&dR,len*sizeof(unsigned char));
        cudaMalloc((void**)&dG,len*sizeof(unsigned char));
        cudaMalloc((void**)&dB,len*sizeof(unsigned char));
        cudaMalloc((void**)&dGRAY,len*sizeof(unsigned char));
        for(int j=0; j<len; j++) {
            R[j] = img->data[j].red;
            G[j] = img->data[j].green;
            B[j] = img->data[j].blue;
        }
        cudaMemcpy(dR,R,len*sizeof(unsigned char),cudaMemcpyHostToDevice);
        cudaMemcpy(dG,G,len*sizeof(unsigned char),cudaMemcpyHostToDevice);
        cudaMemcpy(dB,B,len*sizeof(unsigned char),cudaMemcpyHostToDevice);
        int blockSize = lenb;
        int numBlocks = (len + blockSize -1) / blockSize;
        cudaEvent_t start,stop;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);

        toGRAY<<<numBlocks, blockSize>>>(dR,dG,dB,dGRAY,len);

        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        float tot_time=0;
        cudaEventElapsedTime(&tot_time,start,stop);
        getTime[i+1][0] = i;
        getTime[0][ii+1] = lenb; 
        getTime[i+1][ii+1] = tot_time; //FOR PARALLEL TIME GRAPH
        //getTime[i+1][ii+1] = (serialTime[i]/tot_time);  //FOR SPEEDUP GRAPH
        
        cudaMemcpy(GRAY,dGRAY,len*sizeof(unsigned char),cudaMemcpyDeviceToHost);
        for(int j=0; j<len; j++) {
            gry->data[j].gray = GRAY[j];
        }
        writePGM(namepgm, gry);
        free(R);
        free(G);
        free(B);
        free(GRAY);
        cudaFree(dR);
        cudaFree(dG);
        cudaFree(dB);
        cudaFree(dGRAY);
        free(img->data);
        free(img);
        free(gry->data);
        free(gry);

    }
ii++;
}
    printf("Parallel Computation Time: \n");
    for(int i=0; i<11; i++) {
        for(int j=0;j<12;j++) {
            if( j==0 ){
                printf("%.0f", getTime[i][j]);
            }
            else if( i==0 ){
                printf(",%.0f", getTime[i][j]);
            }
            else printf(",%f", getTime[i][j]);
        }
        printf("\n");
    }
    printf("Speed Up: \n");
    for(int i=0; i<11; i++) {
        for(int j=0;j<12;j++) {
            if( j==0 ){
                printf("%.0f", getTime[i][j]);
            }
            else if( i==0 ){
                printf(",%.0f", getTime[i][j]);
            }
            else printf(",%f", (serialTime[i-1]/(double)getTime[i][j]));
        }
        printf("\n");
    }
    return 0;
}
