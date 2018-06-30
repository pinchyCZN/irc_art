module shortcut;

import core.sys.windows.windows;
import core.sys.windows.shlwapi;
import core.sys.windows.commctrl;
import core.stdc.stdlib;
import core.stdc.string;
import core.stdc.stdio;
import anchor_system;
import resource;
import fonts;
import debug_print;

nothrow:

CONTROL_ANCHOR[] keyshort_anchor=[
	{IDC_ADD,ANCHOR_LEFT|ANCHOR_BOTTOM},
	{IDC_EDIT,ANCHOR_LEFT|ANCHOR_BOTTOM},
	{IDC_DELETE,ANCHOR_LEFT|ANCHOR_BOTTOM},
	{IDCANCEL,ANCHOR_RIGHT|ANCHOR_BOTTOM},
	{IDC_KEYLIST,ANCHOR_RIGHT|ANCHOR_LEFT|ANCHOR_BOTTOM|ANCHOR_TOP},
	{IDC_GRIPPY,ANCHOR_RIGHT|ANCHOR_BOTTOM},
];

WIN_REL_POS keyshort_win_pos;
wstring[] DLG_COLS=["val","char","key"];
enum{COL_VAL=0,COL_CHAR=1,COL_KEY=2};

struct SHORTCUT{
	int action;
	int vkey;
	int key_char;
	bool ctrl;
	bool shift;
	bool alt;
	WCHAR data;
}
struct SHORTCUT_PARAM{
	SHORTCUT sc;
	int edit;
}
enum{
	SC_ASCII=0,
	SC_COPY,
	SC_PASTE,
	SC_PASTE_INTO_SELECTION,
	SC_OPEN_TEXT_DLG,
	SC_OPEN_CHAR_SC_DLG,
	SC_OPEN_FUNC_SC_DLG,
	SC_CHK_FG,
	SC_CHK_BG,
	SC_CHK_FILL,
	SC_SELECT_ALL,
	SC_FILL,
	SC_FLIP,
	SC_ROTATE,
	SC_RETURN,
	SC_BACKSPACE,
	SC_DELETE,
	SC_MOVE_HOME,
	SC_MOVE_END,
	SC_MOVE_UP,
	SC_MOVE_DOWN,
	SC_MOVE_LEFT,
	SC_MOVE_RIGHT,
	SC_QUIT,
	SC_NONE,
}
SHORTCUT[] sc_map=[
	{action:SC_QUIT,vkey:VK_ESCAPE},
	{action:SC_OPEN_TEXT_DLG,vkey:VK_INSERT},
	{action:SC_OPEN_CHAR_SC_DLG,vkey:VK_INSERT,ctrl:true},
	{action:SC_OPEN_FUNC_SC_DLG,vkey:VK_F12},
	{action:SC_COPY,vkey:'C',ctrl:true},
	{action:SC_PASTE,vkey:'V',ctrl:true},
	{action:SC_PASTE_INTO_SELECTION,vkey:'V',ctrl:true,shift:true},
	{action:SC_CHK_FG,vkey:'1',ctrl:true},
	{action:SC_CHK_BG,vkey:'2',ctrl:true},
	{action:SC_CHK_FILL,vkey:'3',ctrl:true},
	{action:SC_SELECT_ALL,vkey:'A',ctrl:true},
	{action:SC_FILL,vkey:'F',ctrl:true},
	{action:SC_FLIP,vkey:'F',ctrl:true,shift:true},
	{action:SC_ROTATE,vkey:'R',ctrl:true},
	{action:SC_RETURN,vkey:VK_RETURN},
	{action:SC_BACKSPACE,vkey:VK_BACK},
	{action:SC_DELETE,vkey:VK_DELETE},
	{action:SC_MOVE_HOME,vkey:VK_HOME},
	{action:SC_MOVE_END,vkey:VK_END},
	{action:SC_MOVE_UP,vkey:VK_UP},
	{action:SC_MOVE_DOWN,vkey:VK_DOWN},
	{action:SC_MOVE_LEFT,vkey:VK_LEFT},
	{action:SC_MOVE_RIGHT,vkey:VK_RIGHT},
];
SHORTCUT[] sc_ascii;

