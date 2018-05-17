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
		return DLGC_WANTARROWS;
		break;
	case WM_LBUTTONDOWN:
		{
			int x,y;
			x=LOWORD(lparam);
			y=HIWORD(lparam);
			mouse_click(x,y);
			InvalidateRect(GetDlgItem(hwnd,IDC_IMAGE),NULL,TRUE);
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
			default:
				if(!(ctrl || shift)){
					int x,y;
					x=get_col();
					y=get_row();
					set_char(vkey,x,y);
					set_fg(0xFFFF,x,y);
					set_fg(rand()&0xFFFF,x,y);
					move_cursor(1,0);
				}
				break;
			}
			InvalidateRect(hwnd,NULL,TRUE);
		}
		break;
	}
	CallWindowProc(old_image_proc,hwnd,msg,wparam,lparam);
}
BOOL CALLBACK main_dlg_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	if(msg!=WM_SETCURSOR && msg!=WM_MOUSEFIRST && msg!=WM_NCHITTEST)
		print_msg(msg,wparam,lparam,hwnd);
	switch(msg){
	case WM_INITDIALOG:
		create_vga_font();
		update_cells(get_rows(),get_cols());
		old_image_proc=SetWindowLong(GetDlgItem(hwnd,IDC_IMAGE),GWL_WNDPROC,image_proc);
		SetFocus(GetDlgItem(hwnd,IDC_IMAGE));
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
			if(di && IDC_IMAGE==di->CtlID){
				HWND htmp=di->hwndItem;
				HDC hdc=di->hDC;
				paint_window(htmp,hdc);
				return TRUE;
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
