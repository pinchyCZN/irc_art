/* Copyright (c) 2018 Trollforge. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Trollforge's name may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 */

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdarg.h>
#define STB_SPRINTF_IMPLEMENTATION
#include "stb_sprintf.h"

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int bool;
#define false 0
#define true  1
#define FALSE 0
#define TRUE  1
#define EX_OSERR -1

#ifdef DEBUG
#define DEBUG 1
#endif /* DEBUG */

#define OUTLN_FNT 0
#define BLOCK_FNT 1
#define COLOR_FNT 2

#define NUM_CHARS 94

/* 4 bytes + '\0' */
#define MAX_UTFSTR	5

#define LEFT_JUSTIFY	0
#define RIGHT_JUSTIFY	1
#define CENTER_JUSTIFY	2

#define DEFAULT_WIDTH	80

#define COLOR_ANSI	0
#define COLOR_MIRC	1

#define ENC_UNICODE	0
#define ENC_ANSI	1


#ifndef DEFAULT_FONT
#define DEFAULT_FONT	"brndamgx" /* seems most complete */
#endif /* DEFAULT_FONT */

typedef struct opt_s {
	uint8_t justify;
	uint8_t width;
	uint8_t color;
	uint8_t encoding;
	bool random;
	bool info;
	bool to_stdout;
} opt_t;

typedef struct cell_s {
	uint8_t color;
	char utfchar[MAX_UTFSTR];
} cell_t;

typedef struct glyph_s {
	uint8_t width;
	uint8_t height;
	cell_t *cell;
} glyph_t;

typedef struct font_s {
	uint8_t namelen;
	uint8_t *name;
	uint8_t fonttype;
	uint8_t spacing;
	uint16_t blocksize;
	uint16_t *charlist;
	uint8_t *data;
	glyph_t *glyphs[NUM_CHARS];
	uint8_t height;
} font_t;


const char *charlist = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNO"
		       "PQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";

opt_t opt;

unsigned int get_tick(void);
int copy_to_clip(const char *str);
int dump_to_console(const char *str);

void
usage(void)
{
	printf("usage: tdfiglet [options] input\n");
	printf("\n");
	printf("    -f [font] Specify font file used.\n");
	printf("    -j l|r|c  Justify left, right, or center.  Default is left.\n");
	printf("    -w n      Set screen width.  Default is 80.\n");
	printf("    -c a|m    Color format ANSI or mirc.  Default is mirc.\n");
	printf("    -e u|a    Encode as unicode or ASCII.  Default is unicode.\n");
	printf("    -i        Print font details.\n");
	printf("    -r        Use random font.\n");
	printf("    -s        Print to stdout.\n");
	printf("    -h        Print usage.\n");
	printf("\n");
	exit(0);
}
static int optind=1;
static char *optarg=0;
int getopt(int argc,char **argv,const char *options)
{
	int result=-1;
	char *tmp;
	optarg=0;
	if(optind>=argc){
		return result;
	}
	tmp=argv[optind];
	if('-'==tmp[0]){
		unsigned char a;
		optind++;
		tmp++;
		a=tmp[0];
		if(isalpha(a)){
			char *ptr;
			ptr=strchr(options,a);
			if(ptr){
				result=a;
				a=ptr[1];
				if(':'==a){
					if(optind<argc){
						optarg=argv[optind++];
					}else{
						result=-1;
					}
				}
			}
		}
	}
	return result;
}



void append_printf(char **buf,int *buf_len,const char *fmt,...)
{
	va_list ap;
	int res;
	va_start(ap,fmt);
	res=stbsp_vsnprintf(0,0,fmt,ap);
	if(res>0){
		char *tmp=0;
		int tmp_size=0;
		int current_len=0;
		int start=0;
		tmp=*buf;
		if(tmp){
			current_len=strlen(tmp);
		}
		tmp_size=current_len+res+1;
		start=current_len;
		tmp=(char*)realloc(tmp,tmp_size);
		if(tmp){
			stbsp_vsnprintf(tmp+start,tmp_size-start,fmt,ap);
			tmp[tmp_size-1]=0;
			*buf=tmp;
			*buf_len=tmp_size;
		}
	}
}



int
lookupchar(char c, const font_t *font)
{
	int i;
	for (i = 0; i < NUM_CHARS; i++) {
		if (charlist[i] == c && font->charlist[i] != 0xffff)
			return i;
	}

	return -1;
}

