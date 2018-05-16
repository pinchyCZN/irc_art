#include <windows.h>
#include "resource.h"
#include "vga737.h"
#include "unicode_font.h"

char *vgargb=0;

typedef struct{
	WCHAR val;
	int fg;
	int bg;
}CELL;
int cell_count=0;
CELL *cells=0;
int rows=10,cols=40;
int cwidth=8,cheight=12;

int resize_map(int w,int h)
{
	return 0;
}
int update_cells(int w,int h)
{
	int result=FALSE;
	CELL *tmp;
	tmp=calloc(w*h*sizeof(CELL),1);
	if(tmp){
		free(cells);
		cells=tmp;
		result=TRUE;
	}
	return result;
}
int get_rows()
{
	return rows;
}
int get_cols()
{
	return cols;
}
int create_vga_font()
{
	const int vga_count=(sizeof(vga737_bin)/12);
	const int total=vga_count+(sizeof(block_elements)/12);
	if(vgargb==0)
		vgargb=malloc(8*12*total);
	if(vgargb){
		int i,j,k;
		for(k=0;k<total;k++){
			for(i=0;i<12;i++){
				for(j=0;j<8;j++){
					int c;
					char *font=vga737_bin;
					char *p;
					int offset=k*12;
					if(k>=vga_count){
						font=block_elements;
						offset=(k-vga_count)*12;
					}
					p=font+offset;
					if(p[i]&(1<<(7-j)))
						c=1;
					else
						c=0;
					//flip y
					vgargb[k*8*12+j+(11-i)*8]=c;
				}
			}
		}
	}
	return 0;
}
int paint_window(HWND hwnd,HDC hdc)
{
	PAINTSTRUCT ps;
	BITMAPINFO bmi;

	hdc=BeginPaint(hwnd,&ps);
	memset(&bmi,0,sizeof(BITMAPINFO));
	bmi.bmiHeader.biBitCount=24;
	bmi.bmiHeader.biWidth=cwidth*cols;
	bmi.bmiHeader.biHeight=cheight*rows;
	bmi.bmiHeader.biPlanes=1;
	bmi.bmiHeader.biSize=sizeof(bmi);
	/*
	SetDIBitsToDevice(hdc,0,Y_OFFSET,W,H,0,0,0,H,buffer,&bmi,DIB_RGB_COLORS);
	{
		RECT rect;
		int dw=0,dh=0;
		GetWindowRect(hwnd,&rect);
		StretchDIBits(hdc,0,Y_OFFSET,W+dw,H+dh,0,0,W,H,buffer,&bmi,DIB_RGB_COLORS,SRCCOPY);

	}
	*/
	EndPaint(hwnd,&ps);
	return 0;
}