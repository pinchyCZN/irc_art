module winmain;

import core.runtime;
import core.sys.windows.windows;
import core.sys.windows.commctrl;
import core.stdc.stdlib;
import core.stdc.stdio;
import core.stdc.string;
import resource;
import image;
import palette;
import fonts;
import anchor_system;
import file_image;
import text_printer;
import shortcut;
import debug_print;

HINSTANCE ghinstance=NULL;
HWND hmaindlg=NULL;
HWND himage=NULL;
enum{
	APP_SETFOCUS=0,
	APP_REFRESH=1
}
nothrow{

CONTROL_ANCHOR[] main_win_anchor=[
	{IDC_COLORS,ANCHOR_LEFT|ANCHOR_TOP},
	{IDC_IMAGE,ANCHOR_LEFT|ANCHOR_RIGHT|ANCHOR_TOP|ANCHOR_BOTTOM},
	{IDC_EXT_COLORS,ANCHOR_RIGHT|ANCHOR_TOP|ANCHOR_BOTTOM},
	{IDC_EXTC_SBAR,ANCHOR_RIGHT|ANCHOR_TOP|ANCHOR_BOTTOM},
	{IDC_STATUS,ANCHOR_RIGHT|ANCHOR_LEFT|ANCHOR_BOTTOM},
	{IDC_GRIPPY,ANCHOR_RIGHT|ANCHOR_BOTTOM},
];
int fg_color=0;
int bg_color=1;

int get_fg_color()
{
	if(IsDlgButtonChecked(hmaindlg,IDC_FG_CHK))
		return fg_color;
	else
		return -1;
}
int get_bg_color()
{
	if(IsDlgButtonChecked(hmaindlg,IDC_BG_CHK))
		return bg_color;
	else
		return -1;
}
int get_fill_char()
{
	if(IsDlgButtonChecked(hmaindlg,IDC_FILL_CHK)){
		WCHAR[4] tmp;
		GetDlgItemText(hmaindlg,IDC_CHAR,tmp.ptr,2);
		return tmp[0];
	}
	else
		return 0;
}

void select_drag(IMAGE *img,int cx,int cy)
{
	img.selection.right=cx;
	img.selection.bottom=cy;
	if(cx<img.selection.left){
		img.selection.right=img.selection.left;
		img.selection.left=cx;
	}
	if(cy<img.selection.top){
		img.selection.bottom=img.selection.top;
		img.selection.top=cy;
	}
}

int process_mouse(int flags,short x,short y)
{
	bool ctrl,shift,alt;
	ctrl=cast(bool)(flags&MK_CONTROL);
	shift=cast(bool)(flags&MK_SHIFT);
	alt=GetKeyState(VK_MENU)&0x8000;
	if(ctrl){
		if(flags&(MK_LBUTTON|MK_RBUTTON)){
			IMAGE *img=get_current_image();
			int ox,oy;
			ox=img.cursor.x;
			oy=img.cursor.y;
			if(image_click(img,x,y)){
				int fg,bg,fill;
				fg=get_fg_color();
				bg=get_bg_color();
				fill=get_fill_char();
				if(flags&MK_RBUTTON)
					fg=-1;
				draw_line(img,ox,oy,img.cursor.x,img.cursor.y,fg,bg,fill);
			}
		}
	}else if(shift){
	}else if(alt){
	}else{
		if(flags&MK_LBUTTON){
			IMAGE *img=get_current_image();
			if(img is null)
				return 0;
			int cx,cy;
			if(x<0)
				x=0;
			if(y<0)
				y=0;
			cx=x/img.cell_width;
			cy=y/img.cell_height;
			img.selection.left=img.cursor.x;
			img.selection.top=img.cursor.y;
			select_drag(img,cx,cy);
			img.is_modified=true;
		}

		//TEST SHIT
		if(0)
		{
			IMAGE *img=get_current_image();
			foreach(ref c;img.cells){
				c.bg=1;
				c.fg=1;
				c.val=0;
			}
			POINT a,b;
			POINT sa,sb;
			int ox,oy;
			ox=x/img.cell_width;
			oy=y/img.cell_height;

			a.x=20;
			a.y=12;
			b.x=ox;
			b.y=oy;
			sa.x=1;
			sa.y=1;
			sb.x=(x%img.cell_width)>=(img.cell_width/2)?1:0;
			sb.y=(y%img.cell_height)>=(img.cell_height/2)?1:0;
			int fg,bg;
			fg=0;
			bg=12;
			draw_line_qb(img,a,b,sa,sb,fg,bg,0);
			img.cursor.x=ox;
			img.cursor.y=oy;
			img.qbpos=sb;
		}
	}
	return 0;
}
int cursor_in_clip(IMAGE *img)
{
	int result=false;
	if(img is null)
		return result;
	if(img.cursor.x >= img.clip.x){
		if(img.cursor.y >= img.clip.y){
			if(img.cursor.x < (img.clip.x+img.clip.width))
				if(img.cursor.y < (img.clip.y+img.clip.height))
					result=true;
		}
	}
	return result;
}
int handle_clip_key(IMAGE *img,int vkey,int ctrl,int shift)
{
	int result=false;
	if(img is null)
		return result;
	if(img.clip.width<=0 || img.clip.height<=0)
		return result;
	if(!cursor_in_clip(img))
		return result;
	int move_clip(int x,int y){
		if(ctrl)
			return false;
		img.clip.x+=x;
		img.clip.y+=y;
		result=true;
		if(img.clip.x<0){
			img.clip.x=0;
			result=false;
		}
		if(img.clip.y<0){
			img.clip.y=0;
			result=false;
		}
		if(img.clip.x>=img.width){
			img.clip.x=img.width-1;
			result=false;
		}
		if(img.clip.y>=img.height){
			img.clip.y=img.height-1;
			result=false;
		}
		return result;
	}
	switch(vkey){
	case VK_DELETE:
		img.clip.cells.length=0;
		img.clip.width=0;
		img.clip.height=0;
		result=true;
		break;
	case VK_LEFT:
		if(move_clip(-1,0))
			img.move_cursor(-1,0);
		break;
	case VK_RIGHT:
		if(move_clip(1,0))
			img.move_cursor(1,0);
		break;
	case VK_UP:
		if(move_clip(0,-1))
			img.move_cursor(0,-1);
		break;
	case VK_DOWN:
		if(move_clip(0,1))
			img.move_cursor(0,1);
		break;
	case 'V':
	case VK_RETURN:
		{
			push_undo(img);
			int x,y;
			for(y=0;y<img.clip.height;y++){
				for(x=0;x<img.clip.width;x++){
					if(!img.clip.is_valid_pos(x,y))
						continue;
					int index=x+y*img.clip.width;
					CELL *cell=&img.clip.cells[index];
					int mx,my;
					mx=x+img.clip.x;
					my=y+img.clip.y;
					img.set_fg(cell.fg,mx,my);
					img.set_bg(cell.bg,mx,my);
					img.set_char(cell.val,mx,my);
				}
			}
			img.clip.cells.length=0;
			img.clip.width=0;
			img.clip.height=0;
			result=true;
		}
		break;
	default:
		break;
	}
	if(result)
	   img.is_modified=true;
	return result;	
}
int handle_selection_key(IMAGE *img,int vkey,int ctrl,int shift)
{
	int result=false;
	if(img is null)
		return result;
	switch(vkey){
	case VK_DELETE:
		{
			int w,h;
			w=img.selection_width();
			h=img.selection_height();
			if(w>0 && h>0){
				int i,j;
				for(i=0;i<h;i++){
					for(j=0;j<w;j++){
						int index;
						int x,y;
						index=j+i*w;
						if(index>=img.cells.length)
							break;
						x=img.selection.left+j;
						y=img.selection.top+i;
						img.set_char(' ',x,y);
						result=true;
					}
				}
			}
		}
		break;
	default:
		break;
	}
	if(result){
		img.is_modified=true;
	}
	return result;
}
int selection_to_clip(IMAGE *img)
{
	int result=false;
	if(img is null)
		return result;
	int w,h;
	w=img.selection_width();
	h=img.selection_height();
	if(w<=0 || h<=0)
		return result;
	img.clip.cells.length=w*h;
	img.clip.width=w;
	img.clip.height=h;
	img.clip.x=img.selection.left;
	img.clip.y=img.selection.top;
	int i,j;
	for(i=0;i<h;i++){
		for(j=0;j<w;j++){
			int src_index,dst_index;
			int x,y;
			x=img.selection.left+j;
			y=img.selection.top+i;
			src_index=x+y*img.width;
			if(src_index>=img.cells.length)
				continue;
			dst_index=j+i*w;
			if(dst_index>=img.clip.cells.length)
				continue;
			CELL *src,dst;
			src=&img.cells[src_index];
			dst=&img.clip.cells[dst_index];
			*dst=*src;
			result=true;
		}
	}
	if(result)
		img.is_modified=true;
	return result;
}
void toggle_check(HWND hwnd,int idc)
{
	int chk=IsDlgButtonChecked(hwnd,idc);
	int state=BST_CHECKED;
	if(chk)
		state=BST_UNCHECKED;
	CheckDlgButton(hwnd,idc,state);
}
int do_action(const SHORTCUT sc,IMAGE *img)
{
	int result=false;
	switch(sc.action){
	case SC_OPEN_CHAR_SC_DLG:
		{
			SC_DLG_PARAM scp;
			scp.hparent=hmaindlg;
			scp.hinstance=ghinstance;
			DialogBoxParam(ghinstance,MAKEINTRESOURCE(IDD_KEYS),hmaindlg,&dlg_keyshort,cast(LPARAM)&scp);
		}
		break;
	case SC_OPEN_TEXT_DLG:
		{
			TEXT_PARAMS tp;
			tp.hparent=hmaindlg;
			tp.img=img;
			tp.fg=&get_fg_color;
			tp.bg=&get_bg_color;
			tp.fill_char=&get_fill_char;
			if(tp.img is null)
				break;
			if(htextdlg is null)
				htextdlg=CreateDialogParam(ghinstance,MAKEINTRESOURCE(IDD_TEXT),hmaindlg,&dlg_text,cast(LPARAM)&tp);
			if(htextdlg !is null){
				if(ShowWindow(htextdlg,SW_SHOW))
					SetFocus(htextdlg);
			}
		}
		break;
	case SC_MOVE_HOME:
		{
			if(0==img.cursor.x){
				img.move_cursor(0,-img.cursor.y);
			}else{
				img.move_cursor(-img.cursor.x,0);
			}
			img.clip.x=img.cursor.x;
			img.clip.y=img.cursor.y;
		}
		break;
	case SC_MOVE_END:
		img.move_cursor(-img.cursor.x,0);
		img.move_cursor(img.width-1,0);
		break;
	case SC_MOVE_LEFT:
		img.move_cursor(-1,0);
		break;
	case SC_MOVE_RIGHT:
		img.move_cursor(1,0);
		break;
	case SC_MOVE_UP:
		img.move_cursor(0,-1);
		break;
	case SC_MOVE_DOWN:
		img.move_cursor(0,1);
		break;
	case SC_PAINT_BEGIN:
		{
			push_undo(img);
			int fg,bg,fill;
			fg=get_fg_color();
			bg=get_bg_color();
			fill=get_fill_char();
			if(fg>=0)
				img.set_fg(fg,img.cursor.x,img.cursor.y);
			if(bg>=0)
				img.set_bg(bg,img.cursor.x,img.cursor.y);
			if(fill!=0)
				img.set_char(fill,img.cursor.x,img.cursor.y);
			else if(img.qblock_mode)
				draw_qblock(img,fg,bg);
		}
		break;
	case SC_PAINT_QB_MODE:
		img.qblock_mode=!img.qblock_mode;
		img.is_modified=true;
		break;
	case SC_PAINT_LINE_TO:
		push_undo(img);
		int fg,bg,fill;
		fg=get_fg_color();
		bg=get_bg_color();
		fill=get_fill_char();
		if(img.qblock_mode && 0==fill){
			POINT a,b;
			POINT sa,sb;
			a=img.pre_click;
			b=img.cursor;
			sa=img.pre_qbpos;
			sb=img.qbpos;
			draw_line_qb(img,a,b,sa,sb,fg,bg,0);
		}else{
			draw_line(img,img.pre_click.x,img.pre_click.y,img.cursor.x,img.cursor.y,fg,bg,fill);
		}
		break;
	case SC_PAINT_MOVE:
		{
			push_undo_time(img);
			int fg,bg,fill;
			int ox,oy;
			POINT oqbpos;
			fg=get_fg_color();
			bg=get_bg_color();
			fill=get_fill_char();
			ox=img.cursor.x;
			oy=img.cursor.y;
			oqbpos=img.qbpos;
			switch(sc.vkey){
			case VK_LEFT: img.move_cursor(-1,0); break;
			case VK_RIGHT: img.move_cursor(1,0); break;
			case VK_UP: img.move_cursor(0,-1); break;
			case VK_DOWN: img.move_cursor(0,1); break;
			default: break;
			}
			if(img.qblock_mode){
				POINT a,b;
				POINT cqb=img.qbpos;
				a.x=ox;
				a.y=oy;
				b=img.cursor;
				draw_line_qb(img,a,b,oqbpos,cqb,fg,bg,fill);
			}
			else
				draw_line(img,ox,oy,img.cursor.x,img.cursor.y,fg,bg,fill);
		}
		break;
	case SC_QUIT:
		version(_DEBUG){
			PostQuitMessage(0);
		}else{
			img.clear_clip();
		}
		break;
	case SC_DELETE:
		{
			push_undo(img);
			int x,y;
			x=img.cursor.x;
			y=img.cursor.y;
			img.set_char(' ',x,y);
		}
		break;
	case SC_RETURN:
		img.move_cursor(0,1);
		img.clear_selection();
		break;
	case SC_CHK_FG:
		toggle_check(hmaindlg,IDC_FG_CHK);
		break;
	case SC_CHK_BG:
		toggle_check(hmaindlg,IDC_BG_CHK);
		break;
	case SC_CHK_FILL:
		toggle_check(hmaindlg,IDC_FILL_CHK);
		break;
	case SC_ASCII:
		{
			push_undo_time(img);
			int x,y;
			int key_char=sc.data;
			x=img.cursor.x;
			y=img.cursor.y;
			img.set_char(key_char,x,y);
			img.set_fg(fg_color,x,y);
			img.move_cursor(1,0);
			img.clear_selection();
		}
		break;
	case SC_BACKSPACE:
		{
			push_undo_time(img);
			int x,y;
			img.move_cursor(-1,0);
			x=img.cursor.x;
			y=img.cursor.y;
			img.set_char(' ',x,y);
			img.clear_selection();
		}
		break;
	case SC_UNDO:
		pop_undo(img);
		break;
	case SC_REDO:
		redo(img);
		break;
	case SC_COPY:
		if(img.selection_width()>0
		   && img.selection_height()>0){
			selection_to_clip(img);
			memset(&img.selection,0,img.selection.sizeof);
		   }else{
			string tmp;
			if(img.clip.width>0 && img.clip.height>0)
				tmp=img.get_clip_text();
			else
				tmp=img.get_text();
			if(tmp.length>0){
				tmp~='\0';
				copy_str_clipboard(tmp.ptr);
				print_str_len(hmaindlg,tmp.ptr);
			}
		   }
		break;
	case SC_PASTE:
		push_undo(img);
		import_clipboard(hmaindlg,*img,FALSE,get_fg_color(),get_bg_color());
		img.is_modified=false;
		PostMessage(hmaindlg,WM_APP,APP_REFRESH,0);
		break;
	case SC_SELECT_ALL:
		img.selection.left=0;
		img.selection.top=0;
		img.selection.bottom=img.height;
		img.selection.right=img.width;
		img.is_modified=true;
		break;
	case SC_FLIP:
		flip_clip(img);
		break;
	case SC_FILL:
		push_undo(img);
		do_fill(img,get_fg_color(),get_bg_color(),get_fill_char());
		break;
	case SC_ROTATE:
		break;
	case SC_PASTE_INTO_SELECTION:
		import_clipboard(hmaindlg,*img,TRUE,get_fg_color(),get_bg_color());
		img.is_modified=false;
		PostMessage(hmaindlg,WM_APP,APP_REFRESH,0);
		break;
	default:
		break;
	}
	return result;
}
int image_keydown(UINT msg,int vkey)
{
	int result=false;
	bool ctrl=GetKeyState(VK_CONTROL)&0x8000;
	bool shift=GetKeyState(VK_SHIFT)&0x8000;
	bool alt=false;
	IMAGE *img=get_current_image();
	if(img is null)
		return result;
	if(msg==WM_SYSKEYDOWN)
		alt=true;
	else if(msg==WM_LBUTTONDOWN)
		alt=GetKeyState(VK_MENU)&0x8000;
	if(handle_clip_key(img,vkey,ctrl,shift)){
		result=true;
		return result;
	}
	if(handle_selection_key(img,vkey,ctrl,shift)){
		result=true;
		return result;
	}
	SHORTCUT sc;
	sc.vkey=vkey;
	sc.ctrl=ctrl;
	sc.shift=shift;
	sc.alt=alt;
	if(!get_shortcut_action(sc))
		return result;
	result=do_action(sc,img);

	return result;
}

WNDPROC old_image_proc=NULL;
extern (Windows)
BOOL image_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	version(M_DEBUG) {
	if(msg!=WM_SETCURSOR && msg!=WM_MOUSEFIRST && msg!=WM_NCHITTEST && msg!=WM_PAINT){
		printf(">");
		print_msg(msg,wparam,lparam,hwnd);
	}
	}
	
	switch(msg){
		case WM_KILLFOCUS:
			set_focus_flag(hwnd,0);
			return 0;
		case WM_SETFOCUS:
			set_focus_flag(hwnd,1);
			return 0;
			break;
		case WM_GETDLGCODE:
			return DLGC_WANTARROWS|DLGC_WANTCHARS|DLGC_WANTMESSAGE|DLGC_WANTALLKEYS;
			break;
		case WM_LBUTTONDBLCLK:
		case WM_LBUTTONDOWN:
			{
				int x,y;
				int flag=wparam;
				x=LOWORD(lparam);
				y=HIWORD(lparam);
				IMAGE *img=get_current_image();
				if(img !is null){
					image_click(img,x,y);
					memset(&img.selection,0,img.selection.sizeof);
					if(!(flag&MK_CONTROL)){
						img.clip.x=img.cursor.x;
						img.clip.y=img.cursor.y;
					}
					image_keydown(msg,VK_LBUTTON);
				}
				SetFocus(hwnd);
				return 0;
			}
			break;
		case WM_MOUSEMOVE:
			{
				short x,y;
				int flags;
				x=LOWORD(lparam);
				y=HIWORD(lparam);
				flags=wparam;
				process_mouse(flags,x,y);
			}
			break;
		case WM_CHAR:
			break;
		case WM_SYSKEYDOWN:
		case WM_KEYDOWN:
			image_keydown(msg,wparam);
			break;
		default:
			break;
	}
	IMAGE *img=get_current_image();
	if(img !is null){
		if(img.is_modified){
			InvalidateRect(hwnd,NULL,FALSE);
			img.is_modified=false;
			update_status(hmaindlg);
		}
	}

	return CallWindowProc(old_image_proc,hwnd,msg,wparam,lparam);
}

