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
	{IDC_FILTER,ANCHOR_LEFT|ANCHOR_BOTTOM},
	{IDCANCEL,ANCHOR_RIGHT|ANCHOR_BOTTOM},
	{IDC_KEYLIST,ANCHOR_RIGHT|ANCHOR_LEFT|ANCHOR_BOTTOM|ANCHOR_TOP},
	{IDC_GRIPPY,ANCHOR_RIGHT|ANCHOR_BOTTOM},
];

WIN_REL_POS ascii_keymap_win_pos;
wstring[] ASCII_DLG_COLS=["val","char","key"];
enum{ASCII_COL_VAL=0,ASCII_COL_CHAR=1,ASCII_COL_KEY=2};

WIN_REL_POS func_keymap_win_pos;
wstring[] FUNC_DLG_COLS=["ID","description","key"];
enum{FUNC_COL_VAL=0,FUNC_COL_DESC=1,FUNC_COL_KEY=2};

struct SHORTCUT{
	int action;
	int vkey;
	bool ctrl;
	bool shift;
	bool alt;
	WCHAR data;
}
struct SHORTCUT_DLG_PARAM{
	SHORTCUT sc;
	WCHAR *title;
	WCHAR *data;
	int is_edit;
}
enum{
	SC_ASCII=0,
	SC_UNDO,
	SC_REDO,
	SC_COPY,
	SC_PASTE,
	SC_PASTE_INTO_SELECTION,
	SC_SET_CURSOR,
	SC_MAKE_SELECTION,
	SC_OPEN_TEXT_DLG,
	SC_OPEN_CHAR_SC_DLG,
	SC_OPEN_FUNC_SC_DLG,
	SC_CHK_FG,
	SC_CHK_BG,
	SC_CHK_FILL,
	SC_SELECT_ALL,
	SC_GRID,
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
	SC_FG_INCREASE,
	SC_FG_DECREASE,
	SC_BG_INCREASE,
	SC_BG_DECREASE,
	SC_CHAR_INCREASE,
	SC_CHAR_DECREASE,
	SC_PAINT,
	SC_PAINT_LINE_TO,
	SC_PAINT_MOVE_UP,
	SC_PAINT_MOVE_DOWN,
	SC_PAINT_MOVE_LEFT,
	SC_PAINT_MOVE_RIGHT,
	SC_PAINT_MOVE_UPRIGHT,
	SC_PAINT_MOVE_UPLEFT,
	SC_PAINT_MOVE_DOWNLEFT,
	SC_PAINT_MOVE_DOWNRIGHT,
	SC_PAINT_QB_MODE,
	SC_QUIT,
	SC_NONE,
}
struct SC_INFO{
	const int val;
	const wstring desc;
}
SC_INFO[] sc_info=[
	{val:SC_QUIT,desc:"QUIT"},
	{val:SC_OPEN_TEXT_DLG,desc:"open text dialog"},
	{val:SC_OPEN_CHAR_SC_DLG,desc:"open ascii shortcut dialog"},
	{val:SC_OPEN_FUNC_SC_DLG,desc:"open function shortcut dialog"},
	{val:SC_UNDO,desc:"UNDO"},
	{val:SC_REDO,desc:"REDO"},
	{val:SC_COPY,desc:"COPY"},
	{val:SC_PASTE,desc:"PASTE"},
	{val:SC_PASTE_INTO_SELECTION,desc:"paste into selection"},
	{val:SC_CHK_FG,desc:"check foreground FG"},
	{val:SC_CHK_BG,desc:"check background BG"},
	{val:SC_CHK_FILL,desc:"check fill char"},
	{val:SC_SELECT_ALL,desc:"SELECT ALL"},
	{val:SC_GRID,desc:"GRID"},
	{val:SC_FILL,desc:"FILL"},
	{val:SC_FLIP,desc:"FLIP"},
	{val:SC_ROTATE,desc:"ROTATE"},
	{val:SC_RETURN,desc:"return key"},
	{val:SC_BACKSPACE,desc:"backspace"},
	{val:SC_DELETE,desc:"DELETE"},
	{val:SC_MOVE_HOME,desc:"move home"},
	{val:SC_MOVE_END,desc:"move end"},
	{val:SC_MOVE_UP,desc:"move up"},
	{val:SC_MOVE_DOWN,desc:"move down"},
	{val:SC_MOVE_LEFT,desc:"move left"},
	{val:SC_MOVE_RIGHT,desc:"move right"},
	{val:SC_PAINT,desc:"PAINT"},
	{val:SC_PAINT_MOVE_UP,desc:"paint move up"},
	{val:SC_PAINT_MOVE_DOWN,desc:"paint move down"},
	{val:SC_PAINT_MOVE_LEFT,desc:"paint move left"},
	{val:SC_PAINT_MOVE_RIGHT,desc:"paint move right"},
	{val:SC_PAINT_MOVE_UPRIGHT,desc:"paint move up+right"},
	{val:SC_PAINT_MOVE_UPLEFT,desc:"paint move up+left"},
	{val:SC_PAINT_MOVE_DOWNLEFT,desc:"paint move down+left"},
	{val:SC_PAINT_MOVE_DOWNRIGHT,desc:"paint move down+right"},
	{val:SC_PAINT_QB_MODE,desc:"QB quartblock mode"},
];

