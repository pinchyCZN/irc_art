module image;

import core.sys.windows.windows;

nothrow:
struct CELL{
	WCHAR val;
	int fg;
	int bg;
};

struct IMAGE{
nothrow:
	CELL[] cells;
	int width;
	int height;
	POINT cursor;
	RECT selection;
	void resize_image(int w,int h){
		CELL[] tmp;
		int x,y;
		tmp.length=w*h;
		foreach(ref c;tmp){
			c.val=0;
			c.fg=0;
			c.bg=0;
		}
		for(y=0;y<height;y++){
			if(y>=h)
				break;
			for(x=0;x<width;x++){
				int src,dst;
				if(x>=w)
					break;
				src=x+y*width;
				dst=x+y*w;
				if(src>=cells.length)
					break;
				if(dst>=tmp.length)
					break;
				tmp[dst]=cells[src];
			}
		}
		width=w;
		height=h;
		cells=tmp;
	}
					 
};
IMAGE[] images;
int current_image=0;
const char *vgargb=import("vga737.bin");



int paint_image(HWND hwnd,HDC hdc)
{
	int result=FALSE;
	int i,cell_count;
	int xoffset,yoffset;
	struct TMP{
		BITMAPINFOHEADER bmiHeader;
		DWORD[2] colors;
	}
	TMP bmi;
	const char *font=vgargb;
	IMAGE *img;

	if(current_image<0 || current_image>=images.length)
		return result;
	img=&images[current_image];

	bmi.bmiHeader.biBitCount=8;
	bmi.bmiHeader.biWidth=8;
	bmi.bmiHeader.biHeight=12;
	bmi.bmiHeader.biPlanes=1;
	bmi.bmiHeader.biSizeImage=8*12;
	bmi.bmiHeader.biXPelsPerMeter=12;
	bmi.bmiHeader.biYPelsPerMeter=12;
	bmi.bmiHeader.biSize=BITMAPINFOHEADER.sizeof;
	xoffset=0;
	yoffset=0;

	for(i=0;i<img.cells.length;i++){
		ushort a;
		int x,y;
		CELL *cell=&img.cells[i];
		bmi.colors[0]=cell.bg;
		bmi.colors[1]=cell.fg;
		a=cell.val&0xFF;
		x=i%img.width;
		x*=8;
		x+=xoffset;
		y=i/img.width;
		y*=12;
		y+=yoffset;
		SetDIBitsToDevice(hdc,x,y,8,12,
						  0,0, //src xy
						  0,12, //startscan,scanlines
						  font+a*12*8,
						  cast(BITMAPINFO*)&bmi,DIB_RGB_COLORS);
	}
	{
		RECT rect;
		rect.left=img.cursor.x*8;
		rect.left+=xoffset;
		rect.top=img.cursor.y*12;
		rect.top+=yoffset;
		rect.right=rect.left+8;
		rect.bottom=rect.top+12;
		DrawFocusRect(hdc,&rect);
	}
	return 0;

	return result;
}

void init_image()
{
	IMAGE *img;
	images.length=1;
	img=&images[0];
	img.resize_image(80,40);
}