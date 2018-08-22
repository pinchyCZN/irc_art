module file_image;

import core.sys.windows.windows;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;
import std.string;
import std.utf;
import std.stdio;
import image;
import resource;
nothrow:

void update_title(HWND hwnd,wstring title,int mod)
{
	wstring tmp=title;
	if(mod)
		tmp="*"~tmp;
	tmp~="\0";
	SetWindowTextW(hwnd,tmp.ptr);
}
int write_image(wstring fname,string text)
{
	int result=FALSE;
	FILE *f;
	fname~=0;
	f=_wfopen(fname.ptr,"wb");
	if(f){
		fwrite(text.ptr,1,text.length,f);
		fclose(f);
		result=TRUE;
	}
	return result;
}

int init_ofn(OPENFILENAMEW *ofn,const WCHAR *title,HWND hwnd)
{
	ofn.lStructSize=OPENFILENAMEW.sizeof;
	ofn.hwndOwner=hwnd;
	ofn.lpstrFilter="TEXT FILES (*.TXT)\0*.TXT\0ALL FILES (*.*)\0*.*\0\0";
	ofn.lpstrTitle=title;
	ofn.Flags=OFN_ENABLESIZING;
	return TRUE;
}
wstring wchar_to_str(WCHAR[] str)
{
	wstring result;
	foreach(WCHAR c;str){
		if(0==c)
			break;
		result~=c;
	}
	return result;
}
int file_saveas(HWND hwnd,IMAGE *img)
{
	int result=FALSE;
	OPENFILENAMEW ofn;
	WCHAR[] tmp;
	if(img is null)
		return result;
	init_ofn(&ofn,"Save"w.ptr,hwnd);
	tmp.length=1024;
	tmp[]=0;
	ofn.lpstrFile=tmp.ptr;
	ofn.nMaxFile=tmp.length;
	if(GetOpenFileNameW(&ofn)){
		tmp[tmp.length-1]=0;
		img.fname=wchar_to_str(tmp);
		write_image(img.fname,img.get_text());
		update_title(hwnd,img.fname,img.is_modified);
		result=TRUE;
	}
	return result;
}
int file_save(HWND hwnd,IMAGE *img)
{
	int result=FALSE;
	if(img is null)
		return result;
	if(0==img.fname.length)
		result=file_saveas(hwnd,img);
	else
		result=write_image(img.fname,img.get_text());
	if(result)
		update_title(hwnd,img.fname,img.is_modified);
	return result;
}
int copy_str_clipboard(const char *str)
{
	int len,result=FALSE;
	HGLOBAL hmem;
	char *lock;
	len=strlen(str);
	if(len==0)
		return result;
	len++;
	hmem=GlobalAlloc(GMEM_MOVEABLE,len);
	if(hmem !is null){
		lock=cast(char*)GlobalLock(hmem);
		if(lock !is null){
			memcpy(lock,str,len);
			GlobalUnlock(hmem);
			if(OpenClipboard(NULL)!=0){
				EmptyClipboard();
				SetClipboardData(CF_TEXT,hmem);
				CloseClipboard();
				result=TRUE;
			}
		}
		if(!result)
			GlobalFree(hmem);
	}
	return result;
}

