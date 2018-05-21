#include <windows.h>
#include <commctrl.h>
#include <fcntl.h>
#include <stdio.h>

#include "resource.h"

HINSTANCE ghinstance=0;
HWND hmaindlg=0;

int process_mouse(int flags,int x,int y)
{
	if(flags&MK_CONTROL){
		if(flags&MK_LBUTTON){
			image_click(x,y,0);
			map_pixel_cell(&x,&y);
			set_fg(get_color_fg(),x,y);
		}else if(flags&MK_RBUTTON){
			image_click(x,y,0);
			map_pixel_cell(&x,&y);
			set_bg(get_color_bg(),x,y);
		}
	}else if(flags&MK_SHIFT){
	}
	else{
		if(flags&MK_LBUTTON){
			image_click(x,y,MK_LBUTTON);
		}
	}
	return 0;
}
WNDPROC old_image_proc=0;
LRESULT CALLBACK image_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	static void *state=0;
#ifdef _DEBUG
	if(msg!=WM_SETCURSOR && msg!=WM_MOUSEFIRST && msg!=WM_NCHITTEST && msg!=WM_PAINT){
		printf(">");
		print_msg(msg,wparam,lparam,hwnd);
	}
#endif
	if(!state)
		alloc_state(&state);
	save_current_state(state);
	switch(msg){
	case WM_GETDLGCODE:
		return DLGC_WANTARROWS|DLGC_WANTCHARS|DLGC_WANTMESSAGE|DLGC_WANTALLKEYS;
		break;
	case WM_LBUTTONDOWN:
		{
			int x,y;
			x=LOWORD(lparam);
			y=HIWORD(lparam);
			process_mouse(MK_LBUTTON,x,y);
		}
		break;
	case WM_MOUSEMOVE:
		{
			int x,y;
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
				x=get_cursor_x();
				y=get_cursor_y();
				set_char(code,x,y);
				set_fg(get_color_fg(),x,y);
				move_cursor(1,0);
			}else if('\r'==code){
				move_cursor(0,1);
			}else if('\b'==code){
				move_cursor(-1,0);
				x=get_cursor_x();
				y=get_cursor_y();
				set_char(' ',x,y);
			}else{
				if(ctrl){
					if(!shift){
						if(3==code)
							image_to_clipboard();
						else if(0x16==code){
							import_clipboard(hmaindlg);
						}
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
			ox=get_cursor_x();
			oy=get_cursor_y();
			switch(vkey){
			case VK_LEFT:
				move_cursor(-1,0);
				process=TRUE;
				break;
			case VK_RIGHT:
				move_cursor(1,0);
				process=TRUE;
				break;
			case VK_UP:
				move_cursor(0,-1);
				process=TRUE;
				break;
			case VK_DOWN:
				move_cursor(0,1);
				process=TRUE;
				break;
			case VK_ESCAPE:
				PostQuitMessage(0);
				break;
			case VK_DELETE:
				{
					int x,y;
					x=get_cursor_x();
					y=get_cursor_y();
					set_char(' ',x,y);
				}
				break;
			default:
				if(ctrl){

				}
				break;
			}
			if(process){
				int x,y;
				x=get_cursor_x();
				y=get_cursor_y();
				if(ctrl){
					set_bg(get_color_bg(),ox,oy);
					set_bg(get_color_bg(),x,y);
				}else if(shift){
					set_fg(get_color_fg(),ox,oy);
					set_fg(get_color_fg(),x,y);
				}
			}
		}
		break;
	}
	if(state_changed(state))
		InvalidateRect(hwnd,NULL,FALSE);

	return CallWindowProc(old_image_proc,hwnd,msg,wparam,lparam);
}

WNDPROC old_palette_proc=0;
LRESULT CALLBACK palette_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
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
			palette_click(x,y,msg);
			if(htmp=GetDlgItem(hmaindlg,IDC_FG))
				InvalidateRect(htmp,NULL,FALSE);
			if(htmp=GetDlgItem(hmaindlg,IDC_BG))
				InvalidateRect(htmp,NULL,FALSE);
			PostMessage(hmaindlg,WM_APP,0,0);
		}
		break;
	}
	return CallWindowProc(old_palette_proc,hwnd,msg,wparam,lparam);
}
int get_wnd_int(HWND hwnd)
{
	char str[10]={0};
	GetWindowText(hwnd,str,sizeof(str));
	return atoi(str);
}
int set_wind_int(HWND hwnd,int val)
{
	char str[10]={0};
	_snprintf(str,sizeof(str),"%i",val);
	return SetWindowText(hwnd,str);
}
WNDPROC old_edit_proc=0;
LRESULT CALLBACK edit_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	switch(msg){
	case WM_KEYDOWN:
		{
			int key=wparam;
			int dir=0;
			if(VK_UP==key)
				dir=1;
			else if(VK_DOWN==key)
				dir=-1;
			if(dir){
				int w,h;
				int id;
				int x=get_wnd_int(hwnd);
				x+=dir;
				if(x<1)
					x=1;
				else if(x>500)
					x=500;
				id=GetDlgCtrlID(hwnd);
				if(IDC_ROWS==id){
					w=get_cols();
					h=x;
				}else{
					w=x;
					h=get_rows();
				}
				resize_grid(w,h);
				set_wind_int(hwnd,x);
				InvalidateRect(GetDlgItem(hmaindlg,IDC_IMAGE),NULL,TRUE);
			}
		}
		break;
	}
	return CallWindowProc(old_edit_proc,hwnd,msg,wparam,lparam);
}
int display_image_size(HWND hwnd)
{
	char tmp[40]={0};
	int w,h;
	w=get_cols();
	h=get_rows();
	_snprintf(tmp,sizeof(tmp),"%i",w);
	SetDlgItemText(hwnd,IDC_COLS,tmp);
	_snprintf(tmp,sizeof(tmp),"%i",h);
	SetDlgItemText(hwnd,IDC_ROWS,tmp);
	return 0;
}
BOOL CALLBACK main_dlg_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	static HWND hgrip=0;
#ifdef _DEBUG
	if(msg!=WM_SETCURSOR && msg!=WM_MOUSEFIRST && msg!=WM_NCHITTEST)
		print_msg(msg,wparam,lparam,hwnd);