void
ibmtoutf8(char *a, char *u)
{
	static unsigned char table[256][4]={
		{0x00,0x00,0x00,0x00},
		{0x01,0x00,0x00,0x00},
		{0x02,0x00,0x00,0x00},
		{0x03,0x00,0x00,0x00},
		{0x04,0x00,0x00,0x00},
		{0x05,0x00,0x00,0x00},
		{0x06,0x00,0x00,0x00},
		{0x07,0x00,0x00,0x00},
		{0x08,0x00,0x00,0x00},
		{0x09,0x00,0x00,0x00},
		{0x0A,0x00,0x00,0x00},
		{0x0B,0x00,0x00,0x00},
		{0x0C,0x00,0x00,0x00},
		{0x0D,0x00,0x00,0x00},
		{0x0E,0x00,0x00,0x00},
		{0x0F,0x00,0x00,0x00},
		{0x10,0x00,0x00,0x00},
		{0x11,0x00,0x00,0x00},
		{0x12,0x00,0x00,0x00},
		{0x13,0x00,0x00,0x00},
		{0x14,0x00,0x00,0x00},
		{0x15,0x00,0x00,0x00},
		{0x16,0x00,0x00,0x00},
		{0x17,0x00,0x00,0x00},
		{0x18,0x00,0x00,0x00},
		{0x19,0x00,0x00,0x00},
		{0x1A,0x00,0x00,0x00},
		{0x1B,0x00,0x00,0x00},
		{0x1C,0x00,0x00,0x00},
		{0x1D,0x00,0x00,0x00},
		{0x1E,0x00,0x00,0x00},
		{0x1F,0x00,0x00,0x00},
		{0x20,0x00,0x00,0x00},
		{0x21,0x00,0x00,0x00},
		{0x22,0x00,0x00,0x00},
		{0x23,0x00,0x00,0x00},
		{0x24,0x00,0x00,0x00},
		{0x25,0x00,0x00,0x00},
		{0x26,0x00,0x00,0x00},
		{0x27,0x00,0x00,0x00},
		{0x28,0x00,0x00,0x00},
		{0x29,0x00,0x00,0x00},
		{0x2A,0x00,0x00,0x00},
		{0x2B,0x00,0x00,0x00},
		{0x2C,0x00,0x00,0x00},
		{0x2D,0x00,0x00,0x00},
		{0x2E,0x00,0x00,0x00},
		{0x2F,0x00,0x00,0x00},
		{0x30,0x00,0x00,0x00},
		{0x31,0x00,0x00,0x00},
		{0x32,0x00,0x00,0x00},
		{0x33,0x00,0x00,0x00},
		{0x34,0x00,0x00,0x00},
		{0x35,0x00,0x00,0x00},
		{0x36,0x00,0x00,0x00},
		{0x37,0x00,0x00,0x00},
		{0x38,0x00,0x00,0x00},
		{0x39,0x00,0x00,0x00},
		{0x3A,0x00,0x00,0x00},
		{0x3B,0x00,0x00,0x00},
		{0x3C,0x00,0x00,0x00},
		{0x3D,0x00,0x00,0x00},
		{0x3E,0x00,0x00,0x00},
		{0x3F,0x00,0x00,0x00},
		{0x40,0x00,0x00,0x00},
		{0x41,0x00,0x00,0x00},
		{0x42,0x00,0x00,0x00},
		{0x43,0x00,0x00,0x00},
		{0x44,0x00,0x00,0x00},
		{0x45,0x00,0x00,0x00},
		{0x46,0x00,0x00,0x00},
		{0x47,0x00,0x00,0x00},
		{0x48,0x00,0x00,0x00},
		{0x49,0x00,0x00,0x00},
		{0x4A,0x00,0x00,0x00},
		{0x4B,0x00,0x00,0x00},
		{0x4C,0x00,0x00,0x00},
		{0x4D,0x00,0x00,0x00},
		{0x4E,0x00,0x00,0x00},
		{0x4F,0x00,0x00,0x00},
		{0x50,0x00,0x00,0x00},
		{0x51,0x00,0x00,0x00},
		{0x52,0x00,0x00,0x00},
		{0x53,0x00,0x00,0x00},
		{0x54,0x00,0x00,0x00},
		{0x55,0x00,0x00,0x00},
		{0x56,0x00,0x00,0x00},
		{0x57,0x00,0x00,0x00},
		{0x58,0x00,0x00,0x00},
		{0x59,0x00,0x00,0x00},
		{0x5A,0x00,0x00,0x00},
		{0x5B,0x00,0x00,0x00},
		{0x5C,0x00,0x00,0x00},
		{0x5D,0x00,0x00,0x00},
		{0x5E,0x00,0x00,0x00},
		{0x5F,0x00,0x00,0x00},
		{0x60,0x00,0x00,0x00},
		{0x61,0x00,0x00,0x00},
		{0x62,0x00,0x00,0x00},
		{0x63,0x00,0x00,0x00},
		{0x64,0x00,0x00,0x00},
		{0x65,0x00,0x00,0x00},
		{0x66,0x00,0x00,0x00},
		{0x67,0x00,0x00,0x00},
		{0x68,0x00,0x00,0x00},
		{0x69,0x00,0x00,0x00},
		{0x6A,0x00,0x00,0x00},
		{0x6B,0x00,0x00,0x00},
		{0x6C,0x00,0x00,0x00},
		{0x6D,0x00,0x00,0x00},
		{0x6E,0x00,0x00,0x00},
		{0x6F,0x00,0x00,0x00},
		{0x70,0x00,0x00,0x00},
		{0x71,0x00,0x00,0x00},
		{0x72,0x00,0x00,0x00},
		{0x73,0x00,0x00,0x00},
		{0x74,0x00,0x00,0x00},
		{0x75,0x00,0x00,0x00},
		{0x76,0x00,0x00,0x00},
		{0x77,0x00,0x00,0x00},
		{0x78,0x00,0x00,0x00},
		{0x79,0x00,0x00,0x00},
		{0x7A,0x00,0x00,0x00},
		{0x7B,0x00,0x00,0x00},
		{0x7C,0x00,0x00,0x00},
		{0x7D,0x00,0x00,0x00},
		{0x7E,0x00,0x00,0x00},
		{0x7F,0x00,0x00,0x00},
		{0xC3,0x87,0x00,0x00},
		{0xC3,0xBC,0x00,0x00},
		{0xC3,0xA9,0x00,0x00},
		{0xC3,0xA2,0x00,0x00},
		{0xC3,0xA4,0x00,0x00},
		{0xC3,0xA0,0x00,0x00},
		{0xC3,0xA5,0x00,0x00},
		{0xC3,0xA7,0x00,0x00},
		{0xC3,0xAA,0x00,0x00},
		{0xC3,0xAB,0x00,0x00},
		{0xC3,0xA8,0x00,0x00},
		{0xC3,0xAF,0x00,0x00},
		{0xC3,0xAE,0x00,0x00},
		{0xC3,0xAC,0x00,0x00},
		{0xC3,0x84,0x00,0x00},
		{0xC3,0x85,0x00,0x00},
		{0xC3,0x89,0x00,0x00},
		{0xC3,0xA6,0x00,0x00},
		{0xC3,0x86,0x00,0x00},
		{0xC3,0xB4,0x00,0x00},
		{0xC3,0xB6,0x00,0x00},
		{0xC3,0xB2,0x00,0x00},
		{0xC3,0xBB,0x00,0x00},
		{0xC3,0xB9,0x00,0x00},
		{0xC3,0xBF,0x00,0x00},
		{0xC3,0x96,0x00,0x00},
		{0xC3,0x9C,0x00,0x00},
		{0xC2,0xA2,0x00,0x00},
		{0xC2,0xA3,0x00,0x00},
		{0xC2,0xA5,0x00,0x00},
		{0xE2,0x82,0xA7,0x00},
		{0xC6,0x92,0x00,0x00},
		{0xC3,0xA1,0x00,0x00},
		{0xC3,0xAD,0x00,0x00},
		{0xC3,0xB3,0x00,0x00},
		{0xC3,0xBA,0x00,0x00},
		{0xC3,0xB1,0x00,0x00},
		{0xC3,0x91,0x00,0x00},
		{0xC2,0xAA,0x00,0x00},
		{0xC2,0xBA,0x00,0x00},
		{0xC2,0xBF,0x00,0x00},
		{0xE2,0x8C,0x90,0x00},
		{0xC2,0xAC,0x00,0x00},
		{0xC2,0xBD,0x00,0x00},
		{0xC2,0xBC,0x00,0x00},
		{0xC2,0xA1,0x00,0x00},
		{0xC2,0xAB,0x00,0x00},
		{0xC2,0xBB,0x00,0x00},
		{0xE2,0x96,0x91,0x00},
		{0xE2,0x96,0x92,0x00},
		{0xE2,0x96,0x93,0x00},
		{0xE2,0x94,0x82,0x00},
		{0xE2,0x94,0xA4,0x00},
		{0xE2,0x95,0xA1,0x00},
		{0xE2,0x95,0xA2,0x00},
		{0xE2,0x95,0x96,0x00},
		{0xE2,0x95,0x95,0x00},
		{0xE2,0x95,0xA3,0x00},
		{0xE2,0x95,0x91,0x00},
		{0xE2,0x95,0x97,0x00},
		{0xE2,0x95,0x9D,0x00},
		{0xE2,0x95,0x9C,0x00},
		{0xE2,0x95,0x9B,0x00},
		{0xE2,0x94,0x90,0x00},
		{0xE2,0x94,0x94,0x00},
		{0xE2,0x94,0xB4,0x00},
		{0xE2,0x94,0xAC,0x00},
		{0xE2,0x94,0x9C,0x00},
		{0xE2,0x94,0x80,0x00},
		{0xE2,0x94,0xBC,0x00},
		{0xE2,0x95,0x9E,0x00},
		{0xE2,0x95,0x9F,0x00},
		{0xE2,0x95,0x9A,0x00},
		{0xE2,0x95,0x94,0x00},
		{0xE2,0x95,0xA9,0x00},
		{0xE2,0x95,0xA6,0x00},
		{0xE2,0x95,0xA0,0x00},
		{0xE2,0x95,0x90,0x00},
		{0xE2,0x95,0xAC,0x00},
		{0xE2,0x95,0xA7,0x00},
		{0xE2,0x95,0xA8,0x00},
		{0xE2,0x95,0xA4,0x00},
		{0xE2,0x95,0xA5,0x00},
		{0xE2,0x95,0x99,0x00},
		{0xE2,0x95,0x98,0x00},
		{0xE2,0x95,0x92,0x00},
		{0xE2,0x95,0x93,0x00},
		{0xE2,0x95,0xAB,0x00},
		{0xE2,0x95,0xAA,0x00},
		{0xE2,0x94,0x98,0x00},
		{0xE2,0x94,0x8C,0x00},
		{0xE2,0x96,0x88,0x00},
		{0xE2,0x96,0x84,0x00},
		{0xE2,0x96,0x8C,0x00},
		{0xE2,0x96,0x90,0x00},
		{0xE2,0x96,0x80,0x00},
		{0xCE,0xB1,0x00,0x00},
		{0xC3,0x9F,0x00,0x00},
		{0xCE,0x93,0x00,0x00},
		{0xCF,0x80,0x00,0x00},
		{0xCE,0xA3,0x00,0x00},
		{0xCF,0x83,0x00,0x00},
		{0xC2,0xB5,0x00,0x00},
		{0xCF,0x84,0x00,0x00},
		{0xCE,0xA6,0x00,0x00},
		{0xCE,0x98,0x00,0x00},
		{0xCE,0xA9,0x00,0x00},
		{0xCE,0xB4,0x00,0x00},
		{0xE2,0x88,0x9E,0x00},
		{0xCF,0x86,0x00,0x00},
		{0xCE,0xB5,0x00,0x00},
		{0xE2,0x88,0xA9,0x00},
		{0xE2,0x89,0xA1,0x00},
		{0xC2,0xB1,0x00,0x00},
		{0xE2,0x89,0xA5,0x00},
		{0xE2,0x89,0xA4,0x00},
		{0xE2,0x8C,0xA0,0x00},
		{0xE2,0x8C,0xA1,0x00},
		{0xC3,0xB7,0x00,0x00},
		{0xE2,0x89,0x88,0x00},
		{0xC2,0xB0,0x00,0x00},
		{0xE2,0x88,0x99,0x00},
		{0xC2,0xB7,0x00,0x00},
		{0xE2,0x88,0x9A,0x00},
		{0xE2,0x81,0xBF,0x00},
		{0xC2,0xB2,0x00,0x00},
		{0xE2,0x96,0xA0,0x00},
		{0xC2,0xA0,0x00,0x00},
	};
	unsigned char tmp;
	tmp=a[0];
	strncpy(u,table[tmp],4);
	return;
}

