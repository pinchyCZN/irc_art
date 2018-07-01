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
	int get_fg(int x,int y){
		if(!is_valid_pos(x,y))
			return -1;
		int index=x+y*width;
		return cells[index].fg;
	}
	int get_bg(int x,int y){
		if(!is_valid_pos(x,y))
			return -1;
		int index=x+y*width;
		return cells[index].bg;
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
	string get_clip_text(){
		return get_text_cells(clip.cells,clip.width,clip.height);
	}
};
IMAGE[] images;
int current_image=0;
ubyte[] vgargb;

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
	const int total=vga737_bin.length+block_elements.length;
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
int paint_image(HWND hwnd,HDC hdc)
{
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
		draw_focus_rect(img,hdc,rect);
	}

	RECT rect;
	rect.left=img.cursor.x;
	rect.right=rect.left+1;
	rect.top=img.cursor.y;
	rect.bottom=rect.top+1;
	draw_focus_rect(img,hdc,rect);


	if(img.selection_width>0 || img.selection_height>0){
		rect=img.selection;
		draw_focus_rect(img,hdc,rect);
	}
	return result;
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
	tmp.left*=img.cell_width;
	tmp.right*=img.cell_width;
	tmp.top*=img.cell_height;
	tmp.bottom*=img.cell_height;
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
					x=i*img.cell_width;
					y=j*img.cell_height;
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
		for(i=0;i<dx;i++){
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

void do_fill(IMAGE *img,int fg,int bg,int fill_char)
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
void init_image()
{
	IMAGE *img;
	images.length=1;
	img=&images[0];
	img.resize_image(80,40);
	create_vga_font();
}