int fetch_next_char(ubyte *str,int *index,int *val)
{
	int result=FALSE;
	ubyte a,b,c,d;
	int offset=*index;
	a=b=c=d=0;
	a=str[offset];
	if(0==a){
		return result;
	}else{
		b=str[offset+1];
		if(b!=0){
			c=str[offset+2];
			if(c!=0)
				d=str[offset+3];
		}
	}
	if(a&0x80){
		if((a&0xE0)==0xC0){ //110xxxxx 2 bytes
			if((b&0xC0)==0x80){ //10xxxxxx
				*val=((a&0x1F)<<6)|(b&0x3F);
				index[0]+=2;
				result=TRUE;
			}else{
				goto FALLBACK;
			}
		}else if((a&0xF0)==0xE0){ //1110xxxx 3 bytes
			if((b&0xC0)==0x80){ //10xxxxxx
				if((c&0xC0)==0x80){
					*val=((a&0xF)<<12)|((b&0x3F)<<6)|(c&0x3F);
					index[0]+=3;
					result=TRUE;
				}else{
					goto FALLBACK;
				}
			}else{
				goto FALLBACK;
			}
		}else if((a&0xF8)==0xF0){ //11110xxx 4 bytes
			if((b&0xC0)==0x80){ //10xxxxxx
				if((c&0xC0)==0x80){
					if((d&0xC0)==0x80){
						*val=((a&0x7)<<18)|((b&0x3F)<<12)|((c&0x3F)<<6)|(d&0x3F);
						index[0]+=4;
						result=TRUE;
					}else{
						goto FALLBACK;
					}
				}else{
					goto FALLBACK;
				}
			}else{
				goto FALLBACK;
			}
		}else{
			goto FALLBACK;
		}
	}else{
	FALLBACK:
		*val=a;
		index[0]++;
		result=TRUE;
	}
	return result;
}
int get_str_dimensions(ubyte *str,int *width,int *height)
{
	int max_width=0,line_count=0;
	int counter=0;
	int index=0;
	int state=0;
	int num_count;
	int a;
	while(fetch_next_char(str,&index,&a)){
		if(0==a)
			break;
		if('\r'==a || '\n'==a){
			if(counter>max_width)
				max_width=counter;
			counter=0;
			if(a=='\n')
				line_count++;
		}else{
			switch(state){
				case 0:
					if(3==a)
						state=1;
					else{
						if(!(a==2 || a==0x1D || a==0x1F || a==0x16 || a==0xF))
							counter++;
					}
					num_count=0;
					break;
				case 1:
					if(a>='0' && a<='9'){
						num_count++;
						if(num_count>=2)
							state=2;
					}else if(a==','){
						state=3;
						num_count=0;
					}else{
						counter++;
						state=0;
					}
					break;
				case 2: //check for ,
					if(a==','){
						state=3;
						num_count=0;
					}else{
						state=0;
						counter++;
					}
					break;
				case 3: //number after ,
					if(a>='0' && a<='9'){
						num_count++;
						if(num_count>=2)
							state=0;
					}else{
						state=0;
						counter++;
					}
					break;
				default:
					break;
			}
		}
	}
	if(0==line_count){
		if(max_width>0)
			line_count=1;
		else if(counter>0){
			line_count=1;
			max_width=counter;
		}
	}
	*width=max_width;
	*height=line_count;
	return 1;
}
int process_str(ubyte *str,ref IMAGE img,void function(ref IMAGE,int,int,int,int,int) nothrow cell_writer,
				int _fg,int _bg)
{
	int index=0;
	int state=0;
	int num_count,fg,bg;
	int x=0,y=0;
	int a;
	if(_fg<0)
		_fg=1;
	if(_bg<0)
		_bg=0;
	fg=_fg;
	bg=_bg;
	while(fetch_next_char(str,&index,&a)){
		if(0==a)
			break;
		if('\r'==a || '\n'==a){
			fg=_fg;
			bg=_bg;
			x=0;
			if(a=='\n')
				y++;
		}else{
			switch(state){
				case 0:
				WRITE_CELL:
					if(3==a)
						state=1;
					else{
						if(!(a==2 || a==0x1D || a==0x1F || a==0x16 || a==0xF)){
							cell_writer(img,fg,bg,a,x,y);
							/*
							img.set_fg(fg,x,y);
							img.set_bg(bg,x,y);
							img.set_char(a,x,y);
							*/
							x++;
						}
					}
					num_count=0;
					break;
				case 1:
					if(a>='0' && a<='9'){
						if(0==num_count)
							fg=a-'0';
						else{
							fg*=10;
							fg+=a-'0';
						}
						num_count++;
						if(num_count>=2){
							state=2;
						}
					}else if(a==','){
						state=3;
						num_count=0;
					}else{
						state=0;
						goto WRITE_CELL;
					}
					break;
				case 2: //check for ,
					if(a==','){
						state=3;
						num_count=0;
					}else{
						state=0;
						goto WRITE_CELL;
					}
					break;
				case 3: //number after ,
					if(a>='0' && a<='9'){
						if(0==num_count)
							bg=a-'0';
						else{
							bg*=10;
							bg+=a-'0';
						}
						num_count++;
						if(num_count>=2)
							state=0;
					}else{
						state=0;
						goto WRITE_CELL;
					}
					break;
				default:
					break;
			}
		}
	}
	return 1;

}

void full_image_import(ref IMAGE img,int fg,int bg,int a,int x,int y)
{
	img.set_fg(fg,x,y);
	img.set_bg(bg,x,y);
	img.set_char(a,x,y);
}
void resize_img_to_str(char *str,ref IMAGE img)
{
	import std.algorithm.comparison:max;
	int max_x,max_y;
	get_str_dimensions(cast(ubyte*)str,&max_x,&max_y);
	if(max_x>1000)
		max_x=1000;
	if(max_y>10000)
		max_y=10000;
	max_x=max(img.width,max_x);
	max_y=max(img.height,max_y);
	img.resize_image(max_x,max_y);
}
int import_txt(char *str,ref IMAGE img,int fg,int bg)
{
	int result=FALSE;
	resize_img_to_str(str,img);
	result=process_str(cast(ubyte*)str,img,&full_image_import,fg,bg);
	return result;
}
void clip_import(ref IMAGE img,int fg,int bg,int a,int x,int y)
{
	int index;
	index=x+y*img.clip.width;
	if(index>=img.clip.cells.length)
		return;
	img.clip.cells[index].fg=fg;
	img.clip.cells[index].bg=bg;
	img.clip.cells[index].val=cast(WCHAR)a;
}
int import_txt_clip(char *str,ref IMAGE img,int fg,int bg)
{
	int result=FALSE;
	int max_x,max_y;
	get_str_dimensions(cast(ubyte*)str,&max_x,&max_y);
	if(max_x>1000)
		max_x=1000;
	if(max_y>1000)
		max_y=1000;
	img.clip.cells.length=max_x*max_y;
	img.clip.width=max_x;
	img.clip.height=max_y;
	img.clip.x=img.cursor.x;
	img.clip.y=img.cursor.y;
	result=process_str(cast(ubyte*)str,img,&clip_import,fg,bg);
	return result;
}
int import_file(WCHAR *fname,ref IMAGE img,int fg,int bg)
{
	int result=false;
	if(fname is null)
		return result;
	FILE *f;
	f=_wfopen(fname,"rb");
	if(f){
		char *str;
		int str_size=0x100000;
		str=cast(char*)calloc(str_size,1);
		if(str)
			fread(str,1,str_size,f);
		fclose(f);
		if(str){
			str[str_size-1]=0;
			resize_img_to_str(str,img);
			result=process_str(cast(ubyte*)str,img,&full_image_import,fg,bg);
			free(str);
		}
	}
	return result;
}
int file_open(HWND hwnd,ref IMAGE img,int fg,int bg)
{
	int result=FALSE;
	OPENFILENAMEW ofn;
	WCHAR[MAX_PATH] tmp=0;
	init_ofn(&ofn,"Open",hwnd);
	ofn.lpstrFile=tmp.ptr;
	ofn.nMaxFile=tmp.length;
	if(GetOpenFileNameW(&ofn)){
		result=import_file(tmp.ptr,img,fg,bg);
	}
	return result;
}

int import_clipboard(HWND hwnd,ref IMAGE img,int to_img_clip,int fg,int bg)
{
	int result=FALSE;
	if(OpenClipboard(NULL)){
		HANDLE htxt=GetClipboardData(CF_TEXT);
		if(htxt){
			char *str=cast(char*)GlobalLock(htxt);
			if(str){
				char *tmp=strdup(str);
				GlobalUnlock(htxt);
				if(tmp){
					if(to_img_clip)
						result=import_txt_clip(tmp,img,fg,bg);
					else
						result=import_txt(tmp,img,fg,bg);
					if(result)
						img.is_modified=true;
					free(tmp);
				}
			}
		}
		CloseClipboard();
	}
	return result;
}

int drop_file(HWND hwnd,HDROP hdrop,IMAGE *img,int fg,int bg)
{
	int result=false;
	if(img is null || hdrop is null)
		return result;
	WCHAR[1024] fname;
	int count;
	count=DragQueryFile(hdrop,0,fname.ptr,fname.length);
	if(count>0){
		import_file(fname.ptr,*img,fg,bg);
	}
	return result;
}

int get_max_line_len(const char *str)
{
	int max=0;
	int index=0;
	int len=0;
	while(1){
		char a=str[index++];
		if(0==a || '\r'==a || '\n'==a){
			if(len>max){
				max=len;
			}
			len=0;
		}else{
			len++;
		}
		if(0==a)
			break;
	}
	return max;
}
void print_str_len(HWND hparent,const char *str)
{
	int len=get_max_line_len(str);
	char[80] tmp;
	_snprintf(tmp.ptr,tmp.length,"copied string max len=%i",len);
	SetDlgItemTextA(hparent,IDC_STATUS,tmp.ptr);
}