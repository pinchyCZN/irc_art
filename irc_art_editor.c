#include <windows.h>
#include <commctrl.h>
#include "resource.h"

HINSTANCE ghinstance=0;
HWND hmaindlg=0;
int rows=10,cols=40;
int cwidth=8,cheight=12;

BOOL CALLBACK main_dlg_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	switch(msg){
	case WM_INITDIALOG:
		break;
	case WM_PAINT:
		{
			HDC hdc;
			PAINTSTRUCT ps;
			BITMAPINFO bmi;

			hdc=BeginPaint(hwnd,&ps);
			memset(&bmi,0,sizeof(BITMAPINFO));
			bmi.bmiHeader.biBitCount=24;
			bmi.bmiHeader.biWidth=cwidth*cols;
			bmi.bmiHeader.biHeight=cheight*rows;
			bmi.bmiHeader.biPlanes=1;
			bmi.bmiHeader.biSize=sizeof(bmi);
			/*
			SetDIBitsToDevice(hdc,0,Y_OFFSET,W,H,0,0,0,H,buffer,&bmi,DIB_RGB_COLORS);
			{
				RECT rect;
				int dw=0,dh=0;
				GetWindowRect(hwnd,&rect);
				StretchDIBits(hdc,0,Y_OFFSET,W+dw,H+dh,0,0,W,H,buffer,&bmi,DIB_RGB_COLORS,SRCCOPY);

			}
			*/
			EndPaint(hwnd,&ps);
		}
		break;
	}
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

	while (1){
		int ret;
		MSG msg;
		ret=GetMessage(&msg,NULL,0,0);
		if(-1==ret || 0==ret){
			break;
		}else{
		//if(!IsDialogMessage(hpedit,&msg)){
			//TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
//		else{
//			print_msg(msg.message,msg.lParam,msg.wParam,msg.hwnd);
//		}
	}

	return 0;
}