void
readchar(int i, glyph_t *glyph, font_t *font)
{
	uint8_t ch;
	uint8_t color;
	uint8_t *p;
	int row = 0;
	int col = 0;
	int width;
	int height;

	if (font->charlist[i] == 0xffff) {
		printf("char not found\n");
		return;
	}

	p = font->data + font->charlist[i];


	glyph->width = *p;
	p++;
	glyph->height = *p;
	p++;

	row = 0;
	col = 0;
	width = glyph->width;
	height = glyph->height;

	if (height > font->height) {
		font->height = height;
	}

	glyph->cell = calloc(width * font->height, sizeof(cell_t));
	if (!glyph->cell) {
		perror(NULL);
		exit(EX_OSERR);
	}

	{
		int j;
		for (j = 0; j < width * font->height; j++) {
			glyph->cell[j].utfchar[0] = ' ';
			glyph->cell[j].color = 0;
		}
	}

	while (*p) {

		ch = *p;
		p++;


		if (ch == '\r') {
			ch = ' ';
			row++;
			col = 0;
		} else {
			if(COLOR_FNT==font->fonttype){
				color = *p;
				p++;
			}else{
				color=(7);
			}
#ifdef DEBUG
			if (ch == 0x09)
				ch = 'T';
			if (ch < 0x20)
				ch = '?';
#else
			if (ch < 0x20)
				ch = ' ';
#endif /* DEBUG */
			if (opt.encoding == ENC_UNICODE) {
				ibmtoutf8((char *)&ch,
					  glyph->cell[row * width + col].utfchar);
			} else {
				glyph->cell[row * width + col].utfchar[0] = ch;
			}

			glyph->cell[row * width + col].color = color;

			col++;
		}
	}
}


