module text_printer;

import core.sys.windows.windows;
import core.stdc.string;
import core.stdc.stdio;
import core.stdc.stdlib;
import anchor_system;
import resource;
import image;
import fonts;
import debug_print;

nothrow:
CONTROL_ANCHOR[] text_edit_anchor=[
	{IDC_TEXT,ANCHOR_LEFT|ANCHOR_TOP|ANCHOR_RIGHT|ANCHOR_BOTTOM},
	{IDC_TEXTCOLOR,ANCHOR_LEFT|ANCHOR_BOTTOM},
	{IDC_3D,ANCHOR_LEFT|ANCHOR_BOTTOM},
	{IDC_FONT,ANCHOR_LEFT|ANCHOR_BOTTOM},
	{IDC_SPACING,ANCHOR_LEFT|ANCHOR_BOTTOM},
	{IDC_GRIPPY,ANCHOR_RIGHT|ANCHOR_BOTTOM},
];
WIN_REL_POS text_win_pos;
WCHAR[] last_text;
HWND htextdlg=NULL;
int text_spacing=0;

struct TEXT_PARAMS{
	HWND hparent;
	IMAGE *img;
	nothrow:
	int function() fg;
	int function() bg;
	int function() fill_char;
}
TEXT_PARAMS text_params={NULL,null,null,null};
int flag_is3d=0;
int flag_color=0;
int flag_font=VGA737;

int get_rand_color()
{
	static int[14] list=[4,2,3,5,6,7,8,11,9,15,10,12,13,14];
	static int last_color=0;
	int c=list[last_color];
	last_color++;
	if(last_color>=list.length)
		last_color=0;
	return c;
}
int clamp_spacing(int val)
{
	if(val<-10)
		val=10;
	else if(val>10)
		val=-10;
	return val;
}
void calc_clip_size_ascii(char *str,FONT font,IMAGE *img)
{
	int index=0;
	int count=0;
	int width,height,w,h;
	int cell_height;
	if(font.mdata.length>=2)
		cell_height=font.mdata[1];
	while(1){
		ubyte a=cast(ubyte)str[index++];
		if(0==a){
			if(count>0){
				if(w>width)
					width=w;
				height+=h;
			}
			break;
		}else if('\n'==a || '\r'==a){
			if(count>0){
				if(w>width)
					width=w;
				w=0;
				height+=h;
				count=0;
			}
		}else{
			int aindex=a-font.ascii_start;
			if(aindex<0)
				continue;
			aindex*=2;
			if(aindex>=font.mdata.length)
				continue;
			int size,_w,_h;
			_w=font.mdata[aindex];
			_h=font.mdata[aindex+1];
			if(w>0 && _w>0){
				w+=text_spacing;
			}
			w+=_w;
			h=_h;
			size=_w*_h;
			if(0==size)
				continue;
			count++;
		}
	}
	img.clip.cells.length=width*height;
	img.clip.width=width;
	img.clip.height=height;
}
void calc_clip_size_bitmap(char *str,FONT font,IMAGE *img,int is3d)
{
	int w,h,index=0,count=0;
	while(1){
		char a=str[index++];
		if(0==a){
			if(count>w)
				w=count;
			if(count>0)
				h++;
			break;
		}
		if('\r'==a)
			continue;
		if('\n'==a){
			h++;
			if(count>w)
				w=count;
			count=0;
		}else{
			count++;
		}
	}
	w=w*font.width+((w-1)*text_spacing);
	if(w<0)
		w=0;
	h=h*font.height;
	if(w>0 && is3d)
		w++;
	img.clip.cells.length=w*h;
	img.clip.width=w;
	img.clip.height=h;
}
void set_clip_size(char *str,FONT font,IMAGE *img,int is3d)
{
	if(img is null)
		return;
	if((font.width==0 || font.height==0) && font.mdata.length>0){
		calc_clip_size_ascii(str,font,img);
	}else{
		calc_clip_size_bitmap(str,font,img,is3d);
	}
}
void print_text_bitmap(char *str,FONT font,int fg,int bg,int tg,int is3d,int iscolor,
					   ref CLIP clip)
{
	int xpos=0,ypos=0;
	int index=0;
	while(1){
		ubyte a=str[index++];
		if(0==a)
			break;
		if('\r'==a)
			continue;
		if('\n'==a){
			xpos=0;
			ypos+=font.height;
			continue;
		}
		if(iscolor){
			fg=get_rand_color();
			tg=fg+2;
			if(tg>15)
				tg=2;
		}
		int i,j;
		for(i=0;i<font.height;i++){
			int ascii_offset=a-font.ascii_start;
			if(ascii_offset<0)
				continue;
			int k=(ascii_offset*font.height)+i;
			if(k>=font.data.length)
				continue;
			int x=font.data[k];
			for(j=font.width-1;j>=0;j--){
				int bit=x&(1<<(font.width-1-j));
				int c_index=xpos+ypos*clip.width+i*clip.width+j;
				if(c_index>=clip.cells.length)
					continue;
				if(bit){
					clip.cells[c_index].bg=fg;
					if(is3d){
						c_index=xpos+ypos*clip.width+i*clip.width+j+1;
						if(c_index<clip.cells.length)
							clip.cells[c_index].bg=tg;
					}
				}
			}
		}
		xpos+=font.width+text_spacing;
		if(xpos<0)
			xpos=0;
	}
}
int get_ascii_offset(int a,FONT font)
{
	int offset=0;
	int pos=a;
	if((pos*2+1)>=font.mdata.length)
		return offset;
	int i;
	for(i=0;i<font.mdata.length/2;i++){
		int w,h;
		if(i==pos)
			break;
		w=font.mdata[i*2];
		h=font.mdata[i*2+1];
		offset+=w*h;
	}
	return offset;
}
void print_text_ascii(char *str,FONT font,int fg,int bg,int tg,int iscolor,
					   ref CLIP clip)
{
	int xpos=0,ypos=0;
	int index=0;
	int w,h;
	if(font.mdata.length>=2)
		h=font.mdata[1];
	while(1){
		ubyte a=str[index++];
		if(0==a)
			break;
		if('\r'==a)
			continue;
		if('\n'==a){
			xpos=0;
			ypos+=h;
			continue;
		}
		if(iscolor){
			fg=get_rand_color();
			tg=fg+2;
			if(tg>15)
				tg=2;
		}
		int aindex=a-font.ascii_start;
		if(aindex<0 || (aindex*2+1)>=font.mdata.length)
			continue;
		w=font.mdata[aindex*2];
		int i,j;
		int soffset=get_ascii_offset(aindex,font);
		for(i=0;i<h;i++){
			for(j=0;j<w;j++){
				WCHAR src_val,dst_val;
				int src_index=soffset+j+i*w;
				int dst_index=xpos+j+ypos*clip.width+i*clip.width;
				if(src_index>=font.data.length)
					break;
				if(dst_index>=clip.cells.length)
					break;
				clip.cells[dst_index].fg=fg;
				clip.cells[dst_index].bg=bg;
				src_val=font.data[src_index];
				dst_val=clip.cells[dst_index].val;
				if(src_val!=' ')
					clip.cells[dst_index].val=src_val;
				else if(dst_val==0)
					clip.cells[dst_index].val=src_val;
			}
		}
		xpos+=w+text_spacing;
		if(xpos<0)
			xpos=0;
	}
}
void print_text(char *str,int is3d,int iscolor,int font_type)
{
	IMAGE *img=text_params.img;
	if(img is null)
		return;
	int len=strlen(str);
	int fg,bg,tg;
	FONT font=get_font(font_type);
	fg=text_params.fg();
	bg=text_params.bg();
	tg=fg+1;
	if(fg<0)
		fg=0;
	if(bg<0){
		bg=1;
		tg=15;
	}
	set_clip_size(str,font,img,is3d);
	img.clip.x=img.cursor.x;
	img.clip.y=img.cursor.y;
	foreach(ref c;img.clip.cells){
		c.fg=fg;
		c.bg=bg;
		c.val=0;
	}
	if(font.width>0 && font.height>0)
		print_text_bitmap(str,font,fg,bg,tg,is3d,iscolor,img.clip);
	else
		print_text_ascii(str,font,fg,bg,tg,iscolor,img.clip);

	img.is_modified=true;
}
void toggle_check_button(HWND hwnd,int idc)
{
	int flag=IsDlgButtonChecked(hwnd,idc);
	(BST_CHECKED==flag)?(flag=BST_UNCHECKED):(flag=BST_CHECKED);
	CheckDlgButton(hwnd,idc,flag);
	SendMessage(hwnd,WM_APP,0,0);
}
void combo_select_next(HWND hcombo,int dir)
{
	if(hcombo is null)
		return;
	int count=SendMessage(hcombo,CB_GETCOUNT,0,0);
	int index=SendMessage(hcombo,CB_GETCURSEL,0,0);
	if(index>=0 && count>0){
		index+=dir;
		if(index>=count)
			index=0;
		else if(index<0)
			index=count-1;
		SendMessage(hcombo,CB_SETCURSEL,index,0);
	}
	SendMessage(GetParent(hcombo),WM_APP,0,0);
}
private WNDPROC old_edit_proc=NULL;
private extern(Windows)
BOOL _edit_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	version(_DEBUG){
		print_msg(msg,wparam,lparam,hwnd);
	}
	switch(msg){
		case WM_GETDLGCODE:
			int key=wparam;
			int ctrl=GetKeyState(VK_CONTROL)&0x8000;
			int shift=GetKeyState(VK_SHIFT)&0x8000;
			if(!(ctrl || shift)){
				if(VK_RETURN==key)
					return DLGC_DEFPUSHBUTTON;
			}
			break;
		case WM_COPY:
			return 0;
			break;
		case WM_CHAR:
			if(wparam==VK_RETURN){
				int ctrl=GetKeyState(VK_CONTROL)&0x8000;
				int shift=GetKeyState(VK_SHIFT)&0x8000;
				if(!(ctrl || shift)){
					return 0;
				}
			}
			break;
		case WM_KEYDOWN:
			{
				int key=wparam;
				int ctrl=GetKeyState(VK_CONTROL)&0x8000;
				int shift=GetKeyState(VK_SHIFT)&0x8000;
				switch(key){
				case VK_ESCAPE:
					ShowWindow(GetParent(hwnd),SW_HIDE);
					break;
				case VK_F5:
					PostMessage(GetParent(hwnd),WM_APP,0,0);
					break;
				case VK_RETURN:
					if(!(ctrl || shift)){
						PostMessage(GetParent(hwnd),WM_COMMAND,MAKEWPARAM(IDOK,0),0);
						return 0;
					}
					break;
				case VK_INSERT:
					{
						int dir=1;
						if(ctrl || shift)
							dir=-1;
						combo_select_next(GetDlgItem(GetParent(hwnd),IDC_FONT),dir);
					}
					break;
				case 'A':
					if(ctrl)
						SendMessage(hwnd,EM_SETSEL,0,-1);
					break;
				case 'C':
					if(ctrl){
						IMAGE *img=get_current_image();
						if(img !is null){
							string tmp=img.get_clip_text();
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
				case VK_ADD:
					if(ctrl){
						text_spacing+=1;
						text_spacing=clamp_spacing(text_spacing);
						set_text_val(GetDlgItem(htextdlg,IDC_SPACING),text_spacing);
						SendMessage(htextdlg,WM_APP,0,0);
					}
					break;
				case VK_SUBTRACT:
					if(ctrl){
						text_spacing-=1;
						text_spacing=clamp_spacing(text_spacing);
						set_text_val(GetDlgItem(htextdlg,IDC_SPACING),text_spacing);
						SendMessage(htextdlg,WM_APP,0,0);
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
void save_text(HWND hedit,ref WCHAR[] str)
{
	import core.stdc.wchar_;
	str.length=256;
	str[0]=0;
	GetWindowText(hedit,str.ptr,str.length);
	str[$-1]=0;
	int len=wcslen(str.ptr);
	if(0==len)
		str.length=0;
}
void set_text_val(HWND hwnd,int val)
{
	char[8] str;
	_snprintf(str.ptr,str.length,"%i",val);
	SetWindowTextA(hwnd,str.ptr);
}

private WNDPROC old_edit_proc_sp=NULL;
private extern(Windows)
BOOL edit_proc_sp(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	switch(msg){
		case WM_GETDLGCODE:
			if(VK_RETURN==wparam)
				return DLGC_WANTALLKEYS;
			break;
		case WM_KEYDOWN:
			{
				int key=wparam;
				int dir=0;
				if(VK_UP==key)
					dir=1;
				else if(VK_DOWN==key)
					dir=-1;
				if(dir || VK_RETURN==key){
					char[8] str;
					int val;
					GetWindowTextA(hwnd,str.ptr,str.length);
					val=atoi(str.ptr);
					val+=dir;
					text_spacing=val;
					text_spacing=clamp_spacing(text_spacing);
					set_text_val(hwnd,text_spacing);
					SendMessage(GetParent(hwnd),WM_APP,0,0);
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
	version(M_DEBUG){
		print_msg(msg,wparam,lparam,hwnd);
	}
	switch(msg){
		case WM_INITDIALOG:
			{
				TEXT_PARAMS *tp=cast(TEXT_PARAMS*)lparam;
				if(tp is null){
					text_params.fg=null;
					text_params.bg=null;
					text_params.fill_char=null;
					text_params.hparent=NULL;
					text_params.img=null;
				}else{
					text_params=*tp;
				}
				HWND htext=GetDlgItem(hwnd,IDC_TEXT);
				SendMessage(htext,EM_SETLIMITTEXT,250,0);
				old_edit_proc=cast(WNDPROC)SetWindowLongPtr(htext,GWL_WNDPROC,cast(LONG_PTR)&_edit_proc);
				htext=GetDlgItem(hwnd,IDC_SPACING);
				SendMessage(htext,EM_SETLIMITTEXT,3,0);
				set_text_val(htext,text_spacing);
				old_edit_proc_sp=cast(WNDPROC)SetWindowLongPtr(htext,GWL_WNDPROC,cast(LONG_PTR)&edit_proc_sp);
				if(flag_is3d)
					CheckDlgButton(hwnd,IDC_3D,BST_CHECKED);
				if(flag_color)
					CheckDlgButton(hwnd,IDC_TEXTCOLOR,BST_CHECKED);
				init_font_combo(hwnd,IDC_FONT,flag_font);
				init_grippy(hwnd,IDC_GRIPPY);
				anchor_init(hwnd,text_edit_anchor);
				restore_win_rel_position(text_params.hparent,hwnd,text_win_pos);
				save_win_rel_position(text_params.hparent,hwnd,text_win_pos);
				if(last_text.length>0){
					last_text[$-1]=0;
					SetWindowText(htext,last_text.ptr);
					PostMessage(hwnd,WM_APP,0,0);
				}
			}
			break;
		case WM_SHOWWINDOW:
			if(wparam)
				restore_win_rel_position(text_params.hparent,hwnd,text_win_pos);
			else
				save_win_rel_position(text_params.hparent,hwnd,text_win_pos);
			break;
		case WM_MOVE:
			save_win_rel_position(text_params.hparent,hwnd,text_win_pos);
			break;
		case WM_SIZE:
			anchor_resize(hwnd,text_edit_anchor);
			save_win_rel_position(text_params.hparent,hwnd,text_win_pos);
			break;
		case WM_ACTIVATE:
			SetFocus(GetDlgItem(hwnd,IDC_TEXT));
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
						save_text(GetDlgItem(hwnd,IDC_TEXT),last_text);
						ShowWindow(hwnd,SW_HIDE);
					}
					break;
				case IDOK:
					save_text(GetDlgItem(hwnd,IDC_TEXT),last_text);
					ShowWindow(hwnd,SW_HIDE);
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
			case 1:
				restore_win_rel_position(text_params.hparent,hwnd,text_win_pos);
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
