module shortcut;

import core.sys.windows.windows;
import core.sys.windows.commctrl;
import core.stdc.stdlib;
import core.stdc.string;
import anchor_system;
import resource;

nothrow:

CONTROL_ANCHOR[] keyshort_anchor=[
	{IDOK,ANCHOR_LEFT|ANCHOR_BOTTOM},
	{IDCANCEL,ANCHOR_RIGHT|ANCHOR_BOTTOM},
	{IDC_KEYLIST,ANCHOR_RIGHT|ANCHOR_LEFT|ANCHOR_BOTTOM|ANCHOR_TOP},
	{IDC_GRIPPY,ANCHOR_RIGHT|ANCHOR_BOTTOM},
];

WIN_REL_POS keyshort_win_pos;


void init_lview(HWND hparent,HWND hlview)
{
	wstring[] cols=["char","key"];
	int i;
	for(i=0;i<cols.length;i++){
		LV_COLUMN col;
		col.mask = LVCF_WIDTH|LVCF_TEXT;
		col.cx = 100;
		col.pszText = cast(WCHAR*)cols[i].ptr;
		try{
			ListView_InsertColumn(hlview,i,&col);
		}
		catch(Exception e){
		}
	}
}
void fill_list(HWND hlview)
{
	try{
	ListView_DeleteAllItems(hlview);
	int i;
	for(i=0x2580;i<0x259F;i++){
		WCHAR[2] str;
		LV_ITEM lvitem;
		str[0]=cast(WCHAR)i;
		str[1]=0;
		lvitem.mask = LVIF_TEXT;
		lvitem.pszText = str.ptr;
		lvitem.iItem = i;
		lvitem.iSubItem = 0;
		lvitem.lParam = 0;
		ListView_InsertItem(hlview,&lvitem);
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
		init_lview(hwnd,GetDlgItem(hwnd,IDC_KEYLIST));
		fill_list(GetDlgItem(hwnd,IDC_KEYLIST));
		init_grippy(hwnd,IDC_GRIPPY);
		anchor_init(hwnd,keyshort_anchor);
		restore_win_rel_position(sc_param.hparent,hwnd,keyshort_win_pos);
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
			switch(nlv.hdr.code){
			case NM_DBLCLK:
				HWND hlview=nlv.hdr.hwndFrom;
				int item=get_focused_item(hlview);
				if(item<0)
					break;
				WCHAR[4] tmp;
				if(get_item_text(hlview,tmp,item,0)){
//					DialogBox(
				}
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

extern (Windows)
BOOL dlg_enter_key(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	switch(msg){
	case WM_INITDIALOG:
		break;
	default:
		break;
	}
	return FALSE;
}