#include <windows.h>
#include <commctrl.h>
#include <fcntl.h>
#include <stdio.h>

#include "resource.h"

HINSTANCE ghinstance=0;
HWND hmaindlg=0;

WNDPROC old_image_proc=0;
LRESULT CALLBACK image_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	if(msg!=WM_SETCURSOR && msg!=WM_MOUSEFIRST && msg!=WM_NCHITTEST && msg!=WM_PAINT){
		printf(">");
		print_msg(msg,wparam,lparam,hwnd);
	}
	switch(msg){
	case WM_GETDLGCODE:
		return DLGC_WANTARROWS|DLGC_WANTCHARS|DLGC_WANTMESSAGE|DLGC_WANTALLKEYS;
		break;
	case WM_LBUTTONDOWN:
		{
			int x,y;
			x=LOWORD(lparam);
			y=HIWORD(lparam);
			image_click(x,y,MK_LBUTTON);
			InvalidateRect(hwnd,NULL,FALSE);
		}
		break;
	case WM_MOUSEMOVE:
		{
			int x,y;
			int flags;
			x=LOWORD(lparam);
			y=HIWORD(lparam);
			flags=wparam;
			if(flags&MK_CONTROL){
				if(flags&MK_LBUTTON){
					image_click(x,y,0);
					map_pixel_cell(&x,&y);
					set_bg(get_color_fg(),x,y);
				}else if(flags&MK_RBUTTON){
					image_click(x,y,0);
					map_pixel_cell(&x,&y);
					set_fg(get_color_bg(),x,y);
				}
			}else if(flags&MK_SHIFT){
			}
			else{
				if(flags&MK_LBUTTON){
					image_click(x,y,MK_LBUTTON);
					InvalidateRect(hwnd,NULL,FALSE);
				}
			}
		}
		break;
	case WM_CHAR:
		{
			int x,y;
			int code=wparam;
			int ctrl=GetKeyState(VK_CONTROL)&0x8000;
			int shift=GetKeyState(VK_SHIFT)&0x8000;
			if(code>=' ' && code<=0x7F){
				if(ctrl)
					break;
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
			}
		}
		break;
	case WM_KEYDOWN:
		{
			int vkey=wparam;
			int ctrl=GetKeyState(VK_CONTROL)&0x8000;
			int shift=GetKeyState(VK_SHIFT)&0x8000;
			switch(vkey){
			case VK_LEFT:
				move_cursor(-1,0);
				break;
			case VK_RIGHT:
				move_cursor(1,0);
				break;
			case VK_UP:
				move_cursor(0,-1);
				break;
			case VK_DOWN:
				move_cursor(0,1);
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
				break;
			}
			InvalidateRect(hwnd,NULL,FALSE);
		}
		break;
	}
	CallWindowProc(old_image_proc,hwnd,msg,wparam,lparam);
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
	CallWindowProc(old_palette_proc,hwnd,msg,wparam,lparam);
}
WNDPROC old_edit_proc=0;
LRESULT CALLBACK edit_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	switch(msg){
	case WM_KEYDOWN:
		{
			int key=wparam;
			if(VK_UP){

			}else if(VK_DOWN){

			}
		}
		break;
	}
	CallWindowProc(old_edit_proc,hwnd,msg,wparam,lparam);
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
	//if(msg!=WM_SETCURSOR && msg!=WM_MOUSEFIRST && msg!=WM_NCHITTEST)
	//	print_msg(msg,wparam,lparam,hwnd);
	switch(msg){
	case WM_INITDIALOG:
		create_vga_font();
		init_colors();
		update_cells(get_rows(),get_cols());
		display_image_size(hwnd);
		old_image_proc=SetWindowLong(GetDlgItem(hwnd,IDC_IMAGE),GWL_WNDPROC,image_proc);
		old_palette_proc=SetWindowLong(GetDlgItem(hwnd,IDC_COLORS),GWL_WNDPROC,palette_proc);
		old_edit_proc=SetWindowLong(GetDlgItem(hwnd,IDC_ROWS),GWL_WNDPROC,edit_proc);
		old_edit_proc=SetWindowLong(GetDlgItem(hwnd,IDC_COLS),GWL_WNDPROC,edit_proc);
		SetFocus(GetDlgItem(hwnd,IDC_IMAGE));
		hgrip=create_grippy(hwnd);
		init_main_win_anchor(hwnd);
		break;
	case WM_SIZE:
		{
			grippy_move(hwnd,hgrip);
			resize_main_win(hwnd);
		}
		break;
	case WM_APP:
		{
			if(0==wparam)
				SetFocus(GetDlgItem(hwnd,IDC_IMAGE));
		}
		break;
	case WM_COMMAND:
		{
			int idc=LOWORD(wparam);
			if(IDCANCEL==idc){
				DestroyWindow(hwnd);
				PostQuitMessage(0);
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

	ctrls.dwSize=sizeof(ctrls);
	ctrls.dwICC=ICC_LISTVIEW_CLASSES|ICC_TREEVIEW_CLASSES|ICC_BAR_CLASSES|ICC_TAB_CLASSES|ICC_PROGRESS_CLASS|ICC_HOTKEY_CLASS;
	InitCommonControlsEx(&ctrls);

	hmaindlg=CreateDialog(hinstance,MAKEINTRESOURCE(IDD_MAINDLG),NULL,main_dlg_proc);
	if(!hmaindlg){
		MessageBox(NULL,"Unable to create window","ERROR",MB_OK|MB_SYSTEMMODAL);
		return 0;
	}
	ShowWindow(hmaindlg,SW_SHOW);
	debug_console(hmaindlg);

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
