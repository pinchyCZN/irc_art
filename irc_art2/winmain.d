module winmain;

import core.runtime;
import core.sys.windows.windows;
import core.sys.windows.commctrl;
import core.stdc.ctype;
import core.stdc.stdlib;
import core.stdc.stdio;
import core.stdc.string;
import resource;
import image;
import palette;
import anchor_system;
import file_image;
import text_printer;
import shortcut;
import debug_print;

HINSTANCE ghinstance=NULL;
HWND hmaindlg=NULL;
enum{
	APP_SETFOCUS=0,
	APP_REFRESH=1
}
nothrow{

CONTROL_ANCHOR[] main_win_anchor=[
	{IDC_COLORS,ANCHOR_LEFT|ANCHOR_TOP},
	{IDC_IMAGE,ANCHOR_LEFT|ANCHOR_RIGHT|ANCHOR_TOP|ANCHOR_BOTTOM},
	{IDC_EXT_COLORS,ANCHOR_RIGHT|ANCHOR_TOP|ANCHOR_BOTTOM},
	{IDC_EXTC_SBAR,ANCHOR_RIGHT|ANCHOR_TOP|ANCHOR_BOTTOM},
	{IDC_STATUS,ANCHOR_RIGHT|ANCHOR_LEFT|ANCHOR_BOTTOM},
	{IDC_GRIPPY,ANCHOR_RIGHT|ANCHOR_BOTTOM},
];
int fg_color=0;
int bg_color=1;

int get_fg_color()
{
	if(IsDlgButtonChecked(hmaindlg,IDC_FG_CHK))
		return fg_color;
	else
		return -1;
}
int get_bg_color()
{
	if(IsDlgButtonChecked(hmaindlg,IDC_BG_CHK))
		return bg_color;
	else
		return -1;
}

void select_drag(IMAGE *img,int cx,int cy)
{
	img.selection.right=cx;
	img.selection.bottom=cy;
	if(cx<img.selection.left){
		img.selection.right=img.selection.left;
		img.selection.left=cx;
	}
	if(cy<img.selection.top){
		img.selection.bottom=img.selection.top;
		img.selection.top=cy;
	}
}
int process_mouse(int flags,short x,short y)
{
	if(flags&MK_CONTROL){
		if(flags&MK_LBUTTON){
			IMAGE *img=get_current_image();
			if(image_click(img,x,y)){
				int fg,bg;
				fg=get_fg_color();
				bg=get_bg_color();
				if(fg>=0)
					img.set_fg(fg,img.cursor.x,img.cursor.y);
				if(bg>=0)
					img.set_bg(bg,img.cursor.x,img.cursor.y);
			}
		}else if(flags&MK_RBUTTON){
			IMAGE *img=get_current_image();
			if(image_click(img,x,y)){
				img.set_bg(bg_color,img.cursor.x,img.cursor.y);
			}
		}
	}else if(flags&MK_SHIFT){
	}
	else{
		if(flags&MK_LBUTTON){
			IMAGE *img=get_current_image();
			if(img is null)
				return 0;
			int cx,cy;
			if(x<0)
				x=0;
			if(y<0)
				y=0;
			cx=x/img.cell_width;
			cy=y/img.cell_height;
			img.selection.left=img.cursor.x;
			img.selection.top=img.cursor.y;
			select_drag(img,cx,cy);
			img.is_modified=true;
		}
	}
	return 0;
}
int cursor_in_clip(IMAGE *img)
{
	int result=false;
	if(img is null)
		return result;
	if(img.cursor.x >= img.clip.x){
		if(img.cursor.y >= img.clip.y){
			if(img.cursor.x < (img.clip.x+img.clip.width))
				if(img.cursor.y < (img.clip.y+img.clip.height))
					result=true;
		}
	}
	return result;
}
int handle_clip_key(IMAGE *img,int vkey,int ctrl,int shift)
{
	int result=false;
	if(img is null)
		return result;
	if(img.clip.width<=0 || img.clip.height<=0)
		return result;
	if(!cursor_in_clip(img))
		return result;
	void move_clip(int x,int y){
		if(ctrl)
			return;
		img.clip.x+=x;
		img.clip.y+=y;
		result=true;
		if(img.clip.x<0){
			img.clip.x=0;
			result=false;
		}
		if(img.clip.y<0){
			img.clip.y=0;
			result=false;
		}
		if(img.clip.x>=img.width){
			img.clip.x=img.width-1;
			result=false;
		}
		if(img.clip.y>=img.height){
			img.clip.y=img.height-1;
			result=false;
		}
	}
	switch(vkey){
	case VK_DELETE:
		img.clip.cells.length=0;
		img.clip.width=0;
		img.clip.height=0;
		result=true;
		break;
	case VK_LEFT:
		move_clip(-1,0);
		break;
	case VK_RIGHT:
		move_clip(1,0);
		break;
	case VK_UP:
		move_clip(0,-1);
		break;
	case VK_DOWN:
		move_clip(0,1);
		break;
	case VK_RETURN:
		{
			int x,y;
			for(y=0;y<img.clip.height;y++){
				for(x=0;x<img.clip.width;x++){
					if(!img.clip.is_valid_pos(x,y))
						continue;
					int index=x+y*img.clip.width;
					CELL *cell=&img.clip.cells[index];
					int mx,my;
					mx=x+img.clip.x;
					my=y+img.clip.y;
					img.set_fg(cell.fg,mx,my);
					img.set_bg(cell.bg,mx,my);
					img.set_char(cell.val,mx,my);
				}
			}
			img.clip.cells.length=0;
			img.clip.width=0;
			img.clip.height=0;
		}
		break;
	default:
		break;
	}
	if(result)
	   img.is_modified=true;
	return result;	
}
int handle_selection_key(IMAGE *img,int vkey,int ctrl,int shift)
{
	int result=false;
	if(img is null)
		return result;
	switch(vkey){
	case VK_DELETE:
		{
			int w,h;
			w=img.selection_width();
			h=img.selection_height();
			if(w>0 && h>0){
				int i,j;
				for(i=0;i<h;i++){
					for(j=0;j<w;j++){
						int index;
						int x,y;
						index=j+i*w;
						if(index>=img.cells.length)
							break;
						x=img.selection.left+j;
						y=img.selection.top+i;
						img.set_char(' ',x,y);
						result=true;
					}
				}
			}
		}
		break;
	default:
		break;
	}
	if(result){
		img.is_modified=true;
	}
	return result;
}
int selection_to_clip(IMAGE *img)
{
	int result=false;
	if(img is null)
		return result;
	int w,h;
	w=img.selection_width();
	h=img.selection_height();
	if(w<=0 || h<=0)
		return result;
	img.clip.cells.length=w*h;
	img.clip.width=w;
	img.clip.height=h;
	img.clip.x=img.selection.left;
	img.clip.y=img.selection.top;
	int i,j;
	for(i=0;i<h;i++){
		for(j=0;j<w;j++){
			int src_index,dst_index;
			int x,y;
			x=img.selection.left+j;
			y=img.selection.top+i;
			src_index=x+y*img.width;
			if(src_index>=img.cells.length)
				continue;
			dst_index=j+i*w;
			if(dst_index>=img.clip.cells.length)
				continue;
			CELL *src,dst;
			src=&img.cells[src_index];
			dst=&img.clip.cells[dst_index];
			*dst=*src;
			result=true;
		}
	}
	if(result)
		img.is_modified=true;
	return result;
}
void toggle_check(HWND hwnd,int idc)
{
	int chk=IsDlgButtonChecked(hwnd,idc);
	int state=BST_CHECKED;
	if(chk)
		state=BST_UNCHECKED;
	CheckDlgButton(hwnd,idc,state);
}

WNDPROC old_image_proc=NULL;
extern (Windows)
BOOL image_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	version(M_DEBUG) {
	if(msg!=WM_SETCURSOR && msg!=WM_MOUSEFIRST && msg!=WM_NCHITTEST && msg!=WM_PAINT){
		printf(">");
		print_msg(msg,wparam,lparam,hwnd);
	}
	}
	
	switch(msg){
		case WM_KILLFOCUS:
		case WM_SETFOCUS:
			return 0;
			break;
		case WM_GETDLGCODE:
			return DLGC_WANTARROWS|DLGC_WANTCHARS|DLGC_WANTMESSAGE|DLGC_WANTALLKEYS;
			break;
		case WM_LBUTTONDOWN:
			{
				int x,y;
				x=LOWORD(lparam);
				y=HIWORD(lparam);
				IMAGE *img=get_current_image();
				if(img !is null){
					image_click(img,x,y);
					memset(&img.selection,0,img.selection.sizeof);
				}
				SetFocus(hwnd);
				return 0;
			}
			break;
		case WM_MOUSEMOVE:
			{
				short x,y;
				int flags;
				x=LOWORD(lparam);
				y=HIWORD(lparam);
				flags=wparam;
				process_mouse(flags,x,y);
			}
			break;
		case WM_CHAR:
			{
				int x,y;
				int code=wparam;
				int ctrl=GetKeyState(VK_CONTROL)&0x8000;
				int shift=GetKeyState(VK_SHIFT)&0x8000;
				IMAGE *img=get_current_image();
				if(img is null)
					break;
				if(code>=' ' && code<=0x7F){
					if(ctrl){
						break;
					}
					if(shift){
						int caps=GetKeyState(VK_CAPITAL)&1;
						if(caps)
							code=tolower(code);
						else
							code=toupper(code);
					}
					x=img.cursor.x;
					y=img.cursor.y;
					code=0x2580+rand()%10;
					img.set_char(code,x,y);
					img.set_fg(fg_color,x,y);
					img.move_cursor(1,0);
					img.clear_selection();
				}else if('\r'==code){
					img.move_cursor(0,1);
					img.clear_selection();
				}else if('\b'==code){
					img.move_cursor(-1,0);
					x=img.cursor.x;
					y=img.cursor.y;
					img.set_char(' ',x,y);
					img.clear_selection();
				}else{
					if(ctrl){
						if(!shift){
							if(3==code){ //ctrl-c
								if(img.selection_width()>0
								   && img.selection_height()>0){
									selection_to_clip(img);
									memset(&img.selection,0,img.selection.sizeof);
								}else{
									if(img.clip.width>0 && img.clip.height>0){
										string tmp=get_text_cells(img.clip.cells,img.clip.width,img.clip.height);
										if(tmp.length>0){
											tmp~='\0';
											copy_str_clipboard(tmp.ptr);
										}
									}else{
										image_to_clipboard(img);
									}
								}
							}else if(0x16==code){ //ctrl-v
								import_clipboard(hmaindlg,*img,FALSE,get_fg_color(),get_bg_color());
								img.is_modified=false;
								PostMessage(hmaindlg,WM_APP,APP_REFRESH,0);
							}else if(1==code){ //ctrl-a
								img.selection.left=0;
								img.selection.top=0;
								img.selection.bottom=img.height;
								img.selection.right=img.width;
								img.is_modified=true;
							}else if(6==code){ //ctrl-f
								if(img.cursor_in_clip()){
									flip_clip(img);
								}else
									do_fill(img,get_fg_color(),get_bg_color());
							}else if(12==code){ //ctrl-r

							}
						}else if(0x16==code){ //ctrl-v
							import_clipboard(hmaindlg,*img,TRUE,get_fg_color(),get_bg_color());
							img.is_modified=false;
							PostMessage(hmaindlg,WM_APP,APP_REFRESH,0);
						}
						break;
					}
				}
			}
			break;
		case WM_KEYDOWN:
			{
				int vkey=wparam;
				int ctrl=GetKeyState(VK_CONTROL)&0x8000;
				int shift=GetKeyState(VK_SHIFT)&0x8000;
				int process=FALSE;
				int ox,oy;
				IMAGE *img=get_current_image();
				if(img is null)
					break;
				ox=img.cursor.x;
				oy=img.cursor.y;
				switch(vkey){
					case VK_INSERT:
						if(ctrl){
							SC_DLG_PARAM scp;
							scp.hparent=GetParent(hwnd);
							scp.hinstance=ghinstance;
							DialogBoxParam(ghinstance,MAKEINTRESOURCE(IDD_KEYS),hwnd,&dlg_keyshort,cast(LPARAM)&scp);
						}else{
							static HWND htextdlg;
							TEXT_PARAMS tp;
							tp.hparent=hmaindlg;
							tp.img=get_current_image();
							tp.fg=get_fg_color();
							tp.bg=get_bg_color();
							if(tp.img is null)
								break;
							DialogBoxParam(ghinstance,MAKEINTRESOURCE(IDD_TEXT),hwnd,&dlg_text,cast(LPARAM)&tp);
							/*
							if(htextdlg is null)
								htextdlg=CreateDialogParam(ghinstance,MAKEINTRESOURCE(IDD_TEXT),hmaindlg,&dlg_text,cast(LPARAM)&tp);
							if(htextdlg !is null)
								SetWindowPos(htextdlg,HWND_TOP,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_SHOWWINDOW);
							*/
						}
						break;
					case VK_HOME:
						{
							if(0==img.cursor.x){
								img.move_cursor(0,-img.cursor.y);
							}else{
								img.move_cursor(-img.cursor.x,0);
							}
						}
						break;
					case VK_END:
						{
							img.move_cursor(-img.cursor.x,0);
							img.move_cursor(img.width-1,0);
						}
						break;
					case VK_LEFT:
						handle_clip_key(img,vkey,ctrl,shift);
						img.move_cursor(-1,0);
						process=TRUE;
						break;
					case VK_RIGHT:
						handle_clip_key(img,vkey,ctrl,shift);
						img.move_cursor(1,0);
						process=TRUE;
						break;
					case VK_UP:
						handle_clip_key(img,vkey,ctrl,shift);
						img.move_cursor(0,-1);
						process=TRUE;
						break;
					case VK_DOWN:
						handle_clip_key(img,vkey,ctrl,shift);
						img.move_cursor(0,1);
						process=TRUE;
						break;
					case VK_ESCAPE:
						PostQuitMessage(0);
						break;
					case VK_DELETE:
						{
							int x,y;
							x=img.cursor.x;
							y=img.cursor.y;
							if(!handle_clip_key(img,vkey,ctrl,shift))
								if(!handle_selection_key(img,vkey,ctrl,shift))
									img.set_char(' ',x,y);
						}
						break;
					case VK_RETURN:
						handle_clip_key(img,vkey,ctrl,shift);
						break;
					case '1':
						if(ctrl)
							toggle_check(hmaindlg,IDC_FG_CHK);
						break;
					case '2':
						if(ctrl)
							toggle_check(hmaindlg,IDC_BG_CHK);
						break;
					default:
						break;
				}
				if(process){
					int x,y;
					x=img.cursor.x;
					y=img.cursor.y;
					if(ctrl){
						int is_inside_clip(int x,int y){
							int cx,cy,cw,ch;
							cx=img.clip.x;
							cy=img.clip.y;
							cw=img.clip.width;
							ch=img.clip.height;
							if(0==cw || 0==ch)
								return false;
							if(x>=cx && x<(cx+cw)){
								if(y>=cy && y<(cy+ch))
									return true;
							}
							return false;
						}
						int fg,bg;
						fg=get_fg_color();
						bg=get_bg_color();
						if(fg>=0){
							if(!is_inside_clip(ox,oy)){
								img.set_fg(fg,ox,oy);
								if(!is_inside_clip(x,y))
									img.set_fg(fg,x,y);
							}
						}
						if(bg>=0){
							if(!is_inside_clip(ox,oy)){
								img.set_bg(bg,ox,oy);
								if(!is_inside_clip(x,y))
									img.set_bg(bg,x,y);
							}
						}
					}
				}
			}
			break;
		default:
			break;
	}
	IMAGE *img=get_current_image();
	if(img !is null){
		if(img.is_modified){
			InvalidateRect(hwnd,NULL,FALSE);
			img.is_modified=false;
			update_status(hmaindlg);
		}
	}

	return CallWindowProc(old_image_proc,hwnd,msg,wparam,lparam);
}

