module file_image;

import core.sys.windows.windows;
import core.stdc.stdio;
import std.string;
import std.utf;
import image;
nothrow:

void update_title(HWND hwnd,wstring title,int mod)
{
	wstring tmp;
	if(mod)
		tmp=title~"*"w;
	SetWindowTextW(hwnd,toUTF16z(tmp));
}
int write_image(string fname,string text)
{
	int result=FALSE;
	FILE *f;
	f=fopen(toStringz(fname),"wb");
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
	ofn.hInstance=GetModuleHandle(NULL);
	ofn.hwndOwner=hwnd;
	ofn.lpstrFilter="TEXT FILES (*.TXT)\0*.TXT\0ALL FILES (*.*)\0*.*\0\0";
	ofn.lpstrTitle=title;
	ofn.Flags=OFN_ENABLESIZING;
	return TRUE;
}

int file_saveas(HWND hwnd,IMAGE img)
{
	int result=FALSE;
	OPENFILENAMEW ofn;
	WCHAR[1024] tmp;
	init_ofn(&ofn,"Save"w.ptr,hwnd);
	ofn.lpstrFile=tmp.ptr;
	ofn.nMaxFile=tmp.length;
	if(GetOpenFileNameW(&ofn)){
		write_image(gfname);
		update_title(hwnd);
		result=TRUE;
	}
	return result;
}
int file_save(HWND hwnd)
{
	int result=FALSE;
	if(gfname[0]!=0)
		result=write_image(gfname);
	else
		result=file_saveas(hwnd);
	if(result)
		update_title(hwnd);
	return result;
}
int copy_str_clipboard(char *str)
{
	int len,result=FALSE;
	HGLOBAL hmem;
	char *lock;
	len=strlen(str);
	if(len==0)
		return result;
	len++;
	hmem=GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE,len);
	if(hmem!=0){
		lock=GlobalLock(hmem);
		if(lock!=0){
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
int image_to_clipboard()
{
	int result=FALSE;
	char *buf=0;
	int buf_size=0;
	if(get_image_txt(&buf,&buf_size)){
		result=copy_str_clipboard(buf);
		if(buf)
			free(buf);
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
int get_str_dimensions(ref ubyte[] str,int *width,int *height)
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
int process_str(char *str)
{
	int index=0;
	int state=0;
	int num_count,fg,bg;
	int x=0,y=0;
	int max_x,max_y;
	int a;
	max_x=get_cols();
	max_y=get_rows();
	fg=1;
	bg=0;
	while(fetch_next_char(str,&index,&a)){
		if(0==a)
			break;
		if('\r'==a || '\n'==a){
			fg=1;
			bg=0;
			x=0;
			if(a=='\n')
				y++;
			if(y>=max_y)
				break;
		}else{
			switch(state){
				case 0:
				WRITE_CELL:
					if(3==a)
						state=1;
					else{
						if(!(a==2 || a==0x1D || a==0x1F || a==0x16 || a==0xF)){
							set_fg(get_color_val(fg),x,y);
							set_bg(get_color_val(bg),x,y);
							set_char(a,x,y);
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
			}
		}
	}
	return 1;

}
int import_txt(char *str)
{
	int result=FALSE;
	int width=0,height=0;
	get_str_dimensions(str,&width,&height);
	if(width<=0 || height<=0){
		return result;
	}
	if(width>500)
		width=500;
	if(height>1000)
		height=1000;
	if(resize_grid(width,height))
		result=process_str(str);
	return result;
}
int file_open(HWND hwnd)
{
	int result=FALSE;
	OPENFILENAMEW ofn={0};
	WCHAR[MAX_PATH] tmp={0};
	init_ofn(&ofn,"Open",hwnd);
	ofn.lpstrFile=tmp;
	ofn.nMaxFile=sizeof(tmp)/sizeof(WCHAR);
	if(GetOpenFileNameW(&ofn)){
		FILE *f;
		f=_wfopen(tmp,"rb");
		if(f){
			char *str;
			int str_size=0x100000;
			str=calloc(str_size,1);
			if(str)
				fread(str,1,str_size,f);
			fclose(f);
			if(str){
				str[str_size-1]=0;
				result=process_str(str);
				free(str);
			}
		}
	}
	if(result)
		PostMessage(hwnd,WM_APP,1,0);
	return result;
}

int import_clipboard(HWND hwnd)
{
	int result=FALSE;
	if(OpenClipboard(NULL)){
		HANDLE htxt=GetClipboardData(CF_TEXT);
		if(htxt){
			char *str=GlobalLock(htxt);
			if(str){
				char *tmp=strdup(str);
				GlobalUnlock(htxt);
				if(tmp){
					result=import_txt(tmp);
					free(tmp);
				}
			}
		}
		CloseClipboard();
	}
	if(result)
		PostMessage(hwnd,WM_APP,1,0);
	return result;
}