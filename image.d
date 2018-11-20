module image;

import core.sys.windows.windows;
import core.stdc.stdlib;
import core.stdc.string;
import qblock;

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
	bool is_modified;
	bool qblock_mode;
	bool show_grid;
	DWORD time;
	POINT cursor;
	POINT qbpos,pre_qbpos;
	POINT pre_click;
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
	bool get_index_pos(int x,int y,ref int index){
		if(x>=width || x<0)
			return false;
		if(y>=height || y<0)
			return false;
		index=x+y*width;
		if(index>=cells.length)
			return false;
		return true;
	}
	void set_char(int val,int x,int y){
		int index;
		if(!get_index_pos(x,y,index))
			return;
		cells[index].val=cast(WCHAR)val;
		is_modified=true;
	}
	void set_fg(int val,int x,int y){
		int index;
		if(!get_index_pos(x,y,index))
			return;
		cells[index].fg=val;
		is_modified=true;
	}
	void set_bg(int val,int x,int y){
		int index;
		if(!get_index_pos(x,y,index))
			return;
		cells[index].bg=val;
		is_modified=true;
	}
	int get_fg(int x,int y){
		int index;
		if(!get_index_pos(x,y,index))
			return -1;
		return cells[index].fg;
	}
	int get_bg(int x,int y){
		int index;
		if(!get_index_pos(x,y,index))
			return -1;
		return cells[index].bg;
	}
	ushort get_char(int x,int y){
		int index;
		if(!get_index_pos(x,y,index))
			return 0;
		return cells[index].val;
	}
	void move_cursor(int x,int y){
		int scale=2;
		if(qblock_mode)
			scale=1;
		int a,b;
		a=cursor.x*2;
		b=cursor.y*2;
		a+=qbpos.x;
		b+=qbpos.y;
		a+=x*scale;
		b+=y*scale;
		if(a>=(width*2))
			a=(width*2)-1;
		if(a<0)
			a=0;
		if(b>=(height*2))
			b=(height*2)-1;
		if(b<0)
			b=0;
		qbpos.x=a&1;
		qbpos.y=b&1;
		cursor.x=a/2;
		cursor.y=b/2;
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
		is_modified=true;
	}
	string get_text(){
		return get_text_cells(cells,width,height);
	}
	string get_clip_text(){
		return get_text_cells(clip.cells,clip.width,clip.height);
	}
};
struct CUSTOM_WINDOW{
	nothrow:
	BYTE[] pixels; //BGR format
	int width;
	int height;
	const ushort PIXEL_SIZE=4;
	void set_size(int w,int h){
		int len;
		width=w;
		height=h;
		len=w*h*PIXEL_SIZE;
		if(pixels.length!=len){
			pixels.length=len;
		}
	}
	bool get_index(int x,int y,ref int index){
		if(x<0 || x>=width)
			return false;
		if(y<0 || y>=height)
			return false;
		x=x*PIXEL_SIZE;
		y=(height-1)*width*PIXEL_SIZE-y*width*PIXEL_SIZE;
		index=x+y;
		if((index+PIXEL_SIZE-1)>=pixels.length)
			return false;
		else if(index<0)
			return false;
		return true;
	}
	void set_pixel(int x,int y,int RGB){
		int index;
		if(!get_index(x,y,index))
			return;
		pixels[index]=cast(BYTE)RGB;
		pixels[index+1]=cast(BYTE)(RGB>>8);
		pixels[index+2]=cast(BYTE)(RGB>>16);
		pixels[index+3]=0;
	}
	int get_pixel(int x,int y){
		int result=0;
		int index;
		if(!get_index(x,y,index))
			return result;
		result=pixels[index];
		result|=pixels[index+1]<<8;
		result|=pixels[index+2]<<16;
		return result;
	}
	void draw_line(POINT a,POINT b,int function(int current_color,int x,int y)nothrow next_color){
		if(a.x==b.x){ //vert
			int i,start,end;
			int x;
			if(a.y<b.y){
				start=a.y;
				end=b.y;
			}else{
				start=b.y;
				end=a.y;
			}
			x=a.x;
			for(i=start;i<=end;i++){
				int c=get_pixel(x,i);
				c=next_color(c,x,i);
				set_pixel(x,i,c);
			}
		}else if(a.y==b.y){ //hori
			int i,start,end;
			int y;
			if(a.x<b.x){
				start=a.x;
				end=b.x;
			}else{
				start=b.x;
				end=a.x;
			}
			y=a.y;
			for(i=start;i<=end;i++){
				int c=get_pixel(i,y);
				c=next_color(c,i,y);
				set_pixel(i,y,c);
			}
		}
	}
	void fill_rect(RECT r,int rgb){
		int i,j;
		for(i=r.left;i<r.right;i++){
			for(j=r.top;j<r.bottom;j++){
				set_pixel(i,j,rgb);
			}
		}
	}
};
IMAGE[] images;
IMAGE[] undo_buffer;
IMAGE[] redo_buffer;
int current_image=0;
ubyte[] vgargb;
CUSTOM_WINDOW image_window;

