module debug_print;

import core.sys.windows.windows;
import core.stdc.stdio;
import core.stdc.ctype;
nothrow:

struct NAME{
	int val;
	string name;
};
NAME[] wm_names=[
{WM_NULL,"WM_NULL"}, //0x0000
{WM_CREATE,"WM_CREATE"}, //0x0001
{WM_DESTROY,"WM_DESTROY"}, //0x0002
{WM_MOVE,"WM_MOVE"}, //0x0003
{WM_SIZE,"WM_SIZE"}, //0x0005
{WM_ACTIVATE,"WM_ACTIVATE"}, //0x0006
{WM_SETFOCUS,"WM_SETFOCUS"}, //0x0007
{WM_KILLFOCUS,"WM_KILLFOCUS"}, //0x0008
{WM_ENABLE,"WM_ENABLE"}, //0x000A
{WM_SETREDRAW,"WM_SETREDRAW"}, //0x000B
{WM_SETTEXT,"WM_SETTEXT"}, //0x000C
{WM_GETTEXT,"WM_GETTEXT"}, //0x000D
{WM_GETTEXTLENGTH,"WM_GETTEXTLENGTH"}, //0x000E
{WM_PAINT,"WM_PAINT"}, //0x000F
{WM_CLOSE,"WM_CLOSE"}, //0x0010
{WM_QUERYENDSESSION,"WM_QUERYENDSESSION"}, //0x0011
{WM_QUIT,"WM_QUIT"}, //0x0012
{WM_QUERYOPEN,"WM_QUERYOPEN"}, //0x0013
{WM_ERASEBKGND,"WM_ERASEBKGND"}, //0x0014
{WM_SYSCOLORCHANGE,"WM_SYSCOLORCHANGE"}, //0x0015
{WM_ENDSESSION,"WM_ENDSESSION"}, //0x0016
{WM_SHOWWINDOW,"WM_SHOWWINDOW"}, //0x0018
{WM_WININICHANGE,"WM_WININICHANGE"}, //0x001A
{WM_SETTINGCHANGE,"WM_SETTINGCHANGE"}, //WM_WININICHANGE
{WM_DEVMODECHANGE,"WM_DEVMODECHANGE"}, //0x001B
{WM_ACTIVATEAPP,"WM_ACTIVATEAPP"}, //0x001C
{WM_FONTCHANGE,"WM_FONTCHANGE"}, //0x001D
{WM_TIMECHANGE,"WM_TIMECHANGE"}, //0x001E
{WM_CANCELMODE,"WM_CANCELMODE"}, //0x001F
{WM_SETCURSOR,"WM_SETCURSOR"}, //0x0020
{WM_MOUSEACTIVATE,"WM_MOUSEACTIVATE"}, //0x0021
{WM_CHILDACTIVATE,"WM_CHILDACTIVATE"}, //0x0022
{WM_QUEUESYNC,"WM_QUEUESYNC"}, //0x0023
{WM_GETMINMAXINFO,"WM_GETMINMAXINFO"}, //0x0024
{WM_PAINTICON,"WM_PAINTICON"}, //0x0026
{WM_ICONERASEBKGND,"WM_ICONERASEBKGND"}, //0x0027
{WM_NEXTDLGCTL,"WM_NEXTDLGCTL"}, //0x0028
{WM_SPOOLERSTATUS,"WM_SPOOLERSTATUS"}, //0x002A
{WM_DRAWITEM,"WM_DRAWITEM"}, //0x002B
{WM_MEASUREITEM,"WM_MEASUREITEM"}, //0x002C
{WM_DELETEITEM,"WM_DELETEITEM"}, //0x002D
{WM_VKEYTOITEM,"WM_VKEYTOITEM"}, //0x002E
{WM_CHARTOITEM,"WM_CHARTOITEM"}, //0x002F
{WM_SETFONT,"WM_SETFONT"}, //0x0030
{WM_GETFONT,"WM_GETFONT"}, //0x0031
{WM_SETHOTKEY,"WM_SETHOTKEY"}, //0x0032
{WM_GETHOTKEY,"WM_GETHOTKEY"}, //0x0033
{WM_QUERYDRAGICON,"WM_QUERYDRAGICON"}, //0x0037
{WM_COMPAREITEM,"WM_COMPAREITEM"}, //0x0039
//{WM_GETOBJECT,"WM_GETOBJECT"}, //0x003D
{WM_COMPACTING,"WM_COMPACTING"}, //0x0041
{WM_COMMNOTIFY,"WM_COMMNOTIFY"}, //0x0044
{WM_WINDOWPOSCHANGING,"WM_WINDOWPOSCHANGING"}, //0x0046
{WM_WINDOWPOSCHANGED,"WM_WINDOWPOSCHANGED"}, //0x0047
{WM_POWER,"WM_POWER"}, //0x0048
{WM_COPYDATA,"WM_COPYDATA"}, //0x004A
{WM_CANCELJOURNAL,"WM_CANCELJOURNAL"}, //0x004B
{WM_NOTIFY,"WM_NOTIFY"}, //0x004E
{WM_INPUTLANGCHANGEREQUEST,"WM_INPUTLANGCHANGEREQUEST"}, //0x0050
{WM_INPUTLANGCHANGE,"WM_INPUTLANGCHANGE"}, //0x0051
{WM_TCARD,"WM_TCARD"}, //0x0052
{WM_HELP,"WM_HELP"}, //0x0053
{WM_USERCHANGED,"WM_USERCHANGED"}, //0x0054
{WM_NOTIFYFORMAT,"WM_NOTIFYFORMAT"}, //0x0055
{WM_CONTEXTMENU,"WM_CONTEXTMENU"}, //0x007B
{WM_STYLECHANGING,"WM_STYLECHANGING"}, //0x007C
{WM_STYLECHANGED,"WM_STYLECHANGED"}, //0x007D
{WM_DISPLAYCHANGE,"WM_DISPLAYCHANGE"}, //0x007E
{WM_GETICON,"WM_GETICON"}, //0x007F
{WM_SETICON,"WM_SETICON"}, //0x0080
{WM_NCCREATE,"WM_NCCREATE"}, //0x0081
{WM_NCDESTROY,"WM_NCDESTROY"}, //0x0082
{WM_NCCALCSIZE,"WM_NCCALCSIZE"}, //0x0083
{WM_NCHITTEST,"WM_NCHITTEST"}, //0x0084
{WM_NCPAINT,"WM_NCPAINT"}, //0x0085
{WM_NCACTIVATE,"WM_NCACTIVATE"}, //0x0086
{WM_GETDLGCODE,"WM_GETDLGCODE"}, //0x0087
{WM_SYNCPAINT,"WM_SYNCPAINT"}, //0x0088
{WM_NCMOUSEMOVE,"WM_NCMOUSEMOVE"}, //0x00A0
{WM_NCLBUTTONDOWN,"WM_NCLBUTTONDOWN"}, //0x00A1
{WM_NCLBUTTONUP,"WM_NCLBUTTONUP"}, //0x00A2
{WM_NCLBUTTONDBLCLK,"WM_NCLBUTTONDBLCLK"}, //0x00A3
{WM_NCRBUTTONDOWN,"WM_NCRBUTTONDOWN"}, //0x00A4
{WM_NCRBUTTONUP,"WM_NCRBUTTONUP"}, //0x00A5
{WM_NCRBUTTONDBLCLK,"WM_NCRBUTTONDBLCLK"}, //0x00A6
{WM_NCMBUTTONDOWN,"WM_NCMBUTTONDOWN"}, //0x00A7
{WM_NCMBUTTONUP,"WM_NCMBUTTONUP"}, //0x00A8
{WM_NCMBUTTONDBLCLK,"WM_NCMBUTTONDBLCLK"}, //0x00A9
//{WM_KEYFIRST,"WM_KEYFIRST"}, //0x0100
{WM_KEYDOWN,"WM_KEYDOWN"}, //0x0100
{WM_KEYUP,"WM_KEYUP"}, //0x0101
{WM_CHAR,"WM_CHAR"}, //0x0102
{WM_DEADCHAR,"WM_DEADCHAR"}, //0x0103
{WM_SYSKEYDOWN,"WM_SYSKEYDOWN"}, //0x0104
{WM_SYSKEYUP,"WM_SYSKEYUP"}, //0x0105
{WM_SYSCHAR,"WM_SYSCHAR"}, //0x0106
{WM_SYSDEADCHAR,"WM_SYSDEADCHAR"}, //0x0107
{WM_KEYLAST,"WM_KEYLAST"}, //0x0108
{WM_IME_STARTCOMPOSITION,"WM_IME_STARTCOMPOSITION"}, //0x010D
{WM_IME_ENDCOMPOSITION,"WM_IME_ENDCOMPOSITION"}, //0x010E
{WM_IME_COMPOSITION,"WM_IME_COMPOSITION"}, //0x010F
{WM_IME_KEYLAST,"WM_IME_KEYLAST"}, //0x010F
{WM_INITDIALOG,"WM_INITDIALOG"}, //0x0110
{WM_COMMAND,"WM_COMMAND"}, //0x0111
{WM_SYSCOMMAND,"WM_SYSCOMMAND"}, //0x0112
{WM_TIMER,"WM_TIMER"}, //0x0113
{WM_HSCROLL,"WM_HSCROLL"}, //0x0114
{WM_VSCROLL,"WM_VSCROLL"}, //0x0115
{WM_INITMENU,"WM_INITMENU"}, //0x0116
{WM_INITMENUPOPUP,"WM_INITMENUPOPUP"}, //0x0117
{WM_MENUSELECT,"WM_MENUSELECT"}, //0x011F
{WM_MENUCHAR,"WM_MENUCHAR"}, //0x0120
{WM_ENTERIDLE,"WM_ENTERIDLE"}, //0x0121
{WM_MENURBUTTONUP,"WM_MENURBUTTONUP"}, //0x0122
{WM_MENUDRAG,"WM_MENUDRAG"}, //0x0123
{WM_MENUGETOBJECT,"WM_MENUGETOBJECT"}, //0x0124
{WM_UNINITMENUPOPUP,"WM_UNINITMENUPOPUP"}, //0x0125
{WM_MENUCOMMAND,"WM_MENUCOMMAND"}, //0x0126
{WM_CTLCOLORMSGBOX,"WM_CTLCOLORMSGBOX"}, //0x0132
{WM_CTLCOLOREDIT,"WM_CTLCOLOREDIT"}, //0x0133
{WM_CTLCOLORLISTBOX,"WM_CTLCOLORLISTBOX"}, //0x0134
{WM_CTLCOLORBTN,"WM_CTLCOLORBTN"}, //0x0135
{WM_CTLCOLORDLG,"WM_CTLCOLORDLG"}, //0x0136
{WM_CTLCOLORSCROLLBAR,"WM_CTLCOLORSCROLLBAR"}, //0x0137
{WM_CTLCOLORSTATIC,"WM_CTLCOLORSTATIC"}, //0x0138
{WM_MOUSEFIRST,"WM_MOUSEFIRST"}, //0x0200
{WM_MOUSEMOVE,"WM_MOUSEMOVE"}, //0x0200
{WM_LBUTTONDOWN,"WM_LBUTTONDOWN"}, //0x0201
{WM_LBUTTONUP,"WM_LBUTTONUP"}, //0x0202
{WM_LBUTTONDBLCLK,"WM_LBUTTONDBLCLK"}, //0x0203
{WM_RBUTTONDOWN,"WM_RBUTTONDOWN"}, //0x0204
{WM_RBUTTONUP,"WM_RBUTTONUP"}, //0x0205
{WM_RBUTTONDBLCLK,"WM_RBUTTONDBLCLK"}, //0x0206
{WM_MBUTTONDOWN,"WM_MBUTTONDOWN"}, //0x0207
{WM_MBUTTONUP,"WM_MBUTTONUP"}, //0x0208
{WM_MBUTTONDBLCLK,"WM_MBUTTONDBLCLK"}, //0x0209
{WM_MOUSEWHEEL,"WM_MOUSEWHEEL"}, //0x020A
{WM_MOUSELAST,"WM_MOUSELAST"}, //0x020A
{WM_MOUSELAST,"WM_MOUSELAST"}, //0x0209
{WM_PARENTNOTIFY,"WM_PARENTNOTIFY"}, //0x0210
{WM_ENTERMENULOOP,"WM_ENTERMENULOOP"}, //0x0211
{WM_EXITMENULOOP,"WM_EXITMENULOOP"}, //0x0212
{WM_NEXTMENU,"WM_NEXTMENU"}, //0x0213
{WM_SIZING,"WM_SIZING"}, //0x0214
{WM_CAPTURECHANGED,"WM_CAPTURECHANGED"}, //0x0215
{WM_MOVING,"WM_MOVING"}, //0x0216
{WM_POWERBROADCAST,"WM_POWERBROADCAST"}, //0x0218
{WM_DEVICECHANGE,"WM_DEVICECHANGE"}, //0x0219
{WM_MDICREATE,"WM_MDICREATE"}, //0x0220
{WM_MDIDESTROY,"WM_MDIDESTROY"}, //0x0221
{WM_MDIACTIVATE,"WM_MDIACTIVATE"}, //0x0222
{WM_MDIRESTORE,"WM_MDIRESTORE"}, //0x0223
{WM_MDINEXT,"WM_MDINEXT"}, //0x0224
{WM_MDIMAXIMIZE,"WM_MDIMAXIMIZE"}, //0x0225
{WM_MDITILE,"WM_MDITILE"}, //0x0226
{WM_MDICASCADE,"WM_MDICASCADE"}, //0x0227
{WM_MDIICONARRANGE,"WM_MDIICONARRANGE"}, //0x0228
{WM_MDIGETACTIVE,"WM_MDIGETACTIVE"}, //0x0229
{WM_MDISETMENU,"WM_MDISETMENU"}, //0x0230
{WM_ENTERSIZEMOVE,"WM_ENTERSIZEMOVE"}, //0x0231
{WM_EXITSIZEMOVE,"WM_EXITSIZEMOVE"}, //0x0232
{WM_DROPFILES,"WM_DROPFILES"}, //0x0233
{WM_MDIREFRESHMENU,"WM_MDIREFRESHMENU"}, //0x0234
{WM_IME_SETCONTEXT,"WM_IME_SETCONTEXT"}, //0x0281
{WM_IME_NOTIFY,"WM_IME_NOTIFY"}, //0x0282
{WM_IME_CONTROL,"WM_IME_CONTROL"}, //0x0283
{WM_IME_COMPOSITIONFULL,"WM_IME_COMPOSITIONFULL"}, //0x0284
{WM_IME_SELECT,"WM_IME_SELECT"}, //0x0285
{WM_IME_CHAR,"WM_IME_CHAR"}, //0x0286
{WM_IME_REQUEST,"WM_IME_REQUEST"}, //0x0288
{WM_IME_KEYDOWN,"WM_IME_KEYDOWN"}, //0x0290
{WM_IME_KEYUP,"WM_IME_KEYUP"}, //0x0291
{WM_MOUSEHOVER,"WM_MOUSEHOVER"}, //0x02A1
{WM_MOUSELEAVE,"WM_MOUSELEAVE"}, //0x02A3
{WM_CUT,"WM_CUT"}, //0x0300
{WM_COPY,"WM_COPY"}, //0x0301
{WM_PASTE,"WM_PASTE"}, //0x0302
{WM_CLEAR,"WM_CLEAR"}, //0x0303
{WM_UNDO,"WM_UNDO"}, //0x0304
{WM_RENDERFORMAT,"WM_RENDERFORMAT"}, //0x0305
{WM_RENDERALLFORMATS,"WM_RENDERALLFORMATS"}, //0x0306
{WM_DESTROYCLIPBOARD,"WM_DESTROYCLIPBOARD"}, //0x0307
{WM_DRAWCLIPBOARD,"WM_DRAWCLIPBOARD"}, //0x0308
{WM_PAINTCLIPBOARD,"WM_PAINTCLIPBOARD"}, //0x0309
{WM_VSCROLLCLIPBOARD,"WM_VSCROLLCLIPBOARD"}, //0x030A
{WM_SIZECLIPBOARD,"WM_SIZECLIPBOARD"}, //0x030B
{WM_ASKCBFORMATNAME,"WM_ASKCBFORMATNAME"}, //0x030C
{WM_CHANGECBCHAIN,"WM_CHANGECBCHAIN"}, //0x030D
{WM_HSCROLLCLIPBOARD,"WM_HSCROLLCLIPBOARD"}, //0x030E
{WM_QUERYNEWPALETTE,"WM_QUERYNEWPALETTE"}, //0x030F
{WM_PALETTEISCHANGING,"WM_PALETTEISCHANGING"}, //0x0310
{WM_PALETTECHANGED,"WM_PALETTECHANGED"}, //0x0311
{WM_HOTKEY,"WM_HOTKEY"}, //0x0312
{WM_PRINT,"WM_PRINT"}, //0x0317
{WM_PRINTCLIENT,"WM_PRINTCLIENT"}, //0x0318
{WM_HANDHELDFIRST,"WM_HANDHELDFIRST"}, //0x0358
{WM_HANDHELDLAST,"WM_HANDHELDLAST"}, //0x035F
{WM_AFXFIRST,"WM_AFXFIRST"}, //0x0360
{WM_AFXLAST,"WM_AFXLAST"}, //0x037F
{WM_PENWINFIRST,"WM_PENWINFIRST"}, //0x0380
{WM_PENWINLAST,"WM_PENWINLAST"}, //0x038F
{WM_APP,"WM_APP"}, //0x8000
{WM_USER,"WM_USER"}, //0x0400
];


