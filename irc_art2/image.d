module image;

import core.sys.windows.windows;
import core.stdc.stdlib;
import core.stdc.string;

nothrow:
struct CELL{
	WCHAR val;
	int fg;
	int bg;
};
struct CLIP{
nothrow:
	CELL[] cells;
	int width;
	int height;
	int x,y;
	int is_valid_pos(int x,int y){
		if(x>=width || x<0)
			return false;
		if(y>=height || y<0)
			return false;
		int index=x+y*width;
		if(index>=cells.length)
			return false;
		return true;
	}
};
int is_cell_num(CELL[] cells,int width,int height,int x,int y)
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
string get_text_cells(CELL[] cells,int width,int height)
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
				if(emit_fg || emit_bg){
					int full=FALSE;
					if(!emit_bg)
						full=is_cell_num(cells,width,height,j+1,i);
					emit_color_str(result,c.fg,full);
				}
				if(emit_bg){
					int full=is_cell_num(cells,width,height,j+1,i);
					result~=',';
					emit_color_str(result,c.bg,full);
				}
			}
			WCHAR a=c.val;
			if(a<' ')
				a=' ';
			result~=a;
			tmp=*c;
		}
		result~="\r\n";
	}
	return result;
}

struct IMAGE{
nothrow:
	CELL[] cells;
	CLIP clip;
	int width;
	int height;
	int cell_width=8,cell_height=12;
	int is_modified;
	POINT cursor;
	RECT selection;
	wstring fname;
	int cursor_in_clip(){
		int result=false;
		if(0==clip.cells.length || 0==clip.width || 0==clip.height)
			return result;
		if(cursor.x>=clip.x && cursor.x<(clip.x+clip.width)){
			if(cursor.y>=clip.y && cursor.y<(clip.y+clip.height)){
				result=true;
			}
		}
		return result;
	}
	int is_valid_pos(int x,int y){
		if(x>=width || x<0)
			return false;
		if(y>=height || y<0)
			return false;
		int index=x+y*width;
		if(index>=cells.length)
			return false;
		return true;
	}
	void set_char(int val,int x,int y){
		if(!is_valid_pos(x,y))
			return;
		int index=x+y*width;
		cells[index].val=cast(WCHAR)val;
		is_modified=true;
	}
	void set_fg(int val,int x,int y){
		if(!is_valid_pos(x,y))
			return;
		int index=x+y*width;
		cells[index].fg=val;
		is_modified=true;
	}
	void set_bg(int val,int x,int y){
		if(!is_valid_pos(x,y))
			return;
		int index=x+y*width;
		cells[index].bg=val;
		is_modified=true;
	}
	void move_cursor(int x,int y){
		cursor.x+=x;
		cursor.y+=y;
		if(cursor.x<0)
			cursor.x=width-1;
		if(cursor.y<0)
			cursor.y=height-1;
		if(cursor.x>=width)
			cursor.x=0;
		if(cursor.y>=height)
			cursor.y=0;
		if(cursor.x<0)
			cursor.x=0;
		if(cursor.y<0)
			cursor.y=0;
		is_modified=true;
	}
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
		is_modified=true;
		memset(&selection,0,selection.sizeof);
	}
	int selection_width()
	{
		return selection.right-selection.left;
	}
	int selection_height()
	{
		return selection.bottom-selection.top;
	}
	void clear_selection(){
		memset(&selection,0,selection.sizeof);
	}
	void clear_clip(){
		clip.cells.length=0;
		clip.width=0;
		clip.height=0;
	}
	string get_text(){
		return get_text_cells(cells,width,height);
	}
};
IMAGE[] images;
int current_image=0;
ubyte *vgargb;