WNDPROC old_palette_proc=NULL;
extern(Windows)
BOOL palette_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
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
				palette_click(x,y,msg,&fg_color,&bg_color);
				htmp=GetDlgItem(hmaindlg,IDC_FG);
				if(htmp)
					InvalidateRect(htmp,NULL,FALSE);
				htmp=GetDlgItem(hmaindlg,IDC_BG);
				if(htmp)
					InvalidateRect(htmp,NULL,FALSE);
				PostMessage(hmaindlg,WM_APP,APP_SETFOCUS,0);
			}
			break;
		default:
			break;
	}
	return CallWindowProc(old_palette_proc,hwnd,msg,wparam,lparam);
}
WNDPROC old_ext_palette_proc=NULL;
extern(Windows)
BOOL ext_palette_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
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
				ext_palette_click(x,y,msg,&fg_color,&bg_color);
				htmp=GetDlgItem(hmaindlg,IDC_FG);
				if(htmp)
					InvalidateRect(htmp,NULL,FALSE);
				htmp=GetDlgItem(hmaindlg,IDC_BG);
				if(htmp)
					InvalidateRect(htmp,NULL,FALSE);
				PostMessage(hmaindlg,WM_APP,APP_SETFOCUS,0);
			}
			break;
		default:
			break;
	}
	return CallWindowProc(old_palette_proc,hwnd,msg,wparam,lparam);
}