#endif
	switch(msg){
	case WM_INITDIALOG:
		create_vga_font();
		init_colors();
		resize_grid(80,40);
		display_image_size(hwnd);
		old_image_proc=SetWindowLong(GetDlgItem(hwnd,IDC_IMAGE),GWL_WNDPROC,(LONG)image_proc);
		old_palette_proc=SetWindowLong(GetDlgItem(hwnd,IDC_COLORS),GWL_WNDPROC,(LONG)palette_proc);
		old_edit_proc=SetWindowLong(GetDlgItem(hwnd,IDC_ROWS),GWL_WNDPROC,(LONG)edit_proc);
		old_edit_proc=SetWindowLong(GetDlgItem(hwnd,IDC_COLS),GWL_WNDPROC,(LONG)edit_proc);
		SetFocus(GetDlgItem(hwnd,IDC_IMAGE));
		hgrip=create_grippy(hwnd);
		init_main_win_anchor(hwnd);
		SendMessage(GetDlgItem(hwnd,IDC_ROWS),EM_LIMITTEXT,4,0);
		SendMessage(GetDlgItem(hwnd,IDC_COLS),EM_LIMITTEXT,4,0);
		break;
	case WM_SIZE:
		{
			grippy_move(hwnd,hgrip);
			resize_main_win(hwnd);
		}
		break;
	case WM_APP:
		{
			switch(wparam){
			case 0:
				SetFocus(GetDlgItem(hwnd,IDC_IMAGE));
				break;
			case 1:
				InvalidateRect(GetDlgItem(hwnd,IDC_IMAGE),0,TRUE);
				display_image_size(hwnd);
				break;
			}
		}
		break;
	case WM_COMMAND:
		{
			int idc=LOWORD(wparam);
			switch(idc){
			case IDM_SAVE:
				file_save(hwnd);
				break;
			case IDM_SAVEAS:
				file_saveas(hwnd);
				break;
			case IDM_FILEOPEN:
				file_open(hwnd);
				break;
			case IDM_COPYTOCLIP:
				image_to_clipboard();
				break;
			case IDCANCEL:
				DestroyWindow(hwnd);
				PostQuitMessage(0);
				break;
			case IDC_FILE:
				{
					static HMENU hmenu=0;
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
			}
		}
		break;
	case WM_DRAWITEM:
		{
			DRAWITEMSTRUCT *di=lparam;
			if(!di)
				break;
			switch(di->CtlID){
			case IDC_IMAGE:
				{
					HWND htmp=di->hwndItem;
					HDC hdc=di->hDC;
					paint_window(htmp,hdc);
					return TRUE;
				}
				break;
			case IDC_COLORS:
				{
					HWND htmp=di->hwndItem;
					HDC hdc=di->hDC;
					paint_colors(htmp,hdc);
					return TRUE;
				}
				break;
			case IDC_FG:
			case IDC_BG:
				{
					HWND htmp=di->hwndItem;
					HDC hdc=di->hDC;
					paint_current_colors(htmp,hdc,di->CtlID);
				}
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
	}
	return 0;
}

int debug_console(HWND hwnd)
{
	RECT rect;
	open_console();
	GetWindowRect(hwnd,&rect);
	move_console(rect.right,0);
	return 0;
}
int WINAPI WinMain(HINSTANCE hinstance,HINSTANCE hprevinstance,LPSTR cmd_line,int cmd_show)
{
	INITCOMMONCONTROLSEX ctrls;

	ghinstance=hinstance;
	ctrls.dwSize=sizeof(ctrls);
	ctrls.dwICC=ICC_LISTVIEW_CLASSES|ICC_TREEVIEW_CLASSES|ICC_BAR_CLASSES|ICC_TAB_CLASSES|ICC_PROGRESS_CLASS|ICC_HOTKEY_CLASS;
	InitCommonControlsEx(&ctrls);

	hmaindlg=CreateDialog(hinstance,MAKEINTRESOURCE(IDD_MAINDLG),NULL,main_dlg_proc);
	if(!hmaindlg){
		MessageBox(NULL,"Unable to create window","ERROR",MB_OK|MB_SYSTEMMODAL);
		return 0;
	}
	ShowWindow(hmaindlg,SW_SHOW);
#ifdef _DEBUG
	debug_console(hmaindlg);
#endif

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
