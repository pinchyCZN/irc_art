module text_printer;

import core.sys.windows.windows;
import core.stdc.string;
import core.stdc.stdio;
import core.stdc.stdlib;
import resource;
import image;
import vga737;
import debug_print;

nothrow:
struct TEXT_PARAMS{
	HWND hparent;
	IMAGE *img;
	int fg,bg;
}
TEXT_PARAMS text_params={NULL,null,-1,-1};
int flag_is3d=0;
int flag_color=0;

void print_text(char *str,int is3d,int iscolor)
{
	IMAGE *img=text_params.img;
	if(img is null)
		return;
	int len=strlen(str);
	int w,h;
	int fg,bg,tg;
	fg=text_params.fg;
	bg=text_params.bg;
	tg=fg+1;
	if(fg<0)
		fg=0;
	if(bg<0){
		bg=1;
		tg=15;
	}
	w=len*8;
	h=12;
	if(is3d)
		w++;
	img.clip.cells.length=w*h;
	img.clip.width=w;
	img.clip.height=h;
	img.clip.x=img.cursor.x;
	img.clip.y=img.cursor.y;
	CLIP clip=img.clip;
	foreach(ref c;clip.cells){
		c.fg=fg;
		c.bg=bg;
		c.val=0;
	}
	int index=0;
	while(1){
		ubyte a=str[index];
		if(0==a)
			break;
		if(iscolor){
			fg=rand()%(15-3);
			fg+=3;
			tg++;
			if(tg>15)
				tg=fg-2;
		}
		int i,j;
		for(i=0;i<12;i++){
			int k=(a*12)+i;
			if(k>=vga737_bin.length)
				continue;
			int x=vga737_bin[k];
			for(j=7;j>=0;j--){
				int bit=x&(1<<(7-j));
				int c_index=(index*8)+i*w+j;
				if(c_index>=clip.cells.length)
					continue;
				if(bit){
					clip.cells[c_index].bg=fg;
					if(is3d){
						c_index=(index*8)+i*w+j+1;
						if(c_index<clip.cells.length)
							clip.cells[c_index].bg=tg;
					}
				}
			}
		}
		index++;
	}
	img.is_modified=true;
}

private WNDPROC old_edit_proc=NULL;
private extern(C)
BOOL _edit_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	print_msg(msg,wparam,lparam,hwnd);
	switch(msg){
		case WM_GETDLGCODE:
			break;
		case WM_COPY:
			return 0;
			break;
		case WM_KEYDOWN:
			{
				int key=wparam;
				int ctrl=GetKeyState(VK_CONTROL)&0x8000;
				switch(key){
				case 'A':
					if(ctrl)
						SendMessage(hwnd,EM_SETSEL,0,-1);
					break;
				case 'C':
					if(ctrl){
						IMAGE *img=get_current_image();
						if(img !is null){
							string tmp=get_text_cells(img.clip.cells,img.clip.width,img.clip.height);
							if(tmp.length>0){
								import file_image;
								tmp~='\0';
								copy_str_clipboard(tmp.ptr);
								print_str_len(text_params.hparent,tmp.ptr);
							}
						}
						return 0;
					}
					break;
				default:
					break;
				}
			}
			break;
		default:
			break;
	}
	return CallWindowProc(old_edit_proc,hwnd,msg,wparam,lparam);
}


extern (Windows)
BOOL dlg_text(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	switch(msg){
		case WM_INITDIALOG:
			{
				TEXT_PARAMS *tp=cast(TEXT_PARAMS*)lparam;
				if(tp is null){
					text_params.fg=-1;
					text_params.bg=-1;
					text_params.hparent=NULL;
					text_params.img=null;
				}else{
					text_params=*tp;
				}
				SendMessage(GetDlgItem(hwnd,IDC_TEXT),EM_SETLIMITTEXT,250,0);
				old_edit_proc=cast(WNDPROC)SetWindowLongPtr(GetDlgItem(hwnd,IDC_TEXT),GWL_WNDPROC,cast(LONG_PTR)&_edit_proc);
				if(flag_is3d)
					CheckDlgButton(hwnd,IDC_3D,BST_CHECKED);
				if(flag_color)
					CheckDlgButton(hwnd,IDC_TEXTCOLOR,BST_CHECKED);
			}
			break;
		case WM_COMMAND:
			int idc=LOWORD(wparam);
			switch(idc){
				case IDC_TEXT:
					{
						int notify=HIWORD(wparam);
						HWND htext=cast(HWND)lparam;
						if(EN_CHANGE==notify){
							char[256] str=0;
							GetWindowTextA(htext,str.ptr,str.length);
							str[$-1]=0;
							int is3d,iscolor;
							is3d=BST_CHECKED==IsDlgButtonChecked(hwnd,IDC_3D);
							iscolor=BST_CHECKED==IsDlgButtonChecked(hwnd,IDC_TEXTCOLOR);
							print_text(str.ptr,is3d,iscolor);
							InvalidateRect(GetDlgItem(text_params.hparent,IDC_IMAGE),NULL,TRUE);
						}
					}
					break;
				case IDC_3D:
					flag_is3d=BST_CHECKED==IsDlgButtonChecked(hwnd,IDC_3D);
					break;
				case IDC_TEXTCOLOR:
					flag_color=BST_CHECKED==IsDlgButtonChecked(hwnd,IDC_TEXTCOLOR);
					break;
				case IDCANCEL:
					{
						IMAGE *img=text_params.img;
						if(img !is null){
							img.clear_clip();
							InvalidateRect(GetDlgItem(text_params.hparent,IDC_IMAGE),NULL,TRUE);
						}
						EndDialog(hwnd,0);
					}
					break;
				case IDOK:
					EndDialog(hwnd,0);
					break;
				default:
					break;
			}
			break;
		default:
			break;
	}
	return FALSE;
}