struct KEYMAP{
	BYTE val;
	wstring name;
}
KEYMAP[] keylist=[
	{0x01,"VK_LBUTTON"},
	{0x02,"VK_RBUTTON"},
	{0x03,"VK_CANCEL"},
	{0x04,"VK_MBUTTON"},
	{0x05,"VK_XBUTTON1"},
	{0x06,"VK_XBUTTON2"},
	{0x08,"VK_BACK"},
	{0x09,"VK_TAB"},
	{0x0C,"VK_CLEAR"},
	{0x0D,"VK_RETURN"},
	{0x10,"VK_SHIFT"},
	{0x11,"VK_CONTROL"},
	{0x12,"VK_MENU"},
	{0x13,"VK_PAUSE"},
	{0x14,"VK_CAPITAL"},
	{0x15,"VK_KANA"},
	{0x15,"VK_HANGEUL"},
	{0x15,"VK_HANGUL"},
	{0x17,"VK_JUNJA"},
	{0x18,"VK_FINAL"},
	{0x19,"VK_HANJA"},
	{0x19,"VK_KANJI"},
	{0x1B,"VK_ESCAPE"},
	{0x1C,"VK_CONVERT"},
	{0x1D,"VK_NONCONVERT"},
	{0x1E,"VK_ACCEPT"},
	{0x1F,"VK_MODECHANGE"},
	{0x20,"VK_SPACE"},
	{0x21,"VK_PRIOR"},
	{0x22,"VK_NEXT"},
	{0x23,"VK_END"},
	{0x24,"VK_HOME"},
	{0x25,"VK_LEFT"},
	{0x26,"VK_UP"},
	{0x27,"VK_RIGHT"},
	{0x28,"VK_DOWN"},
	{0x29,"VK_SELECT"},
	{0x2A,"VK_PRINT"},
	{0x2B,"VK_EXECUTE"},
	{0x2C,"VK_SNAPSHOT"},
	{0x2D,"VK_INSERT"},
	{0x2E,"VK_DELETE"},
	{0x2F,"VK_HELP"},
	{0x5B,"VK_LWIN"},
	{0x5C,"VK_RWIN"},
	{0x5D,"VK_APPS"},
	{0x5F,"VK_SLEEP"},
	{0x60,"VK_NUMPAD0"},
	{0x61,"VK_NUMPAD1"},
	{0x62,"VK_NUMPAD2"},
	{0x63,"VK_NUMPAD3"},
	{0x64,"VK_NUMPAD4"},
	{0x65,"VK_NUMPAD5"},
	{0x66,"VK_NUMPAD6"},
	{0x67,"VK_NUMPAD7"},
	{0x68,"VK_NUMPAD8"},
	{0x69,"VK_NUMPAD9"},
	{0x6A,"VK_MULTIPLY"},
	{0x6B,"VK_ADD"},
	{0x6C,"VK_SEPARATOR"},
	{0x6D,"VK_SUBTRACT"},
	{0x6E,"VK_DECIMAL"},
	{0x6F,"VK_DIVIDE"},
	{0x70,"VK_F1"},
	{0x71,"VK_F2"},
	{0x72,"VK_F3"},
	{0x73,"VK_F4"},
	{0x74,"VK_F5"},
	{0x75,"VK_F6"},
	{0x76,"VK_F7"},
	{0x77,"VK_F8"},
	{0x78,"VK_F9"},
	{0x79,"VK_F10"},
	{0x7A,"VK_F11"},
	{0x7B,"VK_F12"},
	{0x7C,"VK_F13"},
	{0x7D,"VK_F14"},
	{0x7E,"VK_F15"},
	{0x7F,"VK_F16"},
	{0x80,"VK_F17"},
	{0x81,"VK_F18"},
	{0x82,"VK_F19"},
	{0x83,"VK_F20"},
	{0x84,"VK_F21"},
	{0x85,"VK_F22"},
	{0x86,"VK_F23"},
	{0x87,"VK_F24"},
	{0x90,"VK_NUMLOCK"},
	{0x91,"VK_SCROLL"},
	{0x92,"VK_OEM_NEC_EQUAL"},
	{0x92,"VK_OEM_FJ_JISHO"},
	{0x93,"VK_OEM_FJ_MASSHOU"},
	{0x94,"VK_OEM_FJ_TOUROKU"},
	{0x95,"VK_OEM_FJ_LOYA"},
	{0x96,"VK_OEM_FJ_ROYA"},
	{0xA0,"VK_LSHIFT"},
	{0xA1,"VK_RSHIFT"},
	{0xA2,"VK_LCONTROL"},
	{0xA3,"VK_RCONTROL"},
	{0xA4,"VK_LMENU"},
	{0xA5,"VK_RMENU"},
	{0xA6,"VK_BROWSER_BACK"},
	{0xA7,"VK_BROWSER_FORWARD"},
	{0xA8,"VK_BROWSER_REFRESH"},
	{0xA9,"VK_BROWSER_STOP"},
	{0xAA,"VK_BROWSER_SEARCH"},
	{0xAB,"VK_BROWSER_FAVORITES"},
	{0xAC,"VK_BROWSER_HOME"},
	{0xAD,"VK_VOLUME_MUTE"},
	{0xAE,"VK_VOLUME_DOWN"},
	{0xAF,"VK_VOLUME_UP"},
	{0xB0,"VK_MEDIA_NEXT_TRACK"},
	{0xB1,"VK_MEDIA_PREV_TRACK"},
	{0xB2,"VK_MEDIA_STOP"},
	{0xB3,"VK_MEDIA_PLAY_PAUSE"},
	{0xB4,"VK_LAUNCH_MAIL"},
	{0xB5,"VK_LAUNCH_MEDIA_SELECT"},
	{0xB6,"VK_LAUNCH_APP1"},
	{0xB7,"VK_LAUNCH_APP2"},
	{0xBA,"VK_OEM_1"},
	{0xBB,"VK_OEM_PLUS"},
	{0xBC,"VK_OEM_COMMA"},
	{0xBD,"VK_OEM_MINUS"},
	{0xBE,"VK_OEM_PERIOD"},
	{0xBF,"VK_OEM_2"},
	{0xC0,"VK_OEM_3"},
	{0xDB,"VK_OEM_4"},
	{0xDC,"VK_OEM_5"},
	{0xDD,"VK_OEM_6"},
	{0xDE,"VK_OEM_7"},
	{0xDF,"VK_OEM_8"},
	{0xE1,"VK_OEM_AX"},
	{0xE2,"VK_OEM_102"},
	{0xE3,"VK_ICO_HELP"},
	{0xE4,"VK_ICO_00"},
	{0xE5,"VK_PROCESSKEY"},
	{0xE6,"VK_ICO_CLEAR"},
	{0xE7,"VK_PACKET"},
	{0xE9,"VK_OEM_RESET"},
	{0xEA,"VK_OEM_JUMP"},
	{0xEB,"VK_OEM_PA1"},
	{0xEC,"VK_OEM_PA2"},
	{0xED,"VK_OEM_PA3"},
	{0xEE,"VK_OEM_WSCTRL"},
	{0xEF,"VK_OEM_CUSEL"},
	{0xF0,"VK_OEM_ATTN"},
	{0xF1,"VK_OEM_FINISH"},
	{0xF2,"VK_OEM_COPY"},
	{0xF3,"VK_OEM_AUTO"},
	{0xF4,"VK_OEM_ENLW"},
	{0xF5,"VK_OEM_BACKTAB"},
	{0xF6,"VK_ATTN"},
	{0xF7,"VK_CRSEL"},
	{0xF8,"VK_EXSEL"},
	{0xF9,"VK_EREOF"},
	{0xFA,"VK_PLAY"},
	{0xFB,"VK_ZOOM"},
	{0xFC,"VK_NONAME"},
	{0xFD,"VK_PA1"},
	{0xFE,"VK_OEM_CLEAR"},
];