SHORTCUT[] sc_map=[
	{action:SC_QUIT,vkey:VK_ESCAPE},
	{action:SC_OPEN_TEXT_DLG,vkey:VK_INSERT},
	{action:SC_OPEN_CHAR_SC_DLG,vkey:VK_INSERT,ctrl:true},
	{action:SC_OPEN_FUNC_SC_DLG,vkey:VK_F9},
	{action:SC_UNDO,vkey:'Z',ctrl:true},
	{action:SC_REDO,vkey:'Y',ctrl:true},
	{action:SC_COPY,vkey:'C',ctrl:true},
	{action:SC_PASTE,vkey:'V',ctrl:true},
	{action:SC_PASTE_INTO_SELECTION,vkey:'V',ctrl:true,shift:true},
	{action:SC_CHK_FG,vkey:'1',ctrl:true},
	{action:SC_CHK_BG,vkey:'2',ctrl:true},
	{action:SC_CHK_FILL,vkey:'3',ctrl:true},
	{action:SC_SELECT_ALL,vkey:'A',ctrl:true},
	{action:SC_GRID,vkey:'G',ctrl:true},
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
	{action:SC_PAINT,vkey:' ',ctrl:true},
	{action:SC_PAINT_MOVE_UP,vkey:VK_UP,ctrl:true},
	{action:SC_PAINT_MOVE_DOWN,vkey:VK_DOWN,ctrl:true},
	{action:SC_PAINT_MOVE_LEFT,vkey:VK_LEFT,ctrl:true},
	{action:SC_PAINT_MOVE_RIGHT,vkey:VK_RIGHT,ctrl:true},
	{action:SC_PAINT_MOVE_UP,vkey:VK_NUMPAD8,ctrl:true},
	{action:SC_PAINT_MOVE_DOWN,vkey:VK_NUMPAD2,ctrl:true},
	{action:SC_PAINT_MOVE_LEFT,vkey:VK_NUMPAD4,ctrl:true},
	{action:SC_PAINT_MOVE_RIGHT,vkey:VK_NUMPAD6,ctrl:true},
	{action:SC_PAINT_MOVE_UPRIGHT,vkey:VK_NUMPAD9,ctrl:true},
	{action:SC_PAINT_MOVE_UPLEFT,vkey:VK_NUMPAD7,ctrl:true},
	{action:SC_PAINT_MOVE_DOWNLEFT,vkey:VK_NUMPAD1,ctrl:true},
	{action:SC_PAINT_MOVE_DOWNRIGHT,vkey:VK_NUMPAD3,ctrl:true},
	{action:SC_PAINT_QB_MODE,vkey:'Q',alt:true},
];
SHORTCUT[] sc_mouse_move_map=[
	{action:SC_PAINT_LINE_TO,vkey:VK_LBUTTON},
	{action:SC_MAKE_SELECTION,vkey:VK_RBUTTON},
];
SHORTCUT[] sc_mouse_click_map=[
	{action:SC_PAINT_LINE_TO,vkey:VK_LBUTTON,shift:true},
	{action:SC_SET_CURSOR,vkey:VK_LBUTTON,ctrl:true},
	{action:SC_PAINT,vkey:VK_LBUTTON},
	{action:SC_MAKE_SELECTION,vkey:VK_RBUTTON},
];
SHORTCUT[] sc_mouse_wheel_map=[
	{action:SC_FG_INCREASE,ctrl:true,data:1},
	{action:SC_FG_DECREASE,ctrl:true,data:0},
	{action:SC_BG_INCREASE,shift:true,data:1},
	{action:SC_BG_DECREASE,shift:true,data:0},
	{action:SC_CHAR_INCREASE,ctrl:true,shift:true,data:1},
	{action:SC_CHAR_DECREASE,ctrl:true,shift:true,data:0},
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

void init_lview(HWND hparent,HWND hlview,wstring[] cols)
{
	try{
	int i;
	for(i=0;i<cols.length;i++){
		LV_COLUMN col;
		col.mask = LVCF_WIDTH|LVCF_TEXT;
		col.cx = 100;
		col.pszText = cast(WCHAR*)cols[i].ptr;
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
	if(str.length>0)
		str[$-1]=0;
}
void print_int(WCHAR[] str,uint val)
{
	int index=0;
	int last_nonzero=0;
	while(1){
		uint tmp;
		if(index>=str.length)
			break;
		tmp=val%10;
		if(tmp!=0)
			last_nonzero=index;
		str[index++]=cast(WCHAR)('0'+tmp);
		val=val/10;
		//4 294 967 295
		if(index>=10)
			break;
	}
	int i,limit;
	limit=(last_nonzero+1)/2;
	for(i=0;i<limit;i++){
		WCHAR a,b;
		a=str[i];
		b=str[last_nonzero-i];
		str[last_nonzero-i]=a;
		str[i]=b;
	}
	last_nonzero++;
	if(last_nonzero<str.length)
		str[last_nonzero]=0;
	if(str.length>0)
		str[$-1]=0;
}
const (WCHAR *)wstrstri(const WCHAR *str1,const WCHAR *str2)
{
	import core.stdc.ctype;
	WCHAR *result=null;
	int index1=0,index2=0;
	while(1){
		WCHAR a,b;
		a=str1[index1];
		b=str2[index2];
		if(0==b){
			if(index2>1)
				result=cast(WCHAR*)(str1+index1-index2);
			break;
		}
		index1++;
		if(0==a)
			break;
		a=cast(WCHAR)tolower(a);
		b=cast(WCHAR)tolower(b);
		if(a==b)
			index2++;
		else
			index2=0;

	}
	return result;
}
void fill_ascii_sc_list(HWND hlview,const WCHAR *filter)
{
	wstring get_key_text(int i){
		foreach(sc;sc_ascii){
			if(sc.data==i){
				wstring tmp=get_sc_key_text(sc);
				tmp~='\0';
				return tmp;
			}
		}
		return "\0";
	}
	try{
	ListView_DeleteAllItems(hlview);
	int i,index=0;
	for(i=0x2580;i<=0x259F;i++){
		WCHAR[8] hex_str;
		WCHAR[2] char_str;
		wstring sc_text;
		LV_ITEM lvitem;
		print_hex(hex_str,i);
		char_str[0]=cast(WCHAR)i;
		char_str[1]=0;
		sc_text=get_key_text(i);
		if(filter[0]!=0){
			if(wstrstri(cast(const WCHAR*)char_str,filter))
				continue;
			if(wstrstri(cast(const WCHAR*)hex_str,filter))
				continue;
			if(wstrstri(sc_text.ptr,filter))
				continue;
		}
		

		lvitem.mask = LVIF_TEXT;
		lvitem.pszText = hex_str.ptr;
		lvitem.iItem = index;
		lvitem.iSubItem = 0;
		lvitem.lParam = 0;
		ListView_InsertItem(hlview,&lvitem);
		ListView_SetItemText(hlview,index,ASCII_COL_CHAR,char_str.ptr);
		foreach(sc;sc_ascii){
			if(sc.data==i){
				wstring tmp=get_sc_key_text(sc);
				tmp~='\0';
				ListView_SetItemText(hlview,index,ASCII_COL_KEY,cast(wchar*)tmp.ptr);
				break;
			}
		}
		if(filter[0]!=0){
			//if(wstrstri(str,filter))
		}else{
			index++;
		}

	}
	}catch(Exception s){
	}
	update_col_width(hlview,ASCII_COL_KEY);
}

void fill_func_sc_list(HWND hlview)
{
	try{
		ListView_DeleteAllItems(hlview);
		int i,index=0;
		foreach(sc;sc_map){
			WCHAR[20] str;
			LV_ITEM lvitem;
			lvitem.mask = LVIF_TEXT;
			print_int(str,sc.action);
			lvitem.pszText = str.ptr;
			lvitem.iItem = index;
			lvitem.iSubItem = 0;
			lvitem.lParam = 0;
			ListView_InsertItem(hlview,&lvitem);
			foreach(info;sc_info){
				if(info.val==sc.action){
					ListView_SetItemText(hlview,index,FUNC_COL_DESC,cast(LPTSTR)info.desc.ptr);
					break;
				}
			}
			wstring tmp=get_sc_key_text(sc);
			tmp~='\0';
			ListView_SetItemText(hlview,index,FUNC_COL_KEY,cast(wchar*)tmp.ptr);

			index++;

		}
	}catch(Exception s){
	}
	update_col_width(hlview,FUNC_COL_KEY);
	update_col_width(hlview,FUNC_COL_DESC);
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
void set_item_text(HWND hlview,const WCHAR *str,int item,int subitem)
{
	try{
		ListView_SetItemText(hlview,item,subitem,cast(wchar*)str);
	}catch(Exception e){
	}
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
void update_ascii_map(const SHORTCUT sc)
{
	int found=false;
	foreach(ref tmp;sc_ascii){
		if(tmp.data==sc.data){
			found=true;
			tmp=sc;
			break;
		}
	}
	if(!found){
		sc_ascii.length++;
		sc_ascii[$-1]=sc;
	}
}
void update_func_map(const SHORTCUT sc)
{
	int found=false;
	foreach(ref tmp;sc_map){
		if(tmp.action==sc.action){
			found=true;
			tmp=sc;
			break;
		}
	}
	if(!found){
		sc_map.length++;
		sc_map[$-1]=sc;
	}
}
void show_key_dlg(HWND hwnd,HWND hlview,bool is_edit,int col_title,int col_key,int col_data,
				  void function(const SHORTCUT)nothrow update_sc)
{
	WCHAR[80] title;
	WCHAR[20] data;
	SHORTCUT_DLG_PARAM scd;
	int index;
	index=get_focused_item(hlview);
	if(index<0)
		return;
	get_item_text(hlview,title,index,col_title);
	get_item_text(hlview,data,index,col_data);
	get_shortcut_info(hlview,index,col_key,&scd.sc);
	scd.title=title.ptr;
	scd.data=data.ptr;
	scd.is_edit=is_edit;

	int r=DialogBoxParam(sc_param.hinstance,MAKEINTRESOURCE(IDD_SHORTCUT),hwnd,&dlg_enter_key,cast(LPARAM)&scd);
	if(r){
		if(update_sc)
			update_sc(scd.sc);
		wstring str=get_sc_key_text(scd.sc);
		str~='\0';
		set_item_text(hlview,str.ptr,index,col_key);
		update_col_width(hlview,col_key);
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
					ListView_SetItemText(hlview,i,ASCII_COL_KEY,cast(wchar*)"");
				}
			}
		}
	}
	}catch(Exception e){
	}
}
extern (Windows)
BOOL dlg_ascii_keymap(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	static int last_selection=0;
	switch(msg){
	case WM_INITDIALOG:
		SC_DLG_PARAM *sc=cast(SC_DLG_PARAM*)lparam;
		if(sc is null)
			memset(&sc_param,0,sc_param.sizeof);
		else
			sc_param=*sc;
		HWND hlview=GetDlgItem(hwnd,IDC_KEYLIST);
		init_lview(hwnd,hlview,ASCII_DLG_COLS);
		HFONT hf=get_dejavu_font();
		if(hf)
			SendDlgItemMessage(hwnd,IDC_KEYLIST,WM_SETFONT,cast(WPARAM)hf,TRUE);
		fill_ascii_sc_list(hlview,"");
		init_grippy(hwnd,IDC_GRIPPY);
		anchor_init(hwnd,keyshort_anchor);
		restore_win_rel_position(sc_param.hparent,hwnd,ascii_keymap_win_pos);
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
				bool edit=false;
				if(key.wVKey==VK_F2)
					edit=true;
				show_key_dlg(hwnd,hlview,edit,ASCII_COL_CHAR,ASCII_COL_KEY,ASCII_COL_VAL,&update_ascii_map);
				break;
			case NM_DBLCLK:
				show_key_dlg(hwnd,hlview,true,ASCII_COL_CHAR,ASCII_COL_KEY,ASCII_COL_VAL,&update_ascii_map);
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
			save_win_rel_position(sc_param.hparent,hwnd,ascii_keymap_win_pos);
			EndDialog(hwnd,0);
			break;
		case IDC_EDIT:
			show_key_dlg(hwnd,GetDlgItem(hwnd,IDC_KEYLIST),true,ASCII_COL_CHAR,ASCII_COL_KEY,ASCII_COL_VAL,&update_ascii_map);
			break;
		case IDC_ADD:
			break;
		case IDC_FILTER:
			WCHAR[40] tmp;
			GetDlgItemText(hwnd,IDC_FILTER,tmp.ptr,tmp.length);
			fill_ascii_sc_list(GetDlgItem(hwnd,IDC_KEYLIST),tmp.ptr);
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

extern (Windows)
BOOL dlg_func_keymap(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	static int last_selection=0;
	switch(msg){
		case WM_INITDIALOG:
			SC_DLG_PARAM *sc=cast(SC_DLG_PARAM*)lparam;
			if(sc is null)
				memset(&sc_param,0,sc_param.sizeof);
			else
				sc_param=*sc;
			HWND hlview=GetDlgItem(hwnd,IDC_KEYLIST);
			init_lview(hwnd,hlview,FUNC_DLG_COLS);
			HFONT hf=get_dejavu_font();
			if(hf)
				SendDlgItemMessage(hwnd,IDC_KEYLIST,WM_SETFONT,cast(WPARAM)hf,TRUE);
			fill_func_sc_list(hlview);
			init_grippy(hwnd,IDC_GRIPPY);
			anchor_init(hwnd,keyshort_anchor);
			restore_win_rel_position(sc_param.hparent,hwnd,func_keymap_win_pos);
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
						bool edit=false;
						if(key.wVKey==VK_F2)
							edit=true;
						show_key_dlg(hwnd,hlview,edit,FUNC_COL_DESC,FUNC_COL_KEY,FUNC_COL_VAL,&update_func_map);
						break;
					case NM_DBLCLK:
						show_key_dlg(hwnd,hlview,true,FUNC_COL_DESC,FUNC_COL_KEY,FUNC_COL_VAL,&update_func_map);
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
					save_win_rel_position(sc_param.hparent,hwnd,func_keymap_win_pos);
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


int get_shortcut_info(HWND hlview,int item,int col_key,SHORTCUT *sc)
{
	int result=FALSE;
	WCHAR[40] tmp;
	tmp[0]=0;
	get_item_text(hlview,tmp,item,ASCII_COL_CHAR);
	sc.data=tmp[0];
	memset(tmp.ptr,0,tmp.sizeof);
	get_item_text(hlview,tmp,item,col_key);
	try{
	if(StrStrW(tmp.ptr,"ctrl"))
		sc.ctrl=1;
	if(StrStrW(tmp.ptr,"alt"))
		sc.alt=1;
	if(StrStrW(tmp.ptr,"shift"))
		sc.shift=1;
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
	sc.vkey=0;
	foreach(c;keylist){
		try
		if(StrStrW(keyname,c.name.ptr)){
			sc.vkey=c.val;
			break;
		}
		catch(Exception e){
		}
	}
	if(sc.vkey==0 && (keyname[0]!=0)){
		int get_hex_val(WCHAR a){
			if(a>='0' && a<='9')
				return a-'0';
			else
				return 10+a-'A';
		}
		if(keyname[0]=='0' && keyname[1]=='x'){
			sc.vkey=(get_hex_val(keyname[2])<<8)||get_hex_val(keyname[3]);
		}else{
			DWORD val=OemKeyScan(keyname[0]);
			sc.vkey=MapVirtualKey(val&0xFFFF,MAPVK_VSC_TO_VK);
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
					if(sc.vkey==0)
						sc.vkey=key;
					else{
						SendMessage(GetParent(hwnd),WM_COMMAND,MAKEWPARAM(IDOK,0),0);
						return 0;
					}
				}else{
					sc.vkey=key;
				}
			}
			print_key(sc,hwnd);
		}
		return 0;
		break;
	case WM_CHAR:
		return 0;
		break;
	case WM_APP:
		if(wparam==0){
			if(lparam!=0){
				SHORTCUT *ptr=cast(SHORTCUT*)lparam;
				WCHAR tmp=ptr.data;
				*ptr=sc;
				ptr.data=tmp;
			}
		}else if(wparam==1){
			memset(&sc,0,sc.sizeof);
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
	static SHORTCUT_DLG_PARAM *scp=NULL;

	switch(msg){
	case WM_INITDIALOG:
		{
			scp=cast(SHORTCUT_DLG_PARAM*)lparam;
			if(scp is null)
				EndDialog(hwnd,0);
			HWND hedit=GetDlgItem(hwnd,IDC_EDIT);
			if(hedit){
				old_edit_proc=cast(WNDPROC)SetWindowLongPtr(hedit,GWL_WNDPROC,cast(LONG_PTR)&_edit_proc2);
				HFONT hf=get_dejavu_font();
				if(hf)
					SendDlgItemMessage(hwnd,IDC_EDIT,WM_SETFONT,cast(WPARAM)hf,TRUE);
				if(scp.is_edit){
					wstring str=get_sc_key_text(scp.sc);
					str~='\0';
					SetWindowText(hedit,str.ptr);
					str="Edit shortcut for:"w~scp.sc.data~'\0';
					SetWindowText(hwnd,str.ptr);
				}
				WCHAR[20] tmp;
				print_hex(tmp,scp.sc.data);
				SetDlgItemText(hwnd,IDC_HEXVAL,tmp.ptr);
				SendMessage(hedit,WM_APP,1,0);
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
int process_ascii_map(ref SHORTCUT sc)
{
	int result=false;
	foreach(c;sc_ascii){
		if(compare_sc(c,sc)){
			result=true;
			sc.action=SC_ASCII;
			sc.data=c.data;
			break;
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
		result=process_ascii_map(sc);
		if(!result){
			int char_code=MapVirtualKey(sc.vkey,MAPVK_VK_TO_CHAR);
			if(char_code!=0){
				import core.stdc.ctype;
				int caps=GetKeyState(VK_CAPITAL)&1;
				if(sc.shift){
					int ret;
					WORD[4] trans;
					BYTE[256] key_state;
					GetKeyboardState(key_state.ptr);
					trans[0]=0;
					ret=ToAscii(sc.vkey,0,key_state.ptr,trans.ptr,0);
					if(ret>0){
						ret=trans[0];
						if(ret)
							char_code=ret;
					}
				}else{
					if(!caps)
						char_code=tolower(char_code);
				}
				sc.action=SC_ASCII;
				sc.data=cast(WCHAR)char_code;
				result=true;
			}
		}
	}
	return result;
}

int get_mouse_click_action(ref SHORTCUT sc)
{
	int result=false;
	foreach(c;sc_mouse_click_map){
		if(compare_sc(c,sc)){
			result=true;
			sc=c;
			break;
		}
	}
	return result;
}
int get_mouse_move_action(ref SHORTCUT sc)
{
	int result=false;
	foreach(c;sc_mouse_move_map){
		if(compare_sc(c,sc)){
			result=true;
			sc=c;
			break;
		}
	}
	return result;
}
int get_mouse_wheel_action(ref SHORTCUT sc)
{
	int result=false;
	foreach(c;sc_mouse_wheel_map){
		if(compare_sc(c,sc)){
			result=true;
			sc=c;
			break;
		}
	}
	return result;
}