string[256] virtual_keys=[
"key0", //0
"LBUTTON", //1
"RBUTTON", //2
"CANCEL", //3
"MBUTTON", //4
"key5", //5
"key6", //6
"key7", //7
"BACK", //8
"TAB", //9
"key10", //10
"key11", //11
"CLEAR", //12
"RETURN", //13
"key14", //14
"key15", //15
"SHIFT", //16
"CONTROL", //17
"MENU", //18
"PAUSE", //19
"CAPITAL", //20
"HANGEUL", //21
"key22", //22
"JUNJA", //23
"FINAL", //24
"HANJA", //25
"key26", //26
"ESCAPE", //27
"CONVERT", //28
"NONCONVERT", //29
"ACCEPT", //30
"MODECHANGE", //31
"SPACE", //32
"PRIOR", //33
"NEXT", //34
"END", //35
"HOME", //36
"LEFT", //37
"UP", //38
"RIGHT", //39
"DOWN", //40
"SELECT", //41
"PRINT", //42
"EXECUTE", //43
"SNAPSHOT", //44
"INSERT", //45
"DELETE", //46
"HELP", //47
"0", //48
"1", //49
"2", //50
"3", //51
"4", //52
"5", //53
"6", //54
"7", //55
"8", //56
"9", //57
"key58", //58
"key59", //59
"key60", //60
"key61", //61
"key62", //62
"key63", //63
"key64", //64
"A", //65
"B", //66
"C", //67
"D", //68
"E", //69
"F", //70
"G", //71
"H", //72
"I", //73
"J", //74
"K", //75
"L", //76
"M", //77
"N", //78
"O", //79
"P", //80
"Q", //81
"R", //82
"S", //83
"T", //84
"U", //85
"V", //86
"W", //87
"X", //88
"Y", //89
"Z", //90
"LWIN", //91
"RWIN", //92
"APPS", //93
"key94", //94
"key95", //95
"NUMPAD0", //96
"NUMPAD1", //97
"NUMPAD2", //98
"NUMPAD3", //99
"NUMPAD4", //100
"NUMPAD5", //101
"NUMPAD6", //102
"NUMPAD7", //103
"NUMPAD8", //104
"NUMPAD9", //105
"MULTIPLY", //106
"ADD", //107
"SEPARATOR", //108
"SUBTRACT", //109
"DECIMAL", //110
"DIVIDE", //111
"F1", //112
"F2", //113
"F3", //114
"F4", //115
"F5", //116
"F6", //117
"F7", //118
"F8", //119
"F9", //120
"F10", //121
"F11", //122
"F12", //123
"F13", //124
"F14", //125
"F15", //126
"F16", //127
"F17", //128
"F18", //129
"F19", //130
"F20", //131
"F21", //132
"F22", //133
"F23", //134
"F24", //135
"key136", //136
"key137", //137
"key138", //138
"key139", //139
"key140", //140
"key141", //141
"key142", //142
"key143", //143
"NUMLOCK", //144
"SCROLL", //145
"key146", //146
"key147", //147
"key148", //148
"key149", //149
"key150", //150
"key151", //151
"key152", //152
"key153", //153
"key154", //154
"key155", //155
"key156", //156
"key157", //157
"key158", //158
"key159", //159
"LSHIFT", //160
"RSHIFT", //161
"LCONTROL", //162
"RCONTROL", //163
"LMENU", //164
"RMENU", //165
"key166", //166
"key167", //167
"key168", //168
"key169", //169
"key170", //170
"key171", //171
"key172", //172
"key173", //173
"key174", //174
"key175", //175
"key176", //176
"key177", //177
"key178", //178
"key179", //179
"key180", //180
"key181", //181
"key182", //182
"key183", //183
"key184", //184
"key185", //185
"key186", //186
"key187", //187
"key188", //188
"key189", //189
"key190", //190
"key191", //191
"key192", //192
"key193", //193
"key194", //194
"key195", //195
"key196", //196
"key197", //197
"key198", //198
"key199", //199
"key200", //200
"key201", //201
"key202", //202
"key203", //203
"key204", //204
"key205", //205
"key206", //206
"key207", //207
"key208", //208
"key209", //209
"key210", //210
"key211", //211
"key212", //212
"key213", //213
"key214", //214
"key215", //215
"key216", //216
"key217", //217
"key218", //218
"key219", //219
"key220", //220
"key221", //221
"key222", //222
"key223", //223
"key224", //224
"key225", //225
"key226", //226
"key227", //227
"key228", //228
"PROCESSKEY", //229
"key230", //230
"key231", //231
"key232", //232
"key233", //233
"key234", //234
"key235", //235
"key236", //236
"key237", //237
"key238", //238
"key239", //239
"key240", //240
"key241", //241
"key242", //242
"key243", //243
"key244", //244
"key245", //245
"ATTN", //246
"CRSEL", //247
"EXSEL", //248
"EREOF", //249
"PLAY", //250
"ZOOM", //251
"NONAME", //252
"PA1", //253
"OEM_CLEAR", //254
"key255", //255
];