IMAGE *get_current_image()
{
	if(current_image<0 || current_image>=images.length)
		return null;
	return &images[current_image];
}
void create_vga_font()
{
	import fonts;
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
int image_click(IMAGE *img,int x,int y)
{
	int result=false;
	if(img is null)
		return result;
	if(0==img.cell_width || 0==img.cell_height)
		return result;
	x=x/img.cell_width;
	y=y/img.cell_height;
	if(x>=img.width || y>=img.height)
		return result;
	if((img.cursor.x != x) || (img.cursor.y != y))
		img.is_modified=true;
	img.cursor.x=x;
	img.cursor.y=y;
	result=true;
	return result;
}

int draw_cells(HDC hdc,RECT *rect,ref CELL[] cells,int row_width,int cell_width,int cell_height,
			   int xoffset,int yoffset,
			   const ubyte *font)
{
	import palette;
	int result;
	struct TMP{
		BITMAPINFOHEADER bmiHeader;
		DWORD[2] colors;
	}
	TMP bmi;
	int i;
	bmi.bmiHeader.biBitCount=8;
	bmi.bmiHeader.biWidth=cell_width;
	bmi.bmiHeader.biHeight=cell_height;
	bmi.bmiHeader.biPlanes=1;
	bmi.bmiHeader.biSizeImage=cell_width*cell_height;
	bmi.bmiHeader.biXPelsPerMeter=0;
	bmi.bmiHeader.biYPelsPerMeter=0;
	bmi.bmiHeader.biSize=BITMAPINFOHEADER.sizeof;
	for(i=0;i<cells.length;i++){
		int x,y;
		x=i%row_width;
		x+=xoffset;
		x*=cell_width;
		y=i/row_width;
		y+=yoffset;
		y*=cell_height;
		if(x>=rect.right)
			continue;
		if(y>=rect.bottom)
			continue;
		CELL *cell=&cells[i];
		ushort a;
		bmi.colors[0]=get_rgb_color(cell.bg);
		bmi.colors[1]=get_rgb_color(cell.fg);
		a=cell.val&0xFF;
		SetDIBitsToDevice(hdc,x,y,cell_width,cell_height,
						  0,0, //src xy
						  0,cell_height, //startscan,scanlines
						  font+a*8*12,
						  cast(BITMAPINFO*)&bmi,DIB_RGB_COLORS);
	}
	return result;
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

	if(font is null)
		return result;
	img=get_current_image();
	if(img is null)
		return result;

	RECT rect;
	GetClientRect(hwnd,&rect);

	bmi.bmiHeader.biBitCount=8;
	bmi.bmiHeader.biWidth=img.cell_width;
	bmi.bmiHeader.biHeight=img.cell_height;
	bmi.bmiHeader.biPlanes=1;
	bmi.bmiHeader.biSizeImage=img.cell_width*img.cell_height;
	bmi.bmiHeader.biXPelsPerMeter=0;
	bmi.bmiHeader.biYPelsPerMeter=0;
	bmi.bmiHeader.biSize=BITMAPINFOHEADER.sizeof;
	xoffset=0;
	yoffset=0;


	draw_cells(hdc,&rect,img.cells,img.width,img.cell_width,img.cell_height,
				   xoffset,yoffset,font);

	if(img.clip.cells.length>0){
		draw_cells(hdc,&rect,img.clip.cells,img.clip.width,img.cell_width,img.cell_height,
				   img.clip.x,img.clip.y,font);
		rect.left=img.clip.x*img.cell_width;
		rect.top=img.clip.y*img.cell_height;
		rect.right=rect.left+img.clip.width*img.cell_width;
		rect.bottom=rect.top+img.clip.height*img.cell_height;
		DrawFocusRect(hdc,&rect);
	}

/*
	for(i=0;i<img.cells.length;i++){
		ushort a;
		int x,y;
		CELL *cell=&img.cells[i];
		bmi.colors[0]=get_rgb_color(cell.bg);
		bmi.colors[1]=get_rgb_color(cell.fg);
		a=cell.val&0xFF;
		x=i%img.width;
		x*=img.cell_width;
		x+=xoffset;
		y=i/img.width;
		y*=img.cell_height;
		y+=yoffset;
		SetDIBitsToDevice(hdc,x,y,img.cell_width,img.cell_height,
						  0,0, //src xy
						  0,img.cell_height, //startscan,scanlines
						  font+a*img.cell_width*img.cell_height,
						  cast(BITMAPINFO*)&bmi,DIB_RGB_COLORS);
	}
*/
	rect.left=img.cursor.x*img.cell_width;
	rect.left+=xoffset;
	rect.top=img.cursor.y*img.cell_height;
	rect.top+=yoffset;
	rect.right=rect.left+img.cell_width;
	rect.bottom=rect.top+img.cell_height;
	DrawFocusRect(hdc,&rect);

	if(img.selection_width>0 || img.selection_height>0){
		rect=img.selection;
		rect.left*=img.cell_width;
		rect.right*=img.cell_width;
		rect.top*=img.cell_height;
		rect.bottom*=img.cell_height;
		DrawFocusRect(hdc,&rect);
	}
	return 0;

	return result;
}

void do_fill(IMAGE *img,int fg,int bg)
{
	if(img is null)
		return;
	int sw,sh;
	sw=img.selection_width();
	sh=img.selection_height();
	if(sw<=0 || sh<=0){

	}else{
		int i,j;
		for(i=0;i<sh;i++){
			for(j=0;j<sw;j++){
				int x,y;
				x=img.selection.left+j;
				y=img.selection.top+i;
				if(fg>=0)
					img.set_fg(fg,x,y);
				if(bg>=0)
					img.set_bg(bg,x,y);
			}
		}
	}
}
enum{LEFT,RIGHT,TOP,BOTTOM}
int get_closest_corner(int cursor_x,int cursor_y,RECT *rect)
{
	int result=LEFT;
	int[BOTTOM+1] vals;
	int i,distance;
	vals[LEFT]=abs(cursor_x-rect.left);
	vals[RIGHT]=abs(rect.right-cursor_x);
	vals[TOP]=abs(cursor_y-rect.top);
	vals[BOTTOM]=abs(rect.bottom-cursor_y);
	distance=int.max;
	for(i=0;i<vals.length;i++){
		if(vals[i]<distance){
			result=i;
			distance=vals[i];
		}
	}
	return result;
}
void flip_clip(IMAGE *img)
{
	if(img is null)
		return;
	if(!img.cursor_in_clip())
		return;
	enum{VERTICAL,HORIZONTAL}
	CLIP clip;
	RECT rect;
	int side,flip;
	rect.left=img.clip.x;
	rect.top=img.clip.y;
	rect.right=img.clip.x+img.clip.width;
	rect.bottom=img.clip.y+img.clip.height;
	side=get_closest_corner(img.cursor.x,img.cursor.y,&rect);
	flip=VERTICAL;
	if(LEFT==side || RIGHT==side)
		flip=HORIZONTAL;
	int i,j;
	clip=img.clip;
	clip.cells=img.clip.cells.dup;
	for(i=0;i<clip.height;i++){
		for(j=0;j<clip.width;j++){
			int src_index,dst_index;
			if(VERTICAL==flip){
				src_index=j+(clip.width*(clip.height-i-1));
				dst_index=j+(clip.width*i);
			}else{
				src_index=(clip.width-j-1)+(clip.width*i);
				dst_index=j+(clip.width*i);
			}
			clip.cells[dst_index]=img.clip.cells[src_index];
		}
	}
	img.clip=clip;
	img.is_modified=true;
}
void init_image()
{
	IMAGE *img;
	images.length=1;
	img=&images[0];
	img.resize_image(80,40);
	create_vga_font();
}