typedef struct{
	unsigned char *data;
	unsigned int len;
	char *name;
}FONT_FILE;

extern FONT_FILE font_list[];
extern FONT_FILE unused_font_list[];

int get_font_count(FONT_FILE *flist)
{
	int result=0;
	int index=0;
	while(1){
		if(0==flist[index++].data){
			break;
		}
		result++;
	}
	return result;
}
int is_font_valid_for_chars(FONT_FILE *font,char *use_chars)
{
	int result=TRUE;
	int i;
	short *data=(short*)(font->data+45);
	for(i=0;i<=0xFF;i++){
		unsigned char a;
		a=use_chars[i];
		if(a && (i>=33) && (i<=126)){
			short val;
			val=data[i-33];
			if(val == -1){
				result=FALSE;
				break;
			}
		}
	}
	return result;
}
int populate_use_font_list(FONT_FILE **use_list,int ulist_count,char *use_chars)
{
	int result=0;
	int i,count,index=0;
	count=get_font_count(font_list);
	for(i=0;i<count;i++){
		int res;
		FONT_FILE *f;
		f=&font_list[i];
		res=is_font_valid_for_chars(f,use_chars);
		if(res){
			if(index>=ulist_count)
				break;
			use_list[index++]=f;
		}
	}
	count=get_font_count(unused_font_list);
	for(i=0;i<count;i++){
		int res;
		FONT_FILE *f;
		f=&unused_font_list[i];
		res=is_font_valid_for_chars(f,use_chars);
		if(res){
			if(index>=ulist_count)
				break;
			use_list[index++]=f;
		}
	}
	result=index;
	return result;
}
char *get_random_font_name(char *used_chars)
{
	char *result=DEFAULT_FONT;
	int rval;
	int c1,c2,total;
	FONT_FILE *flist=font_list;
	FONT_FILE **use_list;
	int use_list_count;
	srand(get_tick());
	c1=get_font_count(font_list);
	c2=get_font_count(unused_font_list);
	total=c1+c2;
	use_list=calloc(sizeof(FONT_FILE*),total);
	if(0==use_list){
		return result;
	}
	use_list_count=populate_use_font_list(use_list,total,used_chars);
	rval=rand();
	rval%=use_list_count;
	result=use_list[rval]->name;
	free(use_list);
	return result;
}
FONT_FILE *search_font_list(FONT_FILE *flist,const char *fname)
{
	FONT_FILE *result=0;
	int index=0;
	while(1){
		FONT_FILE *f;
		f=&flist[index++];
		if(0==f->data){
			break;
		}
		if(0==stricmp(f->name,fname)){
			result=f;
			break;
		}
	}
	return result;
}
FONT_FILE *get_font_entry(const char *fname)
{
	FONT_FILE *result=0;
	result=search_font_list(font_list,fname);
	if(0==result){
		result=search_font_list(unused_font_list,fname);
	}
	return result;
}