void print_key(uint key)
{
	if(key>=virtual_keys.length)
		printf("key=%i\n",key);
	else
		printf("key=%s (%i) (%02X)\n",virtual_keys[key].ptr,key,key);
}

int get_key_str(uint key,char *str)
{
	if(key>=virtual_keys.length)
		sprintf(str,"key=%i",key);
	else
		sprintf(str,"%s",virtual_keys[key].ptr);
	return TRUE;
}
void print_msg(int msg,int wparam,int lparam,HANDLE hwnd)
{
	int i;
	static DWORD last;
	DWORD delta,tick;
	tick=GetTickCount();
	delta=tick-last;
	if(delta>700){
		printf("---\n");
	}
	last=tick;
	for(i=0;i<wm_names.length;i++){
		if(wm_names[i].val==msg){
			printf("%-20s wparam=%08X lparam=%08X %08X x=%3i y=%3i\n",wm_names[i].name.ptr,wparam,lparam,hwnd,LOWORD(lparam),HIWORD(lparam));
			return;
		}
	}
	printf("msg=%08X wparam=%08X lparam=%08X %08X x=%3i y=%3i\n",msg,wparam,lparam,hwnd,LOWORD(lparam),HIWORD(lparam));
}
char *strstri(char *src,char *sub)
{
	int index=0,sub_index=0;
	char a;
	char *start=null;
	while((a=src[index])!=0){
		char b;
		a=cast(char)tolower(a);
		b=sub[sub_index];
		if(0==sub_index)
			start=src+index;
		b=cast(char)tolower(b);
		if(0==b)
			return start;
		if(a==b){
			sub_index++;
		}else{
			sub_index=0;
		}
		index++;
	}
	if(sub_index>0){
		if(0==sub[sub_index])
			return start;
	}
	return null;
}
void show_tick()
{
	static DWORD tick=0;
	DWORD time;
	time=GetTickCount();
	if((time-tick)>250)
		printf("---\n");
	tick=time;
}
static format_msg(int error,const char *prefix)
{
	char[128] buffer;
	if (FormatMessageA(FORMAT_MESSAGE_IGNORE_INSERTS | FORMAT_MESSAGE_FROM_SYSTEM,
		NULL, error, 0, buffer.ptr, buffer.length, NULL))
		printf("%s(%i)=%s\n",prefix,error,buffer.ptr);
}
int print_lasterror()
{
	format_msg(cast(int)GetLastError(),"error");
	return 0;
}


