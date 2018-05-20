#include <windows.h>
#include <stdio.h>

WCHAR gfname[MAX_PATH]={0};
int file_modified=FALSE;
extern HINSTANCE ghinstance;

int update_title(HWND hwnd)
{
	if(gfname[0]!=0){
		WCHAR tmp[256]={0};
		int count=sizeof(tmp)/sizeof(WCHAR);
		WCHAR *mod=L"*";
		if(!file_modified)
			mod=L"";
		_snwprintf(tmp,count,L"%s%s",mod,gfname);
		SetWindowTextW(hwnd,tmp);
	}
	return TRUE;
}
int init_ofn(OPENFILENAMEW *ofn,WCHAR *title,HWND hwnd)
{
	ofn->lStructSize=sizeof(OPENFILENAMEW);
	ofn->hInstance=ghinstance;
	ofn->hwndOwner=hwnd;
	ofn->lpstrFilter=L"TEXT FILES (*.TXT)\0*.TXT\0ALL FILES (*.*)\0*.*\0\0";
	ofn->lpstrTitle=title;
	ofn->Flags=OFN_ENABLESIZING;
	return TRUE;
}
int file_open(HWND hwnd)
{
	int result=FALSE;
	OPENFILENAMEW ofn={0};
	WCHAR tmp[MAX_PATH]={0};
	init_ofn(&ofn,L"Open",hwnd);
	ofn.lpstrFile=tmp;
	ofn.nMaxFile=sizeof(tmp)/sizeof(WCHAR);
	if(GetOpenFileNameW(&ofn)){
	}
	return result;
}
int write_image(WCHAR *fname)
{
	int result=FALSE;
	if(fname[0]!=0){
		char *buf=0;
		int buf_size=0;
		if(get_image_txt(&buf,&buf_size)){
			FILE *f;
			f=_wfopen(fname,L"wb");
			if(f){
				fwrite(buf,buf_size,1,f);
				result=TRUE;
				fclose(f);
			}
			if(buf){
				free(buf);
				buf=0;
			}
		}
	}
	return result;
}
int file_saveas(HWND hwnd)
{
	int result=FALSE;
	OPENFILENAMEW ofn={0};
	WCHAR tmp[MAX_PATH]={0};
	init_ofn(&ofn,L"Save",hwnd);
	ofn.lpstrFile=tmp;
	ofn.nMaxFile=sizeof(tmp)/sizeof(WCHAR);
	if(GetOpenFileNameW(&ofn)){
		int count=sizeof(gfname)/sizeof(WCHAR);
		wcsncpy(gfname,tmp,count);
		gfname[count-1]=0;
		write_image(gfname);
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