WNDPROC old_palette_proc=NULL;
extern(Windows)
BOOL palette_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	switch(msg){
		case WM_LBUTTONDOWN:
		case WM_MBUTTONDOWN:
		case WM_RBUTTONDOWN:
			{
				int x,y;
				HWND htmp;
				x=LOWORD(lparam);
				y=HIWORD(lparam);
				palette_click(x,y,msg,&fg_color,&bg_color);
				htmp=GetDlgItem(hmaindlg,IDC_FG);
				if(htmp)
					InvalidateRect(htmp,NULL,FALSE);
				htmp=GetDlgItem(hmaindlg,IDC_BG);
				if(htmp)
					InvalidateRect(htmp,NULL,FALSE);
				PostMessage(hmaindlg,WM_APP,APP_SETFOCUS,0);
			}
			break;
		default:
			break;
	}
	return CallWindowProc(old_palette_proc,hwnd,msg,wparam,lparam);
}
WNDPROC old_ext_palette_proc=NULL;
extern(Windows)
BOOL ext_palette_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	switch(msg){
		case WM_LBUTTONDOWN:
		case WM_MBUTTONDOWN:
		case WM_RBUTTONDOWN:
			{
				int x,y;
				HWND htmp;
				x=LOWORD(lparam);
				y=HIWORD(lparam);
				ext_palette_click(x,y,msg,&fg_color,&bg_color);
				htmp=GetDlgItem(hmaindlg,IDC_FG);
				if(htmp)
					InvalidateRect(htmp,NULL,FALSE);
				htmp=GetDlgItem(hmaindlg,IDC_BG);
				if(htmp)
					InvalidateRect(htmp,NULL,FALSE);
				PostMessage(hmaindlg,WM_APP,APP_SETFOCUS,0);
			}
			break;
		default:
			break;
	}
	return CallWindowProc(old_palette_proc,hwnd,msg,wparam,lparam);
}