extern (C) int _open_osfhandle(long,int);
void open_console()
{
	import std.stdio;
	static int consoleallocated=FALSE;
	static int consolecreated=FALSE;
	if(!consoleallocated){
		consoleallocated=AllocConsole();
	}
	if(!consolecreated){
		int hcrt;
		hcrt=_open_osfhandle(cast(long)GetStdHandle(STD_OUTPUT_HANDLE),_O_TEXT);
		if(hcrt!=0){
			FILE *f=core.stdc.stdio.stdout;
			f._file=hcrt;
			f._flag=_IOWRT|_IONBF;
			fflush(f);
			consolecreated=TRUE;
		}
	}
	HWND hwnd=GetConsoleWindow();
	if(hwnd!=NULL)
		SetForegroundWindow(hwnd);
}

void hide_console()
{
	int result=FALSE;
	if(GetConsoleWindow){
		HANDLE hcon;
		hcon=GetConsoleWindow();
		if(hcon){
			result=ShowWindow(hcon,SW_HIDE);
		}
	}
}
int move_console(int x,int y)
{
	int result=FALSE;
	if(GetConsoleWindow){
		HANDLE hcon;
		hcon=GetConsoleWindow();
		if(hcon){
			result=SetWindowPos(hcon,null,x,y,0,0,SWP_NOZORDER|SWP_NOSIZE);
		}
	}
	return result;
}
int resize_console(int w,int h,int lines)
{
	int result=FALSE;
	HANDLE hstdout;
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	hstdout=GetStdHandle(STD_OUTPUT_HANDLE);
	if(null==hstdout)
		return result;
	if(GetConsoleScreenBufferInfo(hstdout,&csbi)){
		COORD pt;
		SMALL_RECT rect;
		int cw,ch;
		if(lines<h)
			lines=h;
		cw=csbi.srWindow.Right-csbi.srWindow.Left+1;
		ch=csbi.srWindow.Bottom-csbi.srWindow.Top+1;
		if(w<=cw || h<ch){
			rect.Left=0;
			rect.Right=cast(short)(w-1);
			rect.Top=0;
			rect.Bottom=cast(short)(h-1);
			SetConsoleWindowInfo(hstdout,TRUE,&rect);
		}
		pt.X=cast(short)w;
		pt.Y=cast(short)lines;
		SetConsoleScreenBufferSize(hstdout,pt);
		rect.Left=0;
		rect.Top=0;
		rect.Right=cast(short)(w-1);
		rect.Bottom=cast(short)(h-1);
		SetConsoleWindowInfo(hstdout,TRUE,&rect);
	}
	return result;
}