void init_lview(HWND hparent,HWND hlview)
{
	try{
	int i;
	for(i=0;i<DLG_COLS.length;i++){
		LV_COLUMN col;
		col.mask = LVCF_WIDTH|LVCF_TEXT;
		col.cx = 100;
		col.pszText = cast(WCHAR*)DLG_COLS[i].ptr;
			ListView_InsertColumn(hlview,i,&col);
	}
	ListView_SetExtendedListViewStyle(hlview,LVS_EX_FULLROWSELECT);
	}
	catch(Exception e){
	}

}
void print_hex(WCHAR[] str,int val)
{
	if(str.length>2){
		str[0]='0';
		str[1]='x';
	}
	int index=2;
	int div=12;
	while(1){
		if(index>=str.length)
			break;
		ubyte x=(val>>div)&0xF;
		ubyte add='0';
		if(x>9)
			add='A'-10;
		x+=add;
		str[index++]=x;
		div-=4;
		if(div<0)
			break;
	}
	if(index<str.length)
		str[index++]=0;
	str[$-1]=0;
}
void fill_list(HWND hlview)
{
	try{
	ListView_DeleteAllItems(hlview);
	int i,index=0;
	for(i=0x2580;i<=0x259F;i++){
		WCHAR[20] str;
		LV_ITEM lvitem;
		lvitem.mask = LVIF_TEXT;
		lvitem.pszText = str.ptr;
		lvitem.iItem = index;
		lvitem.iSubItem = 0;
		lvitem.lParam = 0;
		print_hex(str,i);
		ListView_InsertItem(hlview,&lvitem);
		str[0]=cast(WCHAR)i;
		str[1]=0;
		ListView_SetItemText(hlview,index,1,str.ptr);
		index++;

	}
	}catch(Exception s){
	}
}
int get_focused_item(HWND hlistview)
{
	int i,count;
	try{
		count=ListView_GetItemCount(hlistview);
		for(i=0;i<count;i++){
			if(ListView_GetItemState(hlistview,i,LVIS_FOCUSED)==LVIS_FOCUSED)
				return i;
		}
	}catch(Exception e){
	}
	return -1;
}
int get_item_text(HWND hlview,WCHAR[] str,int item,int subitem)
{
	int result=FALSE;
	if(str.length>0)
		str[0]=0;
	try
	ListView_GetItemText(hlview,item,subitem,str.ptr,str.length);
	catch(Exception e){
	}
	if(str.length>0)
		str[$-1]=0;
	if(str[0]!=0)
		result=TRUE;
	return result;
}
struct SC_DLG_PARAM{
	HINSTANCE hinstance;
	HWND hparent;
}
SC_DLG_PARAM sc_param;
int get_string_width(HWND hwnd,wchar *str)
{
	if(hwnd && str){
		SIZE size={0};
		HDC hdc;
		hdc=GetDC(hwnd);
		if(hdc){
			import core.stdc.wchar_;
			HFONT hfont;
			int len=wcslen(str);
			hfont=cast(HFONT)SendMessage(hwnd,WM_GETFONT,0,0);
			if(hfont){
				HGDIOBJ hold;
				hold=cast(HGDIOBJ)SelectObject(hdc,hfont);
				GetTextExtentPoint32W(hdc,str,len,&size);
				if(hold)
					SelectObject(hdc,hold);
			}
			else{
				GetTextExtentPoint32W(hdc,str,len,&size);
			}
			ReleaseDC(hwnd,hdc);
			return size.cx;
		}
	}
	return 0;
}
void update_col_width(HWND hlview,int col)
{
	int i,max=100;
	try{
	int count=ListView_GetItemCount(hlview);
	for(i=0;i<count;i++){
		WCHAR[80] str;
		str[0]=0;
		get_item_text(hlview,str,i,col);
		if(str[0]!=0){
			int x;
			x=get_string_width(hlview,str.ptr);
			if(x>max)
				max=x;
		}
	}
	ListView_SetColumnWidth(hlview,col,max+15);
	}catch(Exception e){
	}
}
void show_key_dlg(HWND hwnd,HWND hlview,int edit)
{
	int item=get_focused_item(hlview);
	if(item<0 && edit)
		return;
	SHORTCUT_PARAM scp;
	scp.edit=edit;
	if(get_shortcut_info(hlview,item,&scp)){
		int r=DialogBoxParam(sc_param.hinstance,MAKEINTRESOURCE(IDD_SHORTCUT),hwnd,&dlg_enter_key,cast(LPARAM)&scp);
		if(r){
			wstring str=get_sc_key_text(scp.sc);
			str~='\0';
			try{
				ListView_SetItemText(hlview,item,COL_KEY,cast(wchar*)str.ptr);
				update_col_width(hlview,COL_KEY);
			}catch(Exception e){
			}
		}
	}
}
void delete_selection(HWND hlview)
{
	int i;
	int count,total;
	try{
	count=ListView_GetItemCount(hlview);
	total=0;
	for(i=0;i<count;i++){
		int state=ListView_GetItemState(hlview,i,LVIS_SELECTED);
		if(state==LVIS_SELECTED)
			total++;
	}
	if(total>0){
		int r=IDOK;
		if(total>1)
			r=MessageBox(hlview,"Ok to removed selected shortcuts?","Warning",MB_OKCANCEL);
		if(r==IDOK){
			for(i=0;i<count;i++){
				int state=ListView_GetItemState(hlview,i,LVIS_SELECTED);
				if(state==LVIS_SELECTED){
					ListView_SetItemText(hlview,i,COL_KEY,cast(wchar*)"");
				}
			}
		}
	}
	}catch(Exception e){
	}
}
extern (Windows)
BOOL dlg_keyshort(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	switch(msg){
	case WM_INITDIALOG:
		SC_DLG_PARAM *sc=cast(SC_DLG_PARAM*)lparam;
		if(sc is null)
			memset(&sc_param,0,sc_param.sizeof);
		else
			sc_param=*sc;
		HWND hlview=GetDlgItem(hwnd,IDC_KEYLIST);
		init_lview(hwnd,hlview);
		fill_list(hlview);
		init_grippy(hwnd,IDC_GRIPPY);
		anchor_init(hwnd,keyshort_anchor);
		restore_win_rel_position(sc_param.hparent,hwnd,keyshort_win_pos);
		HFONT hf=get_dejavu_font();
		if(hf)
			SendDlgItemMessage(hwnd,IDC_KEYLIST,WM_SETFONT,cast(WPARAM)hf,TRUE);
		SetFocus(hlview);
		break;
	case WM_SIZE:
		anchor_resize(hwnd,keyshort_anchor);
		break;
	case WM_NOTIFY:
		int idc=wparam;
		if(idc==IDC_KEYLIST){
			LPNMLISTVIEW nlv=cast(LPNMLISTVIEW)lparam;
			if(nlv is null)
				break;
			HWND hlview=nlv.hdr.hwndFrom;
			switch(nlv.hdr.code){
			case LVN_KEYDOWN:
				LV_KEYDOWN *key=cast(LV_KEYDOWN*)lparam;
				if(!(key.wVKey==VK_F2
					 || key.wVKey==VK_INSERT
					 || key.wVKey==VK_DELETE))
					break;
				if(key.wVKey==VK_DELETE){
					delete_selection(hlview);
					break;
				}
				int edit=false;
				if(key.wVKey==VK_F2)
					edit=true;
				show_key_dlg(hwnd,hlview,edit);
				break;
			case NM_DBLCLK:
				show_key_dlg(hwnd,hlview,true);
				break;
			default:
				break;
			}
		}
		break;
	case WM_COMMAND:
		int idc=LOWORD(wparam);
		switch(idc){
		case IDCANCEL:
		case IDOK:
			save_win_rel_position(sc_param.hparent,hwnd,keyshort_win_pos);
			EndDialog(hwnd,0);
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

int get_shortcut_info(HWND hlview,int item,SHORTCUT_PARAM *scp)
{
	int result=FALSE;
	WCHAR[40] tmp;
	tmp[0]=0;
	get_item_text(hlview,tmp,item,1);
	scp.sc.data=tmp[0];
	memset(tmp.ptr,0,tmp.sizeof);
	get_item_text(hlview,tmp,item,COL_KEY);
	try{
	if(StrStrW(tmp.ptr,"ctrl"))
		scp.sc.ctrl=1;
	if(StrStrW(tmp.ptr,"alt"))
		scp.sc.alt=1;
	if(StrStrW(tmp.ptr,"shift"))
		scp.sc.shift=1;
	}catch(Exception e){
	}
	int i,index=0;
	for(i=0;i<tmp.length;i++){
		WCHAR a=tmp[i];
		if(a=='+'){
			index=i+1;
			if(tmp[index]==0)
				index--;
		}
	}
	WCHAR *keyname=tmp.ptr+index;
	scp.sc.vkey=0;
	scp.sc.key_char=0;
	foreach(c;keylist){
		try
		if(StrStrW(keyname,c.name.ptr)){
			scp.sc.vkey=c.val;
			break;
		}
		catch(Exception e){
		}
	}
	if(scp.sc.vkey==0){
		int get_hex_val(WCHAR a){
			if(a>='0' && a<='9')
				return a-'0';
			else
				return 10+a-'A';
		}
		if(keyname[0]=='0' && keyname[1]=='x'){
			scp.sc.key_char=(get_hex_val(keyname[2])<<8)||get_hex_val(keyname[3]);
		}else{
			scp.sc.key_char=keyname[0];
		}
	}
	result=TRUE;
	return result;
}
wstring get_sc_key_text(SHORTCUT sc)
{
	wstring tmp;
	if(sc.ctrl)
		tmp~="ctrl+";
	if(sc.shift)
		tmp~="shift+";
	if(sc.alt)
		tmp~="alt+";
	if(sc.vkey){
		int found=false;
		foreach(c;keylist){
			if(c.val==sc.vkey){
				tmp~=c.name;
				found=true;
				break;
			}
		}
		if(!found)
			tmp~=sc.vkey;
	}else if(sc.key_char){
		int found=false;
		if(!(sc.key_char>=0x21 && sc.key_char<=0x7E)){
			foreach(c;keylist){
				if(c.val==sc.key_char){
					tmp~=c.name;
					found=true;
					break;
				}
			}
		}
		if(!found)
			tmp~=sc.key_char;
	}
	return tmp;
}
void print_key(SHORTCUT sc,HWND hwnd)
{
	wstring tmp=get_sc_key_text(sc);
	tmp~='\0';
	SetWindowTextW(hwnd,tmp.ptr);
}

private WNDPROC old_edit_proc=NULL;
private extern(C)
BOOL _edit_proc2(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	static SHORTCUT sc;
	version(M_DEBUG){
		if(!(msg==WM_NCHITTEST 
			 || msg==WM_MOUSEFIRST 
			 || msg==WM_SETCURSOR))
			print_msg(msg,wparam,lparam,hwnd);
	}
	switch(msg){
	case WM_CREATE:
		memset(&sc,0,sc.sizeof);
		break;
	case WM_GETDLGCODE:
		{
			int key=wparam;
			if(key==VK_TAB 
			   || key==VK_RETURN)
				return DLGC_WANTALLKEYS;
		}
		break;
	case WM_CONTEXTMENU:
		return 0;
		break;
	case WM_SYSKEYDOWN:
	case WM_KEYDOWN:
		{
			int key=wparam;
			if(key==VK_CONTROL)
				sc.ctrl=1;
			else if(key==VK_SHIFT)
				sc.shift=1;
			else if(key==VK_MENU)
				sc.alt=1;
			else{
				if(key==VK_DELETE || key==VK_BACK){
					if(sc.vkey==VK_DELETE || sc.vkey==VK_BACK){
						sc.ctrl=0;
						sc.shift=0;
						sc.alt=0;
						sc.vkey=0;
					}else{
						sc.vkey=key;
					}
				}else if(key==VK_RETURN){
					if(sc.vkey==0 && sc.key_char==0)
						sc.vkey=key;
					else{
						SendMessage(GetParent(hwnd),WM_COMMAND,MAKEWPARAM(IDOK,0),0);
						return 0;
					}
				}else{
					sc.vkey=key;
				}
			}
			sc.key_char=0;
			print_key(sc,hwnd);
		}
		return 0;
		break;
	case WM_CHAR:
		{
			int key=wparam;
			if(key==VK_ESCAPE
			   || key==' '
			   || key==VK_RETURN
			   || key==VK_BACK
			   || key==VK_TAB){
				print_key(sc,hwnd);
				return 0;
			}
			if(key>=0x21 && key<=0x7E){
				sc.vkey=0;
				sc.key_char=key;
			}
			print_key(sc,hwnd);
		}
		return 0;
		break;
	case WM_APP:
		if(wparam==0){
			if(lparam!=0){
				SHORTCUT *ptr=cast(SHORTCUT*)lparam;
				 *ptr=sc;
			}
		}
		break;
	default:
		break;
	}
	return CallWindowProc(old_edit_proc,hwnd,msg,wparam,lparam);
}

extern (Windows)
BOOL dlg_enter_key(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	static SHORTCUT_PARAM *scp=NULL;

	switch(msg){
	case WM_INITDIALOG:
		{
			scp=cast(SHORTCUT_PARAM*)lparam;
			if(scp is null)
				EndDialog(hwnd,0);
			HWND hedit=GetDlgItem(hwnd,IDC_EDIT);
			if(hedit){
				old_edit_proc=cast(WNDPROC)SetWindowLongPtr(hedit,GWL_WNDPROC,cast(LONG_PTR)&_edit_proc2);
				HFONT hf=get_dejavu_font();
				if(hf)
					SendDlgItemMessage(hwnd,IDC_EDIT,WM_SETFONT,cast(WPARAM)hf,TRUE);
				if(scp.edit){
					wstring str=get_sc_key_text(scp.sc);
					str~='\0';
					SetWindowText(hedit,str.ptr);
					str="Edit shortcut for:"w~scp.sc.data~'\0';
					SetWindowText(hwnd,str.ptr);
				}
				WCHAR[20] tmp;
				print_hex(tmp,scp.sc.data);
				SetDlgItemText(hwnd,IDC_HEXVAL,tmp.ptr);
			}
		}
		break;
	case WM_COMMAND:
		int idc=LOWORD(wparam);
		switch(idc){
			case IDCANCEL:
				EndDialog(hwnd,0);
				break;
			case IDOK:
				{
					SendDlgItemMessage(hwnd,IDC_EDIT,WM_APP,0,cast(LPARAM)&scp.sc);
					EndDialog(hwnd,1);
				}
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
int compare_sc(const SHORTCUT a,const SHORTCUT b)
{
	int result=false;
	if(a.vkey==b.vkey
	   && a.ctrl==b.ctrl
	   && a.shift==b.shift
	   && a.alt==b.alt)
		result=true;
	return result;
}
int process_ascii_map(int char_code,ref SHORTCUT sc)
{
	int result=false;
	foreach(c;sc_ascii){
		if(compare_sc(c,sc)){
			if(char_code==sc.key_char){
				result=true;
				sc.action=SC_ASCII;
				sc.data=c.data;
				break;
			}
		}
	}
	return result;
}
int get_shortcut_action(ref SHORTCUT sc)
{
	int result=false;
	foreach(c;sc_map){
		if(compare_sc(c,sc)){
			result=true;
			sc=c;
			break;
		}
	}
	if(!result){
		int char_code=MapVirtualKey(sc.vkey,MAPVK_VK_TO_CHAR);
		if(char_code!=0){
			result=process_ascii_map(char_code,sc);
			if(!result){
				import core.stdc.ctype;
				if(sc.shift){
					int caps=GetKeyState(VK_CAPITAL)&1;
					if(caps)
						char_code=tolower(char_code);
					else
						char_code=toupper(char_code);
				}else{
					char_code=tolower(char_code);
				}
				sc.action=SC_ASCII;
				sc.data=cast(WCHAR)char_code;
				result=true;
			}
			return result;
		}
	}
	return result;
}