int get_wnd_int(HWND hwnd)
{
	char[10] str=0;
	GetWindowTextA(hwnd,str.ptr,str.length);
	return atoi(str.ptr);
}
int set_wind_int(HWND hwnd,int val)
{
	int result;
	char[10] str=0;
	_snprintf(str.ptr,str.length,"%i",val);
	result=SetWindowTextA(hwnd,str.ptr);
	SendMessage(hwnd,EM_SETSEL,0,-1);
	SendMessage(hwnd,EM_SETSEL,-1,-1);
	return result;
}

WNDPROC old_edit_proc=NULL;
extern(Windows)
BOOL edit_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	version(M_DEBUG){
		printf("==");
		print_msg(msg,wparam,lparam,hwnd);
	}
	switch(msg){
		case WM_GETDLGCODE:
			if(VK_RETURN==wparam)
				return DLGC_WANTALLKEYS;
			break;
		case WM_KEYDOWN:
			{
				int key=wparam;
				int dir=0;
				if(VK_UP==key)
					dir=1;
				else if(VK_DOWN==key)
					dir=-1;
				if(dir || VK_RETURN==key){
					int w,h;
					int id;
					int x=get_wnd_int(hwnd);
					x+=dir;
					if(x<1)
						x=1;
					else if(x>500)
						x=500;
					id=GetDlgCtrlID(hwnd);
					IMAGE *img=get_current_image();
					if(img is null)
						break;
					if(IDC_ROWS==id){
						w=img.width;
						h=x;
					}else{
						w=x;
						h=img.height;
					}
					img.resize_image(w,h);
					set_wind_int(hwnd,x);
					InvalidateRect(GetDlgItem(hmaindlg,IDC_IMAGE),NULL,TRUE);
				}
			}
			break;
		default:
			break;
	}
	return CallWindowProc(old_edit_proc,hwnd,msg,wparam,lparam);
}
void display_image_size(HWND hwnd)
{
	char[40] tmp=0;
	int w,h;
	IMAGE *img=get_current_image();
	if(img is null)
		return;
	w=img.width;
	h=img.height;
	_snprintf(tmp.ptr,tmp.length,"%i",w);
	SetDlgItemTextA(hwnd,IDC_COLS,tmp.ptr);
	_snprintf(tmp.ptr,tmp.length,"%i",h);
	SetDlgItemTextA(hwnd,IDC_ROWS,tmp.ptr);
}
void update_status(HWND hwnd)
{
	HWND hstatus=GetDlgItem(hwnd,IDC_STATUS);
	if(hstatus is null)
		return;
	IMAGE *img=get_current_image();
	if(img is null){
		SetWindowText(hwnd,"");
		return;
	}
	char[80] tmp=0;
	string QB_MODE="QB ";
	if(!img.qblock_mode)
		QB_MODE="";
	_snprintf(tmp.ptr,tmp.length,"%sCURSOR=%02i,%02i  FG=%02i BG=%02i",QB_MODE.ptr,img.cursor.x,img.cursor.y,
																	img.get_fg(img.cursor.x,img.cursor.y),
																	img.get_bg(img.cursor.x,img.cursor.y));
	if(img.clip.width>0 || img.clip.height>0){
		_snprintf(tmp.ptr,tmp.length,"%s | clip size=%i,%i",tmp.ptr,img.clip.width,img.clip.height);
	}
	if(img.selection_width()>0 || img.selection_height()>0){
		_snprintf(tmp.ptr,tmp.length,"%s | selection size=%i,%i",tmp.ptr,img.selection_width(),img.selection_height());
	}
	tmp[$-1]=0;
	SetWindowTextA(hstatus,tmp.ptr);
}
void do_shit(HWND hwnd)
{
	IMAGE *img=get_current_image();
	//img.resize_image(8,10);
	CheckDlgButton(hwnd,IDC_BG_CHK,BST_CHECKED);
	bg_color=12;
	img.qblock_mode=true;
	version(_DEBUG){
		img.cursor.x=28;
		img.cursor.y=11;
		{
		int i;
		for(i=0;i<30;i++){
			img.set_char(0x2580+i,i,0);
		}
		}
		return;
	}else{
		return;
	}
	{
	int i;
	for(i=0;i<3;i++){
		img.set_bg(9,2+i,1);
		img.set_bg(9,2+i,8);
	}
	for(i=0;i<6;i++){
		img.set_bg(9,1,2+i);
		img.set_bg(9,5,2+i);
	}
	}

}
extern(Windows)
BOOL main_dlg_proc(HWND hwnd,UINT msg,WPARAM wparam,LPARAM lparam)
{
	version(M_DEBUG){
	if(msg!=WM_SETCURSOR && msg!=WM_MOUSEFIRST && msg!=WM_NCHITTEST)
		print_msg(msg,wparam,lparam,hwnd);
	}
	switch(msg){
		case WM_INITDIALOG:
			anchor_init(hwnd,main_win_anchor);
			init_grippy(hwnd,IDC_GRIPPY);
			init_image();
			do_shit(hwnd);
			display_image_size(hwnd);
			update_status(hwnd);
			himage=GetDlgItem(hwnd,IDC_IMAGE);
			old_image_proc=cast(WNDPROC)SetWindowLongPtr(himage,GWL_WNDPROC,cast(LONG_PTR)&image_proc);
			old_palette_proc=cast(WNDPROC)SetWindowLongPtr(GetDlgItem(hwnd,IDC_COLORS),GWL_WNDPROC,cast(LONG_PTR)&palette_proc);
			old_edit_proc=cast(WNDPROC)SetWindowLongPtr(GetDlgItem(hwnd,IDC_ROWS),GWL_WNDPROC,cast(LONG_PTR)&edit_proc);
			old_edit_proc=cast(WNDPROC)SetWindowLongPtr(GetDlgItem(hwnd,IDC_COLS),GWL_WNDPROC,cast(LONG_PTR)&edit_proc);
			old_ext_palette_proc=cast(WNDPROC)SetWindowLongPtr(GetDlgItem(hwnd,IDC_EXT_COLORS),GWL_WNDPROC,cast(LONG_PTR)&ext_palette_proc);
			SetFocus(himage);
			SendDlgItemMessage(hwnd,IDC_ROWS,EM_LIMITTEXT,4,0);
			SendDlgItemMessage(hwnd,IDC_COLS,EM_LIMITTEXT,4,0);
			SendDlgItemMessage(hwnd,IDC_CHAR,EM_LIMITTEXT,1,0);
			HFONT hf=get_dejavu_font();
			if(hf)
				SendDlgItemMessage(hwnd,IDC_CHAR,WM_SETFONT,cast(WPARAM)hf,TRUE);
			break;
		case WM_MOVE:
			{
				if(IsWindowVisible(htextdlg)){
					PostMessage(htextdlg,WM_APP,1,0);
				}
			}
			break;
		case WM_SIZE:
			{
				anchor_resize(hwnd,main_win_anchor);
			}
			break;
		case WM_DROPFILES:
			{
				HDROP hdrop=cast(HANDLE)wparam;
				IMAGE *img=get_current_image();
				drop_file(hwnd,hdrop,img,get_fg_color(),get_bg_color());
			}
			break;
		case WM_APP:
			{
				switch(wparam){
					case APP_SETFOCUS:
						SetFocus(GetDlgItem(hwnd,IDC_IMAGE));
						break;
					case APP_REFRESH:
						InvalidateRect(GetDlgItem(hwnd,IDC_IMAGE),NULL,TRUE);
						display_image_size(hwnd);
						update_status(hwnd);
						break;
					default:
						break;
				}
			}
			break;
		case WM_COMMAND:
			{
				int idc=LOWORD(wparam);
				switch(idc){
					case IDM_SAVE:
						file_save(hwnd,get_current_image());
						break;
					case IDM_SAVEAS:
						file_saveas(hwnd,get_current_image());
						break;
					case IDM_FILEOPEN:
						{
							IMAGE *img=get_current_image();
							if(img !is null)
								file_open(hwnd,*img,get_fg_color(),get_bg_color());
						}
						break;
					case IDM_COPYTOCLIP:
						{
							IMAGE *img=get_current_image();
							if(img is null)
								break;
							string tmp=img.get_text();
							if(tmp.length>0){
								tmp~='\0';
								print_str_len(hwnd,tmp.ptr);
							}
						}
						break;
					case IDM_INSERT_TEXT:
						{
							SHORTCUT sc;
							sc.action=SC_OPEN_TEXT_DLG;
							do_action(sc,get_current_image());
						}
						break;
					case IDM_ASCIIMAP:
						{
							SHORTCUT sc;
							sc.action=SC_OPEN_CHAR_SC_DLG;
							do_action(sc,get_current_image());
						}
						break;
					case IDCANCEL:
						DestroyWindow(hwnd);
						PostQuitMessage(0);
						break;
					case IDC_MENU:
						{
							static HMENU hmenu=NULL;
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
					case IDC_FG:
					case IDC_BG:
						PostMessage(hwnd,WM_APP,APP_SETFOCUS,0);
						break;
					case IDC_FG_CHK:
					case IDC_BG_CHK:
					case IDC_FILL_CHK:
						PostMessage(hwnd,WM_APP,APP_SETFOCUS,0);
						break;
					default:
						break;
				}
			}
			break;
		case WM_DRAWITEM:
			{
				DRAWITEMSTRUCT *di=cast(LPDRAWITEMSTRUCT)lparam;
				if(!di)
					break;
				switch(di.CtlID){
					case IDC_IMAGE:
						{
							HWND htmp=di.hwndItem;
							HDC hdc=di.hDC;
							paint_image(htmp,hdc);
							return TRUE;
						}
						break;
					case IDC_COLORS:
						{
							HWND htmp=di.hwndItem;
							HDC hdc=di.hDC;
							paint_colors(htmp,hdc);
							return TRUE;
						}
						break;
					case IDC_FG:
					case IDC_BG:
						{
							HWND htmp=di.hwndItem;
							HDC hdc=di.hDC;
							paint_current_colors(htmp,hdc,di.CtlID,fg_color,bg_color);
						}
						break;
					case IDC_EXT_COLORS:
						{
							HWND htmp=di.hwndItem;
							HDC hdc=di.hDC;
							paint_ext_colors(htmp,hdc);
						}
						break;
					default:
						break;
				}
			}
			break;
		case WM_PAINT:
			{
				HDC hdc=GetDC(hwnd);
				if(hdc){
					RECT rect;
					GetWindowRect(GetDlgItem(hwnd,IDC_IMAGE),&rect);
					MapWindowPoints(HWND_DESKTOP,hwnd,cast(POINT*)&rect,2);
					paint_image_active(hdc,rect,image_focus_flag);
					ReleaseDC(hwnd,hdc);
					return 0;
				}
			}
			break;
		case WM_CLOSE:
			DestroyWindow(hwnd);
			PostQuitMessage(0);
			break;
		default:
			break;
	}
	return 0;
}

} //nothrow

int debug_console(HWND hwnd)
{
	RECT rect;
	open_console();
	GetWindowRect(hwnd,&rect);
	move_console(rect.right,0);
	return 0;
}

extern (Windows)
int WinMain(HINSTANCE hinstance,HINSTANCE hprevinstance,LPSTR cmd_line,int cmd_show)
{
	INITCOMMONCONTROLSEX ctrls;

	Runtime.initialize();
	ghinstance=hinstance;
	ctrls.dwSize=ctrls.sizeof;
	ctrls.dwICC=ICC_LISTVIEW_CLASSES|ICC_TREEVIEW_CLASSES|ICC_BAR_CLASSES|ICC_TAB_CLASSES|ICC_PROGRESS_CLASS|ICC_HOTKEY_CLASS;
	InitCommonControlsEx(&ctrls);

	hmaindlg=CreateDialog(hinstance,MAKEINTRESOURCE(IDD_MAINDLG),NULL,&main_dlg_proc);
	if(!hmaindlg){
		MessageBox(NULL,"Unable to create window","ERROR",MB_OK|MB_SYSTEMMODAL);
		return 0;
	}
	ShowWindow(hmaindlg,SW_SHOW);
	version(_DEBUG)
	{
		debug_console(hmaindlg);
	}
	while (1){
		int ret;
		MSG msg;
		ret=GetMessage(&msg,NULL,0,0);
		if(-1==ret || 0==ret){
			break;
		}else{
			version(M_DEBUG){
				if(msg.message!=WM_SETCURSOR && msg.message!=WM_MOUSEFIRST && msg.message!=WM_NCHITTEST)
					print_msg(msg.message,msg.wParam,msg.lParam,msg.hwnd);
			}
			if(!IsDialogMessage(hmaindlg,&msg)){
				if(msg.hwnd!=himage)
					TranslateMessage(&msg);
				DispatchMessage(&msg);
			}
		}
		//		else{
		//			print_msg(msg.message,msg.lParam,msg.wParam,msg.hwnd);
		//		}
	}

	return 0;
}
