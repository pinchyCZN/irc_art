#include <windows.h>
#include "resource.h"

int rows=10,cols=40;
int cwidth=8,cheight=12;

typedef struct{
	WCHAR val;
	int fg;
	int bg;
	int row;
	int col;
}CELL;
int cell_count=0;
CELL cells[]={0};

int test_cell()
{
	CELL *x=cells;
	CELL shit[]={0};
	int g;
	g=x[0].bg;
	g=shit[0].bg;
	return 0;
}
int update_cells(int w,int h)
{
	CELL *tmp;
	tmp=malloc(w*h*sizeof(CELL));
	if(tmp){

	}
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