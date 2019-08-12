#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string.h>
#include <stdio.h>


int get_tick()
{
	return GetTickCount();
}

int copy_to_clip(const char *str)
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

int dump_to_console(const char *str)
{
	int result=FALSE;
	int i,len;
	len=strlen(str);
	for(i=0;i<len;i++){
		unsigned char a;
		a=str[i];
	}
	return result;
}

	/*
	typedef unsigned int UINT;
	typedef unsigned long DWORD;
	typedef const char * LPCCH;
	typedef unsigned short * LPWSTR;
	typedef const unsigned short * LPCWCH;
	typedef char * LPSTR;
	typedef int * LPBOOL;
#define MB_PRECOMPOSED            0x00000001
#define CP_UTF8                   65001
	int __stdcall MultiByteToWideChar(UINT,DWORD,LPCCH,int,LPWSTR,int);
	int __stdcall WideCharToMultiByte(UINT,DWORD,LPCWCH,int,LPSTR,int,LPCCH,LPBOOL);
	unsigned short tmp[10]={0};
	char out[10]={0};
	int res;
	res=MultiByteToWideChar(437,0,a,1,tmp,10);
	res=WideCharToMultiByte(CP_UTF8,0,tmp,res,out,sizeof(out),0,0);
	if(res>0){
		if(res>4)
			res=4;
		memcpy(u,out,res);
	}
	*/