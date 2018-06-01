module image;

import core.sys.windows.windows;
import core.stdc.stdlib;

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
	string fname;
	void resize_image(int w,int h){
		CELL[] tmp;
		int x,y;
		tmp.length=w*h;
		foreach(ref c;tmp){
			c.val=0;
			c.fg=0;
			c.bg=1;
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
	int selection_width()
	{
		return selection.left-selection.right;
	}
	int selection_height()
	{
		return selection.bottom-selection.top;
	}
	void emit_color_str(ref string buf,int val,int full)
	{
		int result=0;
		int i,div;
		if(val<0 || val>99)
			val=0;
		div=10;
		for(i=0;i<2;i++){
			int x=val/div;
			x=x%10;
			div=1;
			if(!full){
				if(0==i && 0==x)
					continue;
			}
			buf~=cast(char)(x+'0');
		}
	}
	int is_cell_num(int x,int y)
	{
		int result=FALSE;
		if(x>=0 && x<width){
			if(y>=0 && y<height){
				int a;
				CELL *c=&cells[x+y*width];
				a=c.val;
				if(a>='0' && a<='9')
					result=TRUE;
			}
		}
		return result;
	}
	string get_text()
	{
		int i,j;
		string result="";
		for(i=0;i<height;i++){
			CELL tmp={0xFFFF,-1,-1};
			for(j=0;j<width;j++){
				int emit_bg=FALSE;
				int emit_fg=FALSE;
				int index;
				CELL *c;
				index=j+i*width;
				if(index>=cells.length)
					break;
				c=&cells[index];
				if(c.bg!=tmp.bg)
					emit_bg=TRUE;
				if(c.fg!=tmp.fg)
					emit_fg=TRUE;
				if(emit_fg || emit_bg){
					result~=3;
					if(emit_fg){
						int full=FALSE;
						if(!emit_bg)
							full=is_cell_num(j+1,i);
						emit_color_str(result,c.fg,full);
					}
					if(emit_bg){
						int full=is_cell_num(j+1,i);
						result~=',';
						emit_color_str(result,c.bg,full);
					}
				}
				tmp=*c;
			}
			result~='\n';
		}
		return result;
	}

};
IMAGE[] images;
int current_image=0;
ubyte *vgargb;

void create_vga_font()
{
	import vga737;
	import unicode_font;
	const int vga_count=vga737_bin.length;
	const int total=vga737_bin.length+block_elements.length;
	if(vgargb is null)
		vgargb=cast(ubyte*)calloc(8*12*total,1);
	if(vgargb){
		int i,j,k;
		for(k=0;k<total;k++){
			for(i=0;i<12;i++){
				for(j=0;j<8;j++){
					int c;
					ubyte *font=vga737_bin.ptr;
					ubyte *p;
					int offset=k*12;
					if(k>=vga_count){
						font=block_elements.ptr;
						offset=(k-vga_count)*12;
					}
					p=font+offset;
					if(p[i]&(1<<(7-j)))
						c=1;
					else
						c=0;
					//flip y
					vgargb[k*8*12+j+(11-i)*8]=cast(ubyte)c;
				}
			}
		}
	}
}

int paint_image(HWND hwnd,HDC hdc)
{
	import palette;
	int result=FALSE;
	int i,cell_count;
	int xoffset,yoffset;
	struct TMP{
		BITMAPINFOHEADER bmiHeader;
		DWORD[2] colors;
	}
	TMP bmi;
	const ubyte *font=vgargb;
	IMAGE *img;

	if(current_image<0 || current_image>=images.length)
		return result;
	if(font is null)
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
		bmi.colors[0]=get_rgb_color(cell.bg);
		bmi.colors[1]=get_rgb_color(cell.fg);
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
	RECT rect;
	rect.left=img.cursor.x*8;
	rect.left+=xoffset;
	rect.top=img.cursor.y*12;
	rect.top+=yoffset;
	rect.right=rect.left+8;
	rect.bottom=rect.top+12;
	DrawFocusRect(hdc,&rect);

	if(img.selection_width>0 || img.selection_height>0){
		rect=img.selection;
		rect.left*=8;
		rect.right*=8;
		rect.top*=12;
		rect.bottom*=12;
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
	create_vga_font();
}