int get_wnd_int(HWND hwnd)
{
	char[10] str=0;
	GetWindowTextA(hwnd,str.ptr,str.length);
	return atoi(str.ptr);
}
int set_wind_int(HWND hwnd,int val)
{
	int result;
	char[10] str=0;
	_snprintf(str.ptr,str.length,"%i",val);
	result=SetWindowTextA(hwnd,str.ptr);
	SendMessage(hwnd,EM_SETSEL,0,-1);
	SendMessage(hwnd,EM_SETSEL,-1,-1);
	return result;
}

WNDPROC old_edit_proc=NULL;
extern(Windows)
BOOL edit_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	version(M_DEBUG){
		printf("==");
		print_msg(msg,wparam,lparam,hwnd);
	}
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
					int w,h;
					int id;
					int x=get_wnd_int(hwnd);
					x+=dir;
					if(x<1)
						x=1;
					else if(x>500)
						x=500;
					id=GetDlgCtrlID(hwnd);
					IMAGE *img=get_current_image();
					if(img is null)
						break;
					if(IDC_ROWS==id){
						w=img.width;
						h=x;
					}else{
						w=x;
						h=img.height;
					}
					img.resize_image(w,h);
					set_wind_int(hwnd,x);
					InvalidateRect(GetDlgItem(hmaindlg,IDC_IMAGE),NULL,TRUE);
				}
			}
			break;
		default:
			break;
	}
	return CallWindowProc(old_edit_proc,hwnd,msg,wparam,lparam);
}
void display_image_size(HWND hwnd)
{
	char[40] tmp=0;
	int w,h;
	IMAGE *img=get_current_image();
	if(img is null)
		return;
	w=img.width;
	h=img.height;
	_snprintf(tmp.ptr,tmp.length,"%i",w);
	SetDlgItemTextA(hwnd,IDC_COLS,tmp.ptr);
	_snprintf(tmp.ptr,tmp.length,"%i",h);
	SetDlgItemTextA(hwnd,IDC_ROWS,tmp.ptr);
}
void update_status(HWND hwnd)
{
	HWND hstatus=GetDlgItem(hwnd,IDC_STATUS);
	if(hstatus is null)
		return;
	IMAGE *img=get_current_image();
	if(img is null){
		SetWindowText(hwnd,"");
		return;
	}
	char[80] tmp=0;
	_snprintf(tmp.ptr,tmp.length,"CURSOR=%i,%i",img.cursor.x,img.cursor.y);
	if(img.clip.width>0 || img.clip.height>0){
		_snprintf(tmp.ptr,tmp.length,"%s | clip size=%i,%i",tmp.ptr,img.clip.width,img.clip.height);
	}
	if(img.selection_width()>0 || img.selection_height()>0){
		_snprintf(tmp.ptr,tmp.length,"%s | selection size=%i,%i",tmp.ptr,img.selection_width(),img.selection_height());
	}
	tmp[$-1]=0;
	SetWindowTextA(hstatus,tmp.ptr);
}
extern(Windows)
BOOL main_dlg_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	version(M_DEBUG){
	if(msg!=WM_SETCURSOR && msg!=WM_MOUSEFIRST && msg!=WM_NCHITTEST)
		print_msg(msg,wparam,lparam,hwnd);
	}
	switch(msg){
		case WM_INITDIALOG:
			anchor_init(hwnd,main_win_anchor);
			init_grippy(hwnd,IDC_GRIPPY);
			init_image();
			display_image_size(hwnd);
			update_status(hwnd);
			old_image_proc=cast(WNDPROC)SetWindowLongPtr(GetDlgItem(hwnd,IDC_IMAGE),GWL_WNDPROC,cast(LONG_PTR)&image_proc);
			old_palette_proc=cast(WNDPROC)SetWindowLongPtr(GetDlgItem(hwnd,IDC_COLORS),GWL_WNDPROC,cast(LONG_PTR)&palette_proc);
			old_edit_proc=cast(WNDPROC)SetWindowLongPtr(GetDlgItem(hwnd,IDC_ROWS),GWL_WNDPROC,cast(LONG_PTR)&edit_proc);
			old_edit_proc=cast(WNDPROC)SetWindowLongPtr(GetDlgItem(hwnd,IDC_COLS),GWL_WNDPROC,cast(LONG_PTR)&edit_proc);
			old_ext_palette_proc=cast(WNDPROC)SetWindowLongPtr(GetDlgItem(hwnd,IDC_EXT_COLORS),GWL_WNDPROC,cast(LONG_PTR)&ext_palette_proc);
			SetFocus(GetDlgItem(hwnd,IDC_IMAGE));
			SendMessage(GetDlgItem(hwnd,IDC_ROWS),EM_LIMITTEXT,4,0);
			SendMessage(GetDlgItem(hwnd,IDC_COLS),EM_LIMITTEXT,4,0);
			SetDlgItemText(hwnd,IDC_STATUS,"asdasd");
			break;
		case WM_SIZE:
			{
				anchor_resize(hwnd,main_win_anchor);
			}
			break;
		case WM_DROPFILES:
			{
				HDROP hdrop=cast(HANDLE)wparam;
				IMAGE *img=get_current_image();
				drop_file(hwnd,hdrop,img,get_fg_color(),get_bg_color());
			}
			break;
		case WM_APP:
			{
				switch(wparam){
					case APP_SETFOCUS:
						SetFocus(GetDlgItem(hwnd,IDC_IMAGE));
						break;
					case APP_REFRESH:
						InvalidateRect(GetDlgItem(hwnd,IDC_IMAGE),NULL,TRUE);
						display_image_size(hwnd);
						update_status(hwnd);
						break;
					default:
						break;
				}
			}
			break;
		case WM_COMMAND:
			{
				int idc=LOWORD(wparam);
				switch(idc){
					case IDM_SAVE:
						file_save(hwnd,get_current_image());
						break;
					case IDM_SAVEAS:
						file_saveas(hwnd,get_current_image());
						break;
					case IDM_FILEOPEN:
						{
							IMAGE *img=get_current_image();
							if(img !is null)
								file_open(hwnd,*img,get_fg_color(),get_bg_color());
						}
						break;
					case IDM_COPYTOCLIP:
						{
							IMAGE *img=get_current_image();
							if(img is null)
								break;
							image_to_clipboard(img);
						}
						break;
					case IDCANCEL:
						DestroyWindow(hwnd);
						PostQuitMessage(0);
						break;
					case IDC_FILE:
						{
							static HMENU hmenu=NULL;
							if(!hmenu)
								hmenu=LoadMenu(ghinstance,MAKEINTRESOURCE(IDR_MENU1));
							if(hmenu){
								HMENU hsubm=GetSubMenu(hmenu,0);
								POINT p={0};
								GetCursorPos(&p);
								TrackPopupMenu(hsubm,TPM_CENTERALIGN,p.x,p.y,0,hwnd,NULL);
							}
						}
						break;
					case IDC_FG:
					case IDC_BG:
						PostMessage(hwnd,WM_APP,APP_SETFOCUS,0);
						break;
					case IDC_FG_CHK:
					case IDC_BG_CHK:
						PostMessage(hwnd,WM_APP,APP_SETFOCUS,0);
						break;
					default:
						break;
				}
			}
			break;
		case WM_DRAWITEM:
			{
				DRAWITEMSTRUCT *di=cast(LPDRAWITEMSTRUCT)lparam;
				if(!di)
					break;
				switch(di.CtlID){
					case IDC_IMAGE:
						{
							HWND htmp=di.hwndItem;
							HDC hdc=di.hDC;
							paint_image(htmp,hdc);
							return TRUE;
						}
						break;
					case IDC_COLORS:
						{
							HWND htmp=di.hwndItem;
							HDC hdc=di.hDC;
							paint_colors(htmp,hdc);
							return TRUE;
						}
						break;
					case IDC_FG:
					case IDC_BG:
						{
							HWND htmp=di.hwndItem;
							HDC hdc=di.hDC;
							paint_current_colors(htmp,hdc,di.CtlID,fg_color,bg_color);
						}
						break;
					case IDC_EXT_COLORS:
						{
							HWND htmp=di.hwndItem;
							HDC hdc=di.hDC;
							paint_ext_colors(htmp,hdc);
						}
						break;
					default:
						break;
				}
			}
			break;
		case WM_PAINT:
			break;
		case WM_CLOSE:
			DestroyWindow(hwnd);
			PostQuitMessage(0);
			break;
		default:
			break;
	}
	return 0;
}

} //nothrow