font_t
*loadfont(char *fn_arg)
{
	font_t *font;
	uint8_t *map = NULL;
	size_t len;
	uint8_t *p;
	FONT_FILE *fentry=0;
	int i;

	const char *magic = "\x13TheDraw FONTS file\x1a";


	if (opt.info) {
		printf("file: %s\n", fn_arg);
	}
	
	fentry=get_font_entry(fn_arg);
	if(0==fentry){
		printf("Unable to find %s\n",fn_arg);
		exit(0);
	}
	font = malloc(sizeof(font_t));
	map=fentry->data;
	len=fentry->len;


	if (!font) {
		perror(NULL);
		exit(-1);
	}

	font->namelen = map[24];
	font->name = &map[25];
	font->fonttype = map[41];
	font->spacing = map[42];
	font->blocksize = (uint16_t)map[43];
	font->charlist = (uint16_t *)&map[45];
	font->data = &map[233];
	font->height = 0;

	if (strncmp(magic, (const char *)map, strlen(magic))){// || font->fonttype != COLOR_FNT) {
		fprintf(stderr, "Invalid font file: %s\n", fn_arg);
		exit(-1);
	}

	if (opt.info) {
		printf("font: %s\nchar list: ", font->name);
	}

	{
		int i;
		for (i = 0; i < NUM_CHARS; i++) {
			/* check for invalid glyph addresses */
			if (charlist[i] + &map[233] > map + len) {
				printf("invalid glyph address\n");
				perror(NULL);
				exit(-1);
			}

			if (lookupchar(charlist[i], font) > -1) {

				if (opt.info) {
					printf("%c", charlist[i]);
				}

				p = font->data + font->charlist[i] + 2;
				if (*p > font->height) {
					font->height = *p;
				}
			}
		}
	}

	if (opt.info) {
		printf("\n");
	}

	for (i = 0; i < NUM_CHARS; i++) {

		if (lookupchar(charlist[i], font) != -1) {

			font->glyphs[i] = calloc(1, sizeof(glyph_t));

			if (!font->glyphs[i]) {
				perror(NULL);
				exit(EX_OSERR);
			}

			readchar(i, font->glyphs[i], font);

		} else {
			font->glyphs[i] = NULL;
		}
	}
	return font;
}