void push_undo_time(IMAGE *img)
{
	DWORD delta,tick=GetTickCount();
	delta=tick-img.time;
	if(delta>3000){
		img.time=tick;
		push_undo(img);
	}
}
void push_undo(IMAGE *img)
{
	enum MAX_UNDO=500;
	enum UNDO_WINDOW=MAX_UNDO/5;
	undo_buffer~=*img;
	undo_buffer[$-1].cells=img.cells.dup;
	if(undo_buffer.length>=MAX_UNDO){
		import std.algorithm.mutation;
		import std.typecons;
		int i;
		for(i=0;i<UNDO_WINDOW;i++){
			undo_buffer[i].cells.length=0;
		}
		undo_buffer=remove(undo_buffer,tuple(0,UNDO_WINDOW));
	}
	if(redo_buffer.length>0){
		redo_buffer[$-1].cells.length=0;
		redo_buffer.length-=1;
	}
}
void pop_undo(IMAGE *img)
{
	if(undo_buffer.length==0)
		return;
	redo_buffer~=*img;
	redo_buffer[$-1].cells=img.cells.dup;
	img.cells.length=0;

	*img=undo_buffer[$-1];
	undo_buffer.length-=1;
	img.is_modified=true;
}
void redo(IMAGE *img)
{
	if(redo_buffer.length==0)
		return;
	undo_buffer~=*img;
	undo_buffer[$-1].cells=img.cells.dup;
	img.cells.length=0;

	*img=redo_buffer[$-1];
	redo_buffer.length-=1;
	img.is_modified=true;
}
IMAGE *get_current_image()
{
	if(current_image<0 || current_image>=images.length){
		static IMAGE tmp;
		tmp.resize_image(0,0);
		tmp.clip.cells.length=0;
		tmp.clip.width=0;
		tmp.clip.height=0;
		return &tmp;
	}
	return &images[current_image];
}
void create_vga_font()
{
	import fonts;
	const int vga_count=vga737_bin.length;
	const int total=vga737_bin.length;
	if(vgargb.length==0)
		vgargb.length=8*12*total;
	if(vgargb.length>0){
		int i,j,k;
		for(k=0;k<total;k++){
			for(i=0;i<12;i++){
				for(j=0;j<8;j++){
					int c;
					ubyte *font=vga737_bin.ptr;
					ubyte *p;
					int offset=k*12;
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

int image_click(IMAGE *img,short ox,short oy)
{
	int result=false;
	int x,y;
	if(img is null)
		return result;
	if(0==img.cell_width || 0==img.cell_height)
		return result;
	x=ox/img.cell_width;
	y=oy/img.cell_height;
	if(x>=img.width || y>=img.height)
		return result;
	if((img.cursor.x != x) || (img.cursor.y != y))
		img.is_modified=true;
	img.pre_click.x=img.cursor.x;
	img.pre_click.y=img.cursor.y;
	img.cursor.x=x;
	img.cursor.y=y;
	x=ox%img.cell_width;
	y=oy%img.cell_height;
	img.pre_qbpos=img.qbpos;
	img.qbpos.x=0;
	img.qbpos.y=0;
	if(x>=img.cell_width/2)
		img.qbpos.x=1;
	if(y>=img.cell_height/2)
		img.qbpos.y=1;
	result=true;
	return result;
}

int draw_cells(HDC hdc,RECT *clip,ref CELL[] cells,int row_width,int cell_width,int cell_height,
			   int xoffset,int yoffset,
			   const ubyte[] font)
{
	import palette;
	import fonts;
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
		if(x>=clip.right)
			continue;
		if(y>=clip.bottom)
			continue;
		CELL *cell=&cells[i];
		bmi.colors[0]=get_rgb_color(cell.bg);
		bmi.colors[1]=get_rgb_color(cell.fg);
		int font_offset=get_font_offset(cell.val);
		if(font_offset>=font.length)
			continue;
		SetDIBitsToDevice(hdc,x,y,cell_width,cell_height,
						  0,0, //src xy
						  0,cell_height, //startscan,scanlines
						  font.ptr+font_offset,
						  cast(BITMAPINFO*)&bmi,DIB_RGB_COLORS);
	}
	return result;
}

int image_focus_flag=0;
void get_active_rect(RECT *rect)
{
	rect.bottom=rect.top;
	rect.top-=3;
	rect.right=rect.left+100;
	return;
}
void paint_image_active(HDC hdc,RECT rect,int active)
{
	static HBRUSH hactive;
	if(hactive is null)
		hactive=CreateSolidBrush(RGB(0xFF,0,0));
	if(hactive){
		HRGN hrgn;
		RECT tmp=rect;
		get_active_rect(&tmp);
		hrgn=CreateRectRgnIndirect(&tmp);
		if(hrgn){
			HBRUSH hbr=hactive;
			if(!active)
				hbr=GetSysColorBrush(COLOR_BTNFACE);
			FillRgn(hdc,hrgn,hbr);
			DeleteObject(hrgn);
		}
	}
}
void set_focus_flag(HWND hwnd,int active)
{
	RECT rect;
	HWND hparent=GetParent(hwnd);
	GetWindowRect(hwnd,&rect);
	MapWindowPoints(HWND_DESKTOP,hparent,cast(POINT*)&rect,2);
	get_active_rect(&rect);
	RedrawWindow(hparent,&rect,NULL,RDW_INVALIDATE);
	image_focus_flag=active;
}
void scale_rect(ref RECT rect,int w,int h)
{
	rect.left*=w;
	rect.right*=w;
	rect.top*=h;
	rect.bottom*=h;
}
void draw_grid(IMAGE *img)
{
	int i;
	for(i=0;i<img.width;i++){
		int x,y;
		x=i*img.cell_width;
		y=img.height*img.cell_height;
	}
}

void draw_cells2(int width,int height,
				 int xoffset,int yoffset,
				 CELL[] cells,
				 int cell_width,int cell_height)
{
	int x,y;
	for(x=0;x<width;x++){
		for(y=0;y<height;y++){
			import fonts;
			import palette;
			int fg,bg;
			WCHAR c;
			int index;
			index=x+y*width;
			if(index>=cells.length)
				continue;
			fg=cells[index].fg;
			bg=cells[index].bg;
			c=cells[index].val;
			index=get_font_offset(c);
			index/=8;
			if((index+11)>=vga737_bin.length || index<0){
				index=0;
			}
			int i,j;
			int x1,y1;
			x1=x*cell_width;
			y1=y*cell_height;
			x1+=xoffset;
			y1+=yoffset;
			fg=get_rgb_color(fg);
			bg=get_rgb_color(bg);
			for(i=0;i<12;i++){
				ubyte row=vga737_bin[index+i];
				for(j=0;j<8;j++){
					int bit=1<<(7-j);
					if(bit&row)
						image_window.set_pixel(x1+j,y1+i,fg);
					else
						image_window.set_pixel(x1+j,y1+i,bg);
				}
			}
		}
	}
}
int stipple_pattern_hori(int ccolor,int x,int y)
{
	int a;
	BYTE r,g,b;
	r=cast(BYTE)(ccolor>>16);
	g=cast(BYTE)(ccolor>>8);
	b=cast(BYTE)ccolor;
	a=x&1;
	if(a){
		r+=0x2f;
		b+=0x2f;
		g+=0x2f;
		ccolor=(r<<16)|(g<<8)|b;
	}else{
		r-=0x2f;
		b-=0x2f;
		g-=0x2f;
		ccolor=(r<<16)|(g<<8)|b;
	}
	return ccolor;
}
int stipple_pattern_vert(int ccolor,int x,int y)
{
	int a;
	BYTE r,g,b;
	r=cast(BYTE)(ccolor>>16);
	g=cast(BYTE)(ccolor>>8);
	b=cast(BYTE)ccolor;
	a=y&1;
	if(a){
		r+=0x2f;
		b+=0x2f;
		g+=0x2f;
		ccolor=(r<<16)|(g<<8)|b;
	}else{
		r-=0x2f;
		b-=0x2f;
		g-=0x2f;
		ccolor=(r<<16)|(g<<8)|b;
	}
	return ccolor;
}
void draw_stipple_rect(RECT rect)
{
	POINT a,b;
	a.x=rect.left;
	a.y=rect.top;
	b.x=rect.right;
	b.y=rect.top;
	image_window.draw_line(a,b,&stipple_pattern_hori);
	a.y=rect.bottom;
	b.y=rect.bottom;
	image_window.draw_line(a,b,&stipple_pattern_hori);
	a.x=rect.left;
	a.y=rect.top+1;
	b.x=rect.left;
	b.y=rect.bottom-1;
	image_window.draw_line(a,b,&stipple_pattern_vert);
	a.x=rect.right;
	b.x=rect.right;
	image_window.draw_line(a,b,&stipple_pattern_vert);
}

int paint_image2(HWND hwnd,HDC hdc)
{
	import core.stdc.stdio;
	int result=FALSE;
	int xoffset,yoffset;
	const ubyte[] font=vgargb;
	IMAGE *img;

	if(font is null)
		return result;
	img=get_current_image();
	if(img is null)
		return result;

	RECT rect;
	int w,h,_w,_h;
	//GetClientRect(hwnd,&rect);
	//w=rect.right-rect.left;
	//h=rect.bottom-rect.top;
	_w=img.width*img.cell_width;
	_h=img.height*img.cell_height;
	//w=min(_w,w);
	//h=min(_h,h);
	w=_w;
	h=_h;
	image_window.set_size(w,h);
	draw_cells2(img.width,img.height,0,0,
				img.cells,
				img.cell_width,img.cell_height);
	if(img.clip.width>0 && img.clip.height>0){
		draw_cells2(img.clip.width,img.clip.height,img.clip.x*img.cell_width,img.clip.y*img.cell_height,
					img.clip.cells,
					img.cell_width,img.cell_height);
		rect.left=img.clip.x;
		rect.top=img.clip.y;
		rect.right=rect.left+img.clip.width;
		rect.bottom=rect.top+img.clip.height;
		rect.left*=img.cell_width;
		rect.right*=img.cell_width;
		rect.top*=img.cell_height;
		rect.bottom*=img.cell_height;
		draw_stipple_rect(rect);
	}

	//draw grid
	{
		if(img.show_grid){
			int x,y;
			for(x=0;x<img.width;x++){
				POINT a,b;
				a.x=x*img.cell_width;
				a.y=0;
				b.x=a.x;
				b.y=img.height*img.cell_height;
				image_window.draw_line(a,b,&stipple_pattern_vert);
			}
			for(y=0;y<img.height;y++){
				POINT a,b;
				a.x=0;
				a.y=y*img.cell_height;
				b.x=img.width*img.cell_width;
				b.y=a.y;
				image_window.draw_line(a,b,&stipple_pattern_vert);
			}
		}
	}
	//draw selection
	{
		if(img.selection_height()>0 && img.selection_width()>0){
			rect=img.selection;
			scale_rect(rect,img.cell_width,img.cell_height);
			draw_stipple_rect(rect);
		}
	}
	//draw focus
	{
		int x,y;
		if(img.qblock_mode){
			rect.left=img.cursor.x*img.cell_width;
			rect.left+=(img.cell_width/2)*img.qbpos.x;
			rect.right=rect.left+img.cell_width/2;
			rect.top=img.cursor.y*img.cell_height;
			rect.top+=(img.cell_height/2)*img.qbpos.y;
			rect.bottom=rect.top+(img.cell_height/2);
		}else{
			rect.left=img.cursor.x*img.cell_width;
			rect.right=rect.left+img.cell_width;
			rect.top=img.cursor.y*img.cell_height;
			rect.bottom=rect.top+img.cell_height;
		}
		draw_stipple_rect(rect);
	}
	struct TMP{
		BITMAPINFOHEADER bmiHeader;
		DWORD[2] colors;
	}
	TMP bmi;
	bmi.bmiHeader.biBitCount=32;
	bmi.bmiHeader.biWidth=image_window.width;
	bmi.bmiHeader.biHeight=image_window.height;
	bmi.bmiHeader.biPlanes=1;
	bmi.bmiHeader.biSize=bmi.sizeof;
	SetDIBitsToDevice(hdc,0,0,image_window.width,image_window.height,
					  0,0, //src xy
					  0,image_window.height, //startscan,scanlines
					  image_window.pixels.ptr,
					  cast(BITMAPINFO*)&bmi,DIB_RGB_COLORS);

	return 0;
}
int paint_image(HWND hwnd,HDC hdc)
{
	paint_image2(hwnd,hdc);
	return 0;
	/*
	int result=FALSE;
	int xoffset,yoffset;
	const ubyte[] font=vgargb;
	IMAGE *img;

	if(font is null)
		return result;
	img=get_current_image();
	if(img is null)
		return result;

	RECT clip;
	GetClientRect(hwnd,&clip);

	xoffset=0;
	yoffset=0;

	draw_cells(hdc,&clip,img.cells,img.width,img.cell_width,img.cell_height,
				   xoffset,yoffset,font);

	if(img.clip.cells.length>0){
		draw_cells(hdc,&clip,img.clip.cells,img.clip.width,img.cell_width,img.cell_height,
				   img.clip.x,img.clip.y,font);
		RECT rect;
		rect.left=img.clip.x;
		rect.right=img.clip.x+img.clip.width;
		rect.top=img.clip.y;
		rect.bottom=img.clip.y+img.clip.height;
		scale_rect(rect,img.cell_width,img.cell_height);
		draw_focus_rect(img,hdc,rect);
	}

	RECT rect;
	rect.left=img.cursor.x;
	rect.right=rect.left+1;
	rect.top=img.cursor.y;
	rect.bottom=rect.top+1;
	scale_rect(rect,img.cell_width,img.cell_height);
	if(img.qblock_mode){
		int dx,dy;
		dx=img.cell_width/2;
		dy=img.cell_height/2;
		if(img.qbpos.x==0)
			rect.right-=dx;
		else
			rect.left+=dx;
		if(img.qbpos.y==0)
			rect.bottom-=dy;
		else
			rect.top+=dy;
	}
	draw_focus_rect(img,hdc,rect);

	if(img.selection_width>0 || img.selection_height>0){
		rect=img.selection;
		scale_rect(rect,img.cell_width,img.cell_height);
		draw_focus_rect(img,hdc,rect);
	}
	return result;
	*/
}
int is_bad_inverse(int color)
{
	int result=false;
	const int[] bad_colors=[
		14,93,94,95,96,97,7,53
	];
	foreach(c;bad_colors){
		if(color==c){
			result=true;
			break;
		}
	}
	return result;
}
void draw_focus_rect(IMAGE *img,HDC hdc,RECT rect)
{
	RECT tmp=rect;
	DrawFocusRect(hdc,&tmp);

	int select=false;
	enum{TOP,BOTTOM,LEFT,RIGHT}
	void pat_fill(int i,int j,int side){
		int tx,ty;
		tx=i;
		ty=j;
		if(side==RIGHT)
			tx--;
		else if(side==BOTTOM)
			ty--;
		if(img.is_valid_pos(tx,ty)){
			int index=tx+ty*img.width;
			int c=img.cells[index].bg;
			if(is_bad_inverse(c)){
				static HBRUSH hbr;
				if(hbr is null)
					hbr=CreateSolidBrush(RGB(0xFF,0,0));
				if(hbr){
					if(!select){
						SelectObject(hdc,hbr);
						select=true;
					}
					int x,y,w,h;
					x=i;
					y=j;
					if(side==LEFT || side==RIGHT){
						w=1;
						h=img.cell_height;
						if(side==RIGHT){
							x--;
						}
					}else{
						w=img.cell_width;
						h=1;
						if(side==BOTTOM){
							y--;
						}
					}
					PatBlt(hdc,x,y,w,h,PATCOPY);
				}
			}
		}
	}
	int i;
	for(i=rect.left;i<rect.right;i++){
		pat_fill(i,rect.top,TOP);
		pat_fill(i,rect.bottom,BOTTOM);
	}
	for(i=rect.top;i<rect.bottom;i++){
		pat_fill(rect.left,i,LEFT);
		pat_fill(rect.right,i,RIGHT);
	}

}
int min(int a,int b)
{
	return a<b?a:b;
}
int max(int a,int b)
{
	return a>b?a:b;
}

void draw_line(IMAGE *img,int ox,int oy,int x,int y,int fg,int bg,int fill)
{
	int dx,dy;
	int minx,miny;
	dx=ox-x;
	dy=oy-y;
	minx=min(ox,x);
	miny=min(oy,y);
	if(0==dy){
		int i;
		dx=abs(dx);
		for(i=0;i<=dx;i++){
			if(fg>=0)
				img.set_fg(fg,minx+i,miny);
			if(bg>=0)
				img.set_bg(bg,minx+i,miny);
			if(fill)
				img.set_char(fill,minx+i,miny);
		}
	}else if(0==dx){
		int i;
		dy=abs(dy);
		for(i=0;i<=dy;i++){
			if(fg>=0)
				img.set_fg(fg,minx,miny+i);
			if(bg>=0)
				img.set_bg(bg,minx,miny+i);
			if(fill)
				img.set_char(fill,minx,miny+i);
		}
	}else{
		int i;
		int adx;
		double m;
		m=cast(double)dy/dx;
		adx=abs(dx);
		if(minx==ox)
			miny=oy;
		else
			miny=y;
		int pos=0;
		for(i=0;i<=adx;i++){
			int d=cast(int)(m*i);
			//printf("%i %i\n",minx+i,miny+d);
			if(fg>=0)
				img.set_fg(fg,minx+i,miny+d);
			if(bg>=0)
				img.set_bg(bg,minx+i,miny+d);
			if(fill)
				img.set_char(fill,minx+i,miny+d);
			int delta=pos-d;
			int dist=abs(delta);
			if(dist>1){
				int j;
				int dir=-1;
				if(delta>0)
					dir=1;
				for(j=1;j<dist;j++){
					int tx,ty;
					tx=minx+i;
					ty=miny+d+j*dir;
					if(j>(dist>>1))
						tx-=1;
					if(bg>=0)
						img.set_bg(bg,tx,ty);
					if(fg>=0)
						img.set_fg(fg,tx,ty);
					if(fill)
						img.set_char(fill,tx,ty);
				}
			}
			pos=d;
		}
	}
	img.is_modified=true;
}

void draw_line_qb(IMAGE *img,POINT a,POINT b,POINT sa,POINT sb,int fg,int bg,int fill)
{
	POINT pa,pb;
	int width,height;
	int dx,dy;
	int minx,miny;
	width=img.width;
	height=img.height;
	dx=a.x-b.x;
	dy=a.y-b.y;
	minx=min(a.x,b.x);
	miny=min(a.y,b.y);
	if(0==dx && sa.x==sb.x){
		int i;
		POINT ta=sa,tb=sb;
		if(a.y>b.y || (a.y==b.y && sa.y>sb.y)){
			ta=sb;
			tb=sa;
		}
		img.cursor.x=minx;
		img.cursor.y=miny;
		img.qbpos=ta;
		dy=abs(dy*2)-ta.y+tb.y;
		for(i=0;i<=dy;i++){
			draw_qblock(img,fg,bg);
			img.move_cursor(0,1);
		}
		img.cursor=b;
		img.qbpos=sb;
	}else if(0==dy && sa.y==sb.y){
		int i;
		POINT ta=sa,tb=sb;
		if(a.x>b.x || (a.x==b.x && sa.x>sb.x)){
			ta=sb;
			tb=sa;
		}
		img.cursor.x=minx;
		img.cursor.y=miny;
		img.qbpos=ta;
		dx=abs(dx*2)-ta.x+tb.x;
		for(i=0;i<=dx;i++){
			draw_qblock(img,fg,bg);
			img.move_cursor(1,0);
		}
		img.cursor=b;
		img.qbpos=sb;
	}else{
		POINT pqa,pqb;
		int _a,_b;
		_a=a.x*2+sa.x;
		_b=b.x*2+sb.x;
		if(_a<=_b){
			pa=a;
			pb=b;
			pqa=sa;
			pqb=sb;
		}else{
			pa=b;
			pb=a;
			pqa=sb;
			pqb=sa;
		}
		dx=(2*pa.x+pqa.x)-(2*pb.x+pqb.x);
		dy=(2*pa.y+pqa.y)-(2*pb.y+pqb.y);
		double m,x,y;
		x=dx;y=dy;
		m=y/x;
		import core.stdc.stdio;
		printf("x1=%i,%i y1=%i,%i to x2=%i,%i y2=%i,%i dx=%i dy=%i\n",a.x,sa.x,a.y,sa.y,b.x,sb.x,b.y,sb.y,dx,dy);
		printf("m=%f\n",m);
		POINT _cursor,_qbpos;
		_cursor=img.cursor;
		_qbpos=img.qbpos;
		int i;
		dx=abs(dx);
		for(i=0;i<=dx;i++){
			import std.math;
			int tx,ty;
			x=i;
			y=m*x;
			tx=cast(int)round(x);
			tx+=pa.x*2;
			tx+=pqa.x;
			img.cursor.x=tx/2;
			img.qbpos.x=tx&1;
			ty=cast(int)round(y);
			ty+=pa.y*2;
			ty+=pqa.y;
			img.cursor.y=ty/2;
			img.qbpos.y=ty&1;
			draw_qblock(img,fg,bg);
		}
		for(i=0;i<=abs(dy);i++){
			import std.math;
			int tx,ty;
			y=i;
			if(m<0)
				y=-y;
			x=y/m;
			tx=cast(int)round(x);
			tx+=pa.x*2;
			tx+=pqa.x;
			img.cursor.x=tx/2;
			img.qbpos.x=tx&1;
			ty=cast(int)round(y);
			ty+=pa.y*2;
			ty+=pqa.y;
			img.cursor.y=ty/2;
			img.qbpos.y=ty&1;
			draw_qblock(img,fg,bg);
		}
		img.cursor=_cursor;
		img.qbpos=_qbpos;
	}
}

void fill_area(IMAGE *img,int fg,int bg,int fill_char)
{
	int obg,ofg,ochar;
	void append_row_pos(ref POINT[] list,int x,int y){
		if(!img.is_valid_pos(x,y))
			return;
		foreach(p;list){
			if(p.y==y && p.x<x){
				int i,complete=true;
				for(i=p.x;i<x;i++){
					if(bg>=0){
						if(obg!=img.get_bg(i,y)){
							complete=false;
							break;
						}
					}
					if(fg>=0){
						if(ofg!=img.get_fg(i,y)){
							complete=false;
							break;
						}
					}
					if(fill_char!=0){
						if(ochar!=img.get_char(i,y)){
							complete=false;
							break;
						}
					}
				}
				if(complete)
					return;
			}
		}
		POINT tmp={x,y};
		list~=tmp;
	}
	int needs_fill(int x,int y){
		int result=false;
		if(!img.is_valid_pos(x,y))
			return result;
		int cbg,cfg,cchar;
		cbg=img.get_bg(x,y);
		cfg=img.get_fg(x,y);
		cchar=img.get_char(x,y);
		if(bg>=0){
			if(cbg==obg && cbg!=bg)
				result=true;
		}
		if(fg>=0){
			if(cfg==ofg && cfg!=fg)
				result=true;
		}
		if(fill_char!=0){
			if(cchar==ochar && cchar!=fill_char)
				result=true;
		}
		return result;
	}
	void check_neighbor(ref POINT[] neighbor,int xpos,int ypos){
		if(needs_fill(xpos,ypos-1))
			append_row_pos(neighbor,xpos,ypos-1);
		if(needs_fill(xpos,ypos+1))
			append_row_pos(neighbor,xpos,ypos+1);
	}
	void fill_line(int sx,int sy,ref POINT[] neighbor){
		int j,len;
		len=img.width-sx;
		for(j=0;j<len;j++){
			int xpos,ypos;
			xpos=sx+j;
			ypos=sy;
			if(!img.is_valid_pos(xpos,ypos))
				break;
			if(bg>=0){
				int tbg=img.get_bg(xpos,ypos);
				if(tbg==obg && (tbg!=bg)){
					img.set_bg(bg,xpos,ypos);
					check_neighbor(neighbor,xpos,ypos);
				}
				else
					break;
			}
			if(fg>=0){
				int tfg=img.get_fg(xpos,ypos);
				if(tfg==ofg && (tfg!=fg)){
					img.set_fg(fg,xpos,ypos);
					check_neighbor(neighbor,xpos,ypos);
				}
				else
					break;
			}
			if(fill_char!=0){
				int tchar=img.get_char(xpos,ypos);
				if(tchar==ochar && (tchar!=fill_char)){
					img.set_char(fill_char,xpos,ypos);
					check_neighbor(neighbor,xpos,ypos);
				}
				else
					break;
			}
		}
	}
	int get_row_start(int cx,int cy){
		int i,xpos=-1;
		for(i=cx;i>=0;i--){
			if(!img.is_valid_pos(i,cy))
				continue;
			if(bg>=0){
				int tbg=img.get_bg(i,cy);
				if(obg!=tbg){
					xpos=i+1;
					break;
				}
			}if(fg>=0){
				int tfg=img.get_fg(i,cy);
				if(ofg!=tfg){
					xpos=i+1;
					break;
				}
			}if(fill_char!=0){
				int tchar=img.get_char(i,cy);
				if(ochar!=tchar){
					xpos=i+1;
					break;
				}
			}
			if(0==i){
				if(bg>=0 || fg>=0 || fill_char!=0){
					xpos=0;
					break;
				}
			}
		}
		return xpos;
	}
	int y;
	int cx,cy;
	struct PARAMS{
		int fg,bg,fill_char;
	}
	PARAMS[3] params=[
		{fg,-1,0},
		{-1,bg,0},
		{-1,-1,fill_char}
	];
	cx=img.cursor.x;
	cy=img.cursor.y;
	obg=img.get_bg(cx,cy);
	ofg=img.get_fg(cx,cy);
	ochar=img.get_char(cx,cy);
	foreach(param;params){
		fg=param.fg;
		bg=param.bg;
		fill_char=param.fill_char;
		POINT[] list;
		POINT _p;
		_p.x=get_row_start(cx,cy);
		_p.y=cy;
		list~=_p;
		while(list.length!=0){
			POINT[] tmp;
			foreach(p;list){
				int tx=get_row_start(p.x,p.y);
				fill_line(tx,p.y,tmp);
			}
			list.length=0;
			foreach(p;tmp){
				int tx=get_row_start(p.x,p.y);
				fill_line(tx,p.y,list);
			}
		}
	}
}
void fill_qb_area(IMAGE *img,int fg_color)
{
	int get_qb_color(int x,int y,ref int bg){
		int result=-1;
		bg=img.get_bg(x/2,y/2);
		int fg=img.get_fg(x/2,y/2);
		ushort e=img.get_char(x/2,y/2);
		bool t1,t2,b1,b2;
		get_element_corners(e,t1,t2,b1,b2);
		if(y&1){
			if(x&1){
				if(b2)
					result=fg;
			}else{
				if(b1)
					result=fg;
			}
		}else{
			if(x&1){
				if(t2)
					result=fg;
			}else{
				if(t1)
					result=fg;
			}
		}
		return result;
	}
	int get_row_start(int x,int y,int color){
		int result=x;
		int i;
		for(i=x-1;i>=0;i--){
			int bg;
			int c=get_qb_color(i,y,bg);
			if(c!=color){
				result=i+1;
				break;
			}else if(i==0){
				result=0;
				break;
			}
		}
		return result;
	}
	void check_neighbors(int x,int y,int color,ref POINT[] list){
		void append(int _c,int _bg,int _x,int _y){
			if(_c<0 && _bg!=color){
				POINT p;
				p.x=_x;
				p.y=_y;
				bool found=false;
				foreach(_p;list){
					if(_p==p){
						found=true;
						break;
					}
				}
				if(!found)
					list~=p;
			}
		}
		int c,bg;
		if(img.is_valid_pos(x/2,(y-1)/2)){
			c=get_qb_color(x,y-1,bg);
			append(c,bg,x,y-1);
		}
		if(img.is_valid_pos(x/2,(y+1)/2)){
			c=get_qb_color(x,y+1,bg);
			append(c,bg,x,y+1);
		}
	}
	void set_qblock(int x,int y,int c){
		int bg;
		bool t1,t2,b1,b2;
		ushort e=img.get_char(x/2,y/2);
		get_element_corners(e,t1,t2,b1,b2);
		int fg=img.get_fg(x/2,y/2);
		bool has_qb=t1||t2||b1||b2;
		if((fg==c && has_qb) || (!has_qb)){
			e=get_qblock(!(x&1),!(y&1),e);
			img.set_char(e,x/2,y/2);
			img.set_fg(c,x/2,y/2);
		}else{
			img.set_bg(c,x/2,y/2);
		}
	}
	void fill_line(int x,int y,int color,ref POINT[]list){
		int i,max;
		max=img.width*2;
		for(i=x;i<max;i++){
			int c,bg;
			c=get_qb_color(i,y,bg);
			if(c!=color){
				check_neighbors(i,y,color,list);
				set_qblock(i,y,color);
			}else{
				break;
			}
		}
	}
	int sx,sy;
	sx=img.cursor.x*2+img.qbpos.x;
	sy=img.cursor.y*2+img.qbpos.y;
	if(fg_color<0)
		return;
	POINT[] list;
	POINT _p;
	_p.x=get_row_start(sx,sy,fg_color);
	_p.y=sy;
	list~=_p;
	while(list.length>0){
		POINT[] tmp;
		foreach(p;list){
			int tx=get_row_start(p.x,p.y,fg_color);
			fill_line(tx,p.y,fg_color,tmp);
		}
		list.length=0;
		foreach(p;tmp){
			int tx=get_row_start(p.x,p.y,fg_color);
			fill_line(tx,p.y,fg_color,list);
		}
	}
}

void do_fill(IMAGE *img,int fg,int bg,int fill_char)
{
	if(img is null)
		return;
	int sw,sh;
	sw=img.selection_width();
	sh=img.selection_height();
	if(sw<=0 || sh<=0){
		if(img.qblock_mode)
			fill_qb_area(img,fg);
		else
			fill_area(img,fg,bg,fill_char);
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
				if(fill_char!=0)
					img.set_char(fill_char,x,y);
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
void draw_qblock(IMAGE *img,int fg,int bg)
{
	if(img is null)
		return;
	bool LR=false,TB=false;
	ushort element=img.get_char(img.cursor.x,img.cursor.y);
	if(img.qbpos.x<=0)
		LR=true;
	if(img.qbpos.y<=0)
		TB=true;
	element=get_qblock(LR,TB,element);
	img.set_char(element,img.cursor.x,img.cursor.y);
	if(fg>=0)
		img.set_fg(fg,img.cursor.x,img.cursor.y);
	if(bg>=0)
		img.set_bg(bg,img.cursor.x,img.cursor.y);
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