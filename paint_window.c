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
CELL *cells=0;
int rows=0,cols=0;
POINT cursor={0};
int CELL_WIDTH=8;
int CELL_HEIGHT=12;

typedef struct{
	int fg;
	int bg;
	int val;
	int x;
	int y;
}STATE;
int alloc_state(void **p)
{
	int result=FALSE;
	if(p){
		*p=malloc(sizeof(STATE));
		if(*p)
			result=TRUE;
	}
	return result;
}
int save_current_state(STATE *s)
{
	int result=FALSE;
	if(!s)
		return result;
	s->x=cursor.x;
	s->y=cursor.y;
	if(cursor.x>=0 && cursor.x<cols){
		if(cursor.y>=0 && cursor.y<rows){
			CELL *c=&cells[cursor.x+(cursor.y*cols)];
			s->fg=c->fg;
			s->bg=c->bg;
			s->val=c->val;
			result=TRUE;
		}
	}
	return result;
}
int state_changed(STATE *s)
{
	int result=TRUE;
	STATE tmp={0};
	if(!s)
		return result;
	save_current_state(&tmp);
	if(0==memcmp(&tmp,s,sizeof(STATE))){
		result=FALSE;
	}
	return result;
}
int emit_color_str(char *buf,int buf_size,int offset,int val,int full)
{
	int result=0;
	int i,div;
	if(offset>=buf_size)
		return result;
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
		buf[offset++]=x+'0';
		result++;
		if(offset>=buf_size)
			break;
	}
	return result;
}
int emit_char(char *buf,int buf_size,int offset,int val)
{
	int result=0;
	if(offset>=buf_size)
		return result;
	if(val<' ')
		val=' ';
	buf[offset++]=val;
	result++;
	return result;
}
int is_cell_num(int x,int y)
{
	int result=FALSE;
	if(x>=0 && x<cols){
		if(y>=0 && y<rows){
			int a;
			CELL *c=&cells[x+y*cols];
			a=c->val;
			if(a>='0' && a<='9')
				result=TRUE;
		}
	}
	return result;
}
//3FG,BG
int get_image_txt(char **txt,int *txt_size)
{
	int result=0;
	int i,j,index=0;
	int buf_size=rows*cols*(4+6)+rows;
	char *buf=calloc(buf_size,1);
	if(!buf)
		return result;
	for(i=0;i<rows;i++){
		CELL tmp;
		memset(&tmp,-1,sizeof(tmp));
		for(j=0;j<cols;j++){
			int emit_bg=FALSE;
			int emit_fg=FALSE;
			CELL *c=&cells[j+i*cols];
			if(index>=buf_size)
				break;
			if(c->bg!=tmp.bg)
				emit_bg=TRUE;
			if(c->fg!=tmp.fg)
				emit_fg=TRUE;
			if(emit_fg || emit_bg){
				buf[index++]=3;
				if(index>=buf_size)
					break;
				if(emit_fg){
					int full=FALSE;
					if(!emit_bg)
						full=is_cell_num(j+1,i);
					index+=emit_color_str(buf,buf_size,index,get_pal_index(c->fg),full);
				}
				if(emit_bg){
					int full=is_cell_num(j+1,i);
					if(index>=buf_size)
						break;
					buf[index++]=',';
					index+=emit_color_str(buf,buf_size,index,get_pal_index(c->bg),full);
				}
			}
			index+=emit_char(buf,buf_size,index,c->val);
			tmp=*c;
			if(index>=buf_size)
				break;
		}
		buf[index++]='\n';
		if(index>=buf_size)
			break;
	}
	if(0==index)
		return result;
	*txt=realloc(buf,index);
	if(*txt){
		result=index;
		*txt_size=index;
	}else{
		if(buf)
			free(buf);
	}
	return index;
}
int move_cursor(int x,int y)
{
	cursor.x+=x;
	cursor.y+=y;
	if(cursor.x>=cols)
		cursor.x=0;
	if(cursor.x<0)
		cursor.x=cols-1;
	if(cursor.y<0)
		cursor.y=rows-1;
	if(cursor.y>=rows)
		cursor.y=0;
	if(0==rows)
		cursor.y=0;
	if(0==cols)		
		cursor.x=0;
	return 1;
}
int image_click(int x,int y,int msg)
{
	x/=CELL_WIDTH;
	y/=CELL_HEIGHT;
	if(x<0 || x>=cols)
		return 0;
	if(y<0 || y>=rows)
		return 0;
	cursor.x=x;
	cursor.y=y;
	return 1;
}
int is_inside(int x,int y)
{
	int result=FALSE;
	if(x>=cols || x<0)
		return result;
	if(y>=rows || y<0)
		return result;
	result=TRUE;
	return result;
}
int set_fg(int fg,int x,int y)
{
	int result=FALSE;
	CELL *cell;
	int index;
	if(!is_inside(x,y))
		return result;
	index=x+(y*cols);
	if(index>=(rows*cols))
		return result;
	cell=&cells[index];
	cell->fg=fg;
	result=TRUE;
	return result;
}
int set_bg(int bg,int x,int y)
{
	int result=FALSE;
	CELL *cell;
	int index;
	if(!is_inside(x,y))
		return result;
	index=x+(y*cols);
	if(index>=(rows*cols))
		return result;
	cell=&cells[index];
	cell->bg=bg;
	result=TRUE;
	return result;
}
int map_pixel_cell(int *_x,int *_y)
{
	int x,y;
	x=*_x;
	y=*_y;
	x/=CELL_WIDTH;
	y/=CELL_HEIGHT;
	*_x=x;
	*_y=y;
	return 1;
}
int set_char(int key,int x,int y)
{
	int result=FALSE;
	CELL *cell;
	int index;
	if(!is_inside(x,y))
		return result;
	index=x+(y*cols);
	if(index>=(rows*cols))
		return result;
	cell=&cells[index];
	cell->val=key;
	result=TRUE;
	return result;
}
int init_grid(CELL *grid,int w,int h)
{
	int i,j;
	int fg,bg;
	fg=get_rgb(GetSysColor(COLOR_WINDOWTEXT));
	fg=get_nearest_color(fg);
	bg=get_rgb(GetSysColor(COLOR_WINDOW));
	bg=get_nearest_color(bg);
	for(i=0;i<h;i++){
		for(j=0;j<w;j++){
			grid->val=' ';
			grid->bg=bg;
			grid->fg=fg;
		}
	}
	return 1;
}
int resize_grid(int w,int h)
{
	int result=FALSE;
	CELL *tmp;
	tmp=calloc(w*h*sizeof(CELL),1);
	if(tmp){
		init_grid(tmp,w,h);
		if(cells){
			int i;
			int y=min(h,rows);
			for(i=0;i<y;i++){
				CELL *src,*dst;
				int x=min(w,cols);
				int size=sizeof(CELL)*x;
				src=cells+(i*cols);
				dst=tmp+(i*w);
				memcpy(dst,src,size);
			}
			free(cells);
		}
		rows=h;
		cols=w;
		cells=tmp;
		result=TRUE;
	}
	return result;
}
int get_cursor_y()
{
	return cursor.y;
}
int get_cursor_x()
{
	return cursor.x;
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
		vgargb=calloc(8*12*total,1);
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
	int i,cell_count;
	int xoffset,yoffset;
	struct TMP{
		BITMAPINFOHEADER bmiHeader;
		DWORD colors[2];
	};
	struct TMP bmi={0};
	char *font=vgargb;

	if(!vgargb)
		return 0;
	if(rows==0 || cols==0)
		return 0;
	bmi.bmiHeader.biBitCount=8;
	bmi.bmiHeader.biWidth=8;
	bmi.bmiHeader.biHeight=12;
	bmi.bmiHeader.biPlanes=1;
	bmi.bmiHeader.biSizeImage=8*12;
	bmi.bmiHeader.biXPelsPerMeter=12;
	bmi.bmiHeader.biYPelsPerMeter=12;
	bmi.bmiHeader.biSize=sizeof(BITMAPINFOHEADER);
	cell_count=rows*cols;
	xoffset=0;
	yoffset=0;

	for(i=0;i<cell_count;i++){
		unsigned short a;
		int x,y;
		CELL *cell=&cells[i];
		bmi.colors[0]=cell->bg;
		bmi.colors[1]=cell->fg;
		a=cell->val&0xFF;
		x=i%cols;
		x*=8;
		x+=xoffset;
		y=i/cols;
		y*=12;
		y+=yoffset;
		SetDIBitsToDevice(hdc,x,y,8,12,
			0,0, //src xy
			0,12, //startscan,scanlines
			font+a*12*8,
			(BITMAPINFO*)&bmi,DIB_RGB_COLORS);
	}
	{
		RECT rect;
		rect.left=cursor.x*8;
		rect.left+=xoffset;
		rect.top=cursor.y*12;
		rect.top+=yoffset;
		rect.right=rect.left+8;
		rect.bottom=rect.top+12;
		DrawFocusRect(hdc,&rect);
	}
	return 0;
}