void
printcolor(uint8_t color,unsigned char **buf,int *buf_len)
{

	uint8_t fg = color & 0x0f;
	uint8_t bg = (color & 0xf0) >> 4;

	/* thedraw colors                                     BRT BRT BRT BRT BRT BRT BRT BRT */
	/* thedraw colors     BLK BLU GRN CYN RED MAG BRN GRY BLK BLU GRN CYN RED PNK YLW WHT */
	uint8_t fgacolors[] = {30, 34, 32, 36, 31, 35, 33, 37, 90, 94, 92, 96, 91, 95, 93, 97};
	uint8_t bgacolors[] = {40, 44, 42, 46, 41, 45, 43, 47};
	uint8_t fgmcolors[] = { 1,  2,  3, 10,  5,  6,  7, 15, 14,  12, 9, 11,  4, 13,  8,  0};
	uint8_t bgmcolors[] = { 1,  2,  3, 10,  5,  6,  7, 15, 14,  12, 9, 11,  4, 13,  8,  0};

	if (opt.color == COLOR_ANSI) {
		append_printf(buf,buf_len,"\x1b[");
		append_printf(buf,buf_len,"%d;", fgacolors[fg]);
		append_printf(buf,buf_len,"%dm", bgacolors[bg]);
	} else {
		append_printf(buf,buf_len,"\x03");
		append_printf(buf,buf_len,"%d,", fgmcolors[fg]);
		append_printf(buf,buf_len,"%d", bgmcolors[bg]);
	}
}

void
printrow(const glyph_t *glyph, int row,unsigned char **buf,int *buf_len)
{
	char *utfchar;
	uint8_t color;
	int i;
	uint8_t lastcolor;

	for (i = 0; i < glyph->width; i++) {
		utfchar = glyph->cell[glyph->width * row + i].utfchar;
		color = glyph->cell[glyph->width * row + i].color;

		if (i == 0 || color != lastcolor) {
			printcolor(color,buf,buf_len);
			lastcolor = color;
		}

		append_printf(buf,buf_len,"%s", utfchar);
	}

	if(0){
		if (opt.color == COLOR_ANSI) {
			append_printf(buf,buf_len,"\x1b[0m");
		} else {
			append_printf(buf,buf_len,"\x03");
		}
	}
}

void
printstr(const char *str, font_t *font,char **buf,int *buf_len)
{
	int maxheight = 0;
	int linewidth = 0;
	int len = strlen(str);
	int padding = 0;
	int n = 0;
	int i;

	for (i = 0; i < len; i++) {
		glyph_t *g;

		n = lookupchar(str[i], font);

		if (n == -1) {
			continue;
		}

		g = font->glyphs[n];

		if (g->height > maxheight) {
			maxheight = g->height;
		}

		linewidth += g->width;
		if (linewidth + 1 < len) {
			linewidth += font->spacing;
		}
	}

	if (opt.justify == CENTER_JUSTIFY) {
		padding = (opt.width - linewidth) / 2;
	} else if (opt.justify == RIGHT_JUSTIFY) {
		padding = (opt.width - linewidth);
	}

	for (i = 0; i < maxheight; i++) {
		int c,j;
		int len;
		for (j = 0; j < padding; ++j) {
			append_printf(buf,buf_len," ");
		}
		len=strlen(str);
		for (c = 0; c < len; c++) {
			glyph_t *g;
			n = lookupchar(str[c], font);

			if (n == -1) {
				continue;
			}

			g = font->glyphs[n];
			printrow(g, i,buf,buf_len);

			if(1){
				if (opt.color == COLOR_ANSI) {
					append_printf(buf,buf_len,"%s","\x1b[0m");
				} else {
					//append_printf(buf,buf_len,"%s","\x03");
					append_printf(buf,buf_len,"%s%s","\x03","1,1");
				}
			}
			{
				int s;
				for (s = 0; s < font->spacing; s++) {
					append_printf(buf,buf_len," ");
				}
			}
		}

		if (opt.color == COLOR_ANSI) {
			append_printf(buf,buf_len,"%s","\x1b[0m\n");
		} else {
			append_printf(buf,buf_len,"%s","\r\n");
		}
	}
}

typedef unsigned char BYTE;
int get_utf8_code(int len,BYTE *data)
{
	int result=0;
	switch(len){
	case 2:
		result=((data[0]&0x1F)<<6)|(data[1]&0x3F);
		break;
	case 3:
		result=((data[0]&0x0F)<<12)|((data[1]&0x3F)<<6)|(data[2]&0x3F);
		break;
	case 4:
		result=((data[0]&0x07)<<18)|((data[1]&0x3F)<<12)|((data[2]&0x3F)<<6)|(data[3]&0x3F);
		break;
	}
	return result;
}

void save_font_info()
{
	int getch();
	int i;
	char *tmp=0;
	int tmp_len=0;
	static char *tmp_list[200]={0};
	int tmp_index=0;
	for(i=0;i<=0xFF;i++){
		char a[10]={0};
		unsigned char b[10]={0};
		int len,code;
		a[0]=i;
		ibmtoutf8(a,b);
		printf("%02X: %02X %02X %02X %02X ",i,b[0],b[1],b[2],b[3]);
		len=strlen(b);
		if(len>1){
			code=get_utf8_code(len,b);
			printf("(%04X)",code);
		}
		printf("\n");
		append_printf(&tmp,&tmp_len,"{0x%02X,0x%02X,0x%02X,0x%02X},\n",b[0],b[1],b[2],b[3]);
		/*
		append_printf(&tmp,&tmp_len,"%02X:%s",i,b);
		if(strlen(tmp)>100){
			tmp_list[tmp_index++]=strdup(tmp);
			free(tmp);
			tmp=0;
			tmp_len=0;
		}
		*/
	}
	if(tmp){
		tmp_list[tmp_index++]=strdup(tmp);
		free(tmp);
		tmp=0;
		tmp_len=0;
	}
	tmp=calloc(100,1);

	for(i=0;i<200;i++){
		if(0==tmp_list[i]){
			break;
		}
		append_printf(&tmp,&tmp_len,"%s\n",tmp_list[i]);

	}
	copy_to_clip(tmp);
	getch();
	exit(0);
}

void get_used_chars(int argc,char **argv,char *list)
{
	int i;
	memset(list,0,0xFF);
	for(i=0;i<argc;i++){
		char *str;
		int j,len;
		str=argv[i];
		len=strlen(str);
		for(j=0;j<len;j++){
			unsigned char a;
			a=str[j];
			list[a]=1;
		}
	}
}

void print_font_type(int type)
{
	typedef struct{
		int type;
		char *desc;
	}MAP;
	static MAP font_types[]={
		{0,"Outline font"},
		{1,"Block font"},
		{2,"Color font"},
	};
	int i,count;
	count=sizeof(font_types)/sizeof(MAP);
	for(i=0;i<count;i++){
		if(font_types[i].type==type){
			printf("Type: %s\n",font_types[i].desc);
			break;
		}
	}
}

int
main(int argc, char *argv[])
{
	font_t *font = NULL;
	int o;
	char *fontfile = NULL;
	char used_chars[0xFF]={0};

	int r = 0;
	int dll = 0;

	opt.justify = LEFT_JUSTIFY;
	opt.width = 80;
	opt.info = false;
	opt.encoding = ENC_UNICODE;
//	opt.encoding = ENC_ANSI;
	opt.random = false;
	opt.color = COLOR_MIRC;


	while((o = getopt(argc, argv, "f:w:j:c:e:irsh")) != -1) {
		switch (o) {
			case 'f':
				fontfile = optarg;
				break;
			case 'w':
				opt.width = atoi(optarg);
				break;
			case 'j':
				switch (optarg[0]) {
					case 'l':
						opt.justify = LEFT_JUSTIFY;
						break;
					case 'r':
						opt.justify = RIGHT_JUSTIFY;
						break;
					case 'c':
						opt.justify = CENTER_JUSTIFY;
						break;
					default:
						usage();
				}
				break;
			case 'c':
				switch (optarg[0]) {
					case 'a':
						opt.color = COLOR_ANSI;
						break;
					case 'm':
						opt.color = COLOR_MIRC;
						break;
					default:
						usage();
				}
				break;
			case 'e':
				switch (optarg[0]) {
					case 'a':
						opt.encoding = ENC_ANSI;
						break;
					case 'u':
						opt.encoding = ENC_UNICODE;
						break;
					default:
						usage();
				}
				break;
			case 'i':
				opt.info = true;
				break;
			case 'r':
				opt.random = true;
				break;
			case 's':
				opt.to_stdout = true;
				break;
			case 'h':
				/* fallthrough */
			default:
				usage();
		}
	}

	argc -= optind;
	argv += optind;

	if (argc < 1) {
		usage();
	}
	get_used_chars(argc,argv,used_chars);

	if (!fontfile) {
		if (!opt.random) {
			fontfile = DEFAULT_FONT;
		} else {
			fontfile=get_random_font_name(used_chars);
		}
	}

	font = loadfont(fontfile);
	if(0==font){
		printf("unable to load font:%s\n",fontfile);
		exit(-1);
	}
	if(!opt.to_stdout)
		print_font_type(font->fonttype);
	{
		FONT_FILE *f;
		f=get_font_entry(fontfile);
		if(f){
			int res=is_font_valid_for_chars(f,used_chars);
			if(!res){
				if(!opt.to_stdout)
					printf("WARNING: font %s does not support all given chars!\n",fontfile);
			}
		}
	}

	printf("\n");
	{
		char *temp=0;
		int temp_len=0;
		int i;
		for (i = 0; i < argc; i++) {
			printstr(argv[i], font,&temp,&temp_len);
			append_printf(&temp,&temp_len,"\n");
		}
		if(opt.to_stdout){
			printf("%s",temp);
		}else{
			printf("copied to clipboard\n");
			copy_to_clip(temp);
			dump_to_console(temp);
		}
	}

	return(0);
}
