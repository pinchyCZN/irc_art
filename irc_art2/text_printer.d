module text_printer;

import core.sys.windows.windows;
import core.stdc.string;
import core.stdc.stdio;
import core.stdc.stdlib;
import resource;
import image;
import fonts;
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
int flag_font=VGA737;

void print_text(char *str,int is3d,int iscolor,int font_type)
{
	IMAGE *img=text_params.img;
	if(img is null)
		return;
	int len=strlen(str);
	int w,h;
	int fg,bg,tg;
	FONT font=get_font(font_type);
	fg=text_params.fg;
	bg=text_params.bg;
	tg=fg+1;
	if(fg<0)
		fg=0;
	if(bg<0){
		bg=1;
		tg=15;
	}
	w=len*font.width;
	h=font.height;
	if(is3d && len>0)
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
			fg=rand()%16;
			if(fg<=1)
				fg+=2;
			tg=fg+1;
			if(tg>15)
				tg=2;
		}
		int i,j;
		for(i=0;i<font.height;i++){
			int k=(a*font.height)+i;
			if(k>=font.data.length)
				continue;
			int x=font.data[k];
			for(j=font.width-1;j>=0;j--){
				int bit=x&(1<<(font.width-1-j));
				int c_index=(index*font.width)+i*w+j;
				if(c_index>=clip.cells.length)
					continue;
				if(bit){
					clip.cells[c_index].bg=fg;
					if(is3d){
						c_index=(index*font.width)+i*w+j+1;
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
void toggle_check_button(HWND hwnd,int idc)
{
	int flag=IsDlgButtonChecked(hwnd,idc);
	(BST_CHECKED==flag)?(flag=BST_UNCHECKED):(flag=BST_CHECKED);
	CheckDlgButton(hwnd,idc,flag);
	SendMessage(hwnd,WM_APP,0,0);
}
private WNDPROC old_edit_proc=NULL;
private extern(C)
BOOL _edit_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	print_msg(msg,wparam,lparam,hwnd);
	switch(msg){
		case WM_GETDLGCODE:
			int key=wparam;
			//if(VK_RETURN==key)
			//	return DLGC_WANTMESSAGE;
			break;
		case WM_COPY:
			return 0;
			break;
		case WM_KEYDOWN:
			{
				int key=wparam;
				int ctrl=GetKeyState(VK_CONTROL)&0x8000;
				int shift=GetKeyState(VK_SHIFT)&0x8000;
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
				case '1':
					if(ctrl){
						toggle_check_button(GetParent(hwnd),IDC_TEXTCOLOR);
					}
					break;
				case '2':
					if(ctrl){
						toggle_check_button(GetParent(hwnd),IDC_3D);
					}
					break;
				case VK_RETURN:
					if(shift){
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

void init_font_combo(HWND hwnd,int idc,int flag)
{
	HWND hcombo=GetDlgItem(hwnd,idc);
	if(hcombo is null)
		return;
	struct FONT_LIST{
		wstring name;
		int id;
	}
	FONT_LIST[] font_list=[
		{"VGA 737",VGA737},
		{"FONT8x8",FONT8X8},
	];
	foreach(ref f;font_list){
		wstring tmp;
		int index;
		tmp=f.name~'\0';
		index=SendMessage(hcombo,CB_ADDSTRING,0,cast(LPARAM)tmp.ptr);
		if(index>=0){
			SendMessage(hcombo,CB_SETITEMDATA,index,f.id);
		}
	}
	SendMessage(hcombo,CB_SETCURSEL,0,0);
	int i;
	for(i=0;i<font_list.length;i++){
		int val=SendMessage(hcombo,CB_GETITEMDATA,i,0);
		if(val==flag){
			SendMessage(hcombo,CB_SETCURSEL,i,0);
			break;
		}
	}
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
				init_font_combo(hwnd,IDC_FONT,flag_font);
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
							flag_is3d=BST_CHECKED==IsDlgButtonChecked(hwnd,IDC_3D);
							flag_color=BST_CHECKED==IsDlgButtonChecked(hwnd,IDC_TEXTCOLOR);
							int index=SendDlgItemMessage(hwnd,IDC_FONT,CB_GETCURSEL,0,0);
							if(index>=0){
								flag_font=SendDlgItemMessage(hwnd,IDC_FONT,CB_GETITEMDATA,index,0);
							}
							print_text(str.ptr,flag_is3d,flag_color,flag_font);
							InvalidateRect(GetDlgItem(text_params.hparent,IDC_IMAGE),NULL,TRUE);
						}
					}
					break;
				case IDC_FONT:
					if(CBN_SELCHANGE==HIWORD(wparam)){
						HWND hcombo=cast(HWND)lparam;
						int index=SendMessage(hcombo,CB_GETCURSEL,0,0);
						if(index>=0){
							int val=SendMessage(hcombo,CB_GETITEMDATA,index,0);
							if(val>=0)
								flag_font=val;
						}
						SendMessage(hwnd,WM_APP,0,0);
					}
					break;
				case IDC_3D:
					flag_is3d=BST_CHECKED==IsDlgButtonChecked(hwnd,IDC_3D);
					SendMessage(hwnd,WM_APP,0,0);
					break;
				case IDC_TEXTCOLOR:
					flag_color=BST_CHECKED==IsDlgButtonChecked(hwnd,IDC_TEXTCOLOR);
					SendMessage(hwnd,WM_APP,0,0);
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
		case WM_APP:
			switch(wparam){
			case 0:
				PostMessage(hwnd,WM_COMMAND,MAKEWPARAM(IDC_TEXT,EN_CHANGE),cast(LPARAM)GetDlgItem(hwnd,IDC_TEXT));
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