int debug_console(HWND hwnd)
{
	RECT rect;
	open_console();
	GetWindowRect(hwnd,&rect);
	move_console(rect.right,0);
	return 0;
}

extern (Windows)
int WinMain(HINSTANCE hinstance,HINSTANCE hprevinstance,LPSTR cmd_line,int cmd_show)
{
	INITCOMMONCONTROLSEX ctrls;

	Runtime.initialize();
	ghinstance=hinstance;
	ctrls.dwSize=ctrls.sizeof;
	ctrls.dwICC=ICC_LISTVIEW_CLASSES|ICC_TREEVIEW_CLASSES|ICC_BAR_CLASSES|ICC_TAB_CLASSES|ICC_PROGRESS_CLASS|ICC_HOTKEY_CLASS;
	InitCommonControlsEx(&ctrls);

	hmaindlg=CreateDialog(hinstance,MAKEINTRESOURCE(IDD_MAINDLG),NULL,&main_dlg_proc);
	if(!hmaindlg){
		MessageBox(NULL,"Unable to create window","ERROR",MB_OK|MB_SYSTEMMODAL);
		return 0;
	}
	ShowWindow(hmaindlg,SW_SHOW);
	version(M_DEBUG)
	{
		debug_console(hmaindlg);
	}
	while (1){
		int ret;
		MSG msg;
		ret=GetMessage(&msg,NULL,0,0);
		if(-1==ret || 0==ret){
			break;
		}else{
			if(!IsDialogMessage(hmaindlg,&msg)){
				//TranslateMessage(&msg);
				DispatchMessage(&msg);
			}
		}
		//		else{
		//			print_msg(msg.message,msg.lParam,msg.wParam,msg.hwnd);
		//		}
	}

	return 0;
}
