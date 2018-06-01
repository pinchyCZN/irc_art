module anchor_system;

import core.sys.windows.windows;
import resource;

nothrow:

enum ANCHOR_LEFT=1;
enum ANCHOR_RIGHT=2;
enum ANCHOR_TOP=4;
enum ANCHOR_BOTTOM=8;
enum ANCHOR_HCENTER=16;

struct CONTROL_ANCHOR{
	int ctrl_id;
	int anchor_mask;
	RECT rect_ctrl,rect_parent;
	int initialized;
};

struct WIN_REL_POS{
	WINDOWPLACEMENT parent,win;
	int initialized;
};

int anchor_init(HWND hparent,ref CONTROL_ANCHOR[] clist)
{
	int i;
	RECT rparent={0};
	GetClientRect(hparent,&rparent);
	for(i=0;i<clist.length;i++){
		HWND hctrl;
		CONTROL_ANCHOR *ca;
		ca=&clist[i];
		ca.rect_parent=rparent;
		hctrl=GetDlgItem(hparent,ca.ctrl_id);
		if(hctrl){
			RECT rctrl={0};
			GetWindowRect(hctrl,&rctrl);
			MapWindowPoints(NULL,hparent,cast(LPPOINT)&rctrl,2);
			ca.rect_ctrl=rctrl;
		}
		ca.initialized=1;
	}
	return 0;
}


int anchor_resize(HWND hparent,ref CONTROL_ANCHOR[] clist)
{
	int i;
	RECT rparent={0};
	GetClientRect(hparent,&rparent);
	foreach(anchor;clist){
		HWND hctrl;
		if(!anchor.initialized)
			continue;
		hctrl=GetDlgItem(hparent,anchor.ctrl_id);
		if(hctrl){
			int x=0,y=0,cx=0,cy=0,delta;
			int flags=0;
			switch(anchor.anchor_mask){
				case ANCHOR_RIGHT|ANCHOR_TOP:
				case ANCHOR_RIGHT:
					{
						delta=anchor.rect_parent.right-anchor.rect_ctrl.left;
						x=rparent.right-delta;
						y=anchor.rect_ctrl.top-anchor.rect_parent.top;
						flags=SWP_NOSIZE;
					}
					break;
				case ANCHOR_LEFT|ANCHOR_BOTTOM:
				case ANCHOR_BOTTOM:
					{
						delta=anchor.rect_parent.bottom-anchor.rect_ctrl.top;
						x=anchor.rect_ctrl.left-anchor.rect_parent.left;
						y=rparent.bottom-delta;
						flags=SWP_NOSIZE;
					}
					break;
				case ANCHOR_LEFT|ANCHOR_RIGHT|ANCHOR_TOP|ANCHOR_BOTTOM:
					{
						x=anchor.rect_ctrl.left-anchor.rect_parent.left;
						y=anchor.rect_ctrl.top-anchor.rect_parent.top;
						delta=anchor.rect_parent.right -  anchor.rect_ctrl.right;
						cx=(rparent.right-rparent.left) - delta - x;
						delta=anchor.rect_parent.bottom -  anchor.rect_ctrl.bottom;
						cy=(rparent.bottom-rparent.top) - delta - y;
						flags=SWP_NOMOVE;
					}
					break;
				case ANCHOR_LEFT|ANCHOR_RIGHT|ANCHOR_TOP:
				case ANCHOR_LEFT|ANCHOR_RIGHT:
					{
						x=anchor.rect_ctrl.left-anchor.rect_parent.left;
						//y=anchor.rect_ctrl.top-anchor.rect_parent.top;
						delta=anchor.rect_parent.right -  anchor.rect_ctrl.right;
						cx=(rparent.right-rparent.left) - delta - x;
						cy=anchor.rect_ctrl.bottom-anchor.rect_ctrl.top;
						flags=SWP_NOMOVE;
					}
					break;
				case ANCHOR_LEFT|ANCHOR_RIGHT|ANCHOR_BOTTOM:
					{
						x=anchor.rect_ctrl.left-anchor.rect_parent.left;
						delta=anchor.rect_parent.bottom-anchor.rect_ctrl.top;
						y=rparent.bottom-delta;
						delta=anchor.rect_parent.right -  anchor.rect_ctrl.right;
						cx=(rparent.right-rparent.left) - delta - x;
						cy=anchor.rect_ctrl.bottom-anchor.rect_ctrl.top;
						flags=SWP_SHOWWINDOW;
					}
					break;
				case ANCHOR_RIGHT|ANCHOR_BOTTOM:
					{
						delta=anchor.rect_parent.right-anchor.rect_ctrl.left;
						x=rparent.right-delta;
						delta=anchor.rect_parent.bottom-anchor.rect_ctrl.top;
						y=rparent.bottom-delta;
						flags=SWP_NOSIZE;
					}
					break;
				case ANCHOR_LEFT|ANCHOR_TOP|ANCHOR_BOTTOM:
				case ANCHOR_TOP|ANCHOR_BOTTOM:
					{
						//x=anchor.rect_ctrl.left-anchor.rect_parent.left;
						y=anchor.rect_ctrl.top-anchor.rect_parent.top;
						cx=anchor.rect_ctrl.right-anchor.rect_ctrl.left;
						delta=anchor.rect_parent.bottom -  anchor.rect_ctrl.bottom;
						cy=(rparent.bottom-rparent.top) - delta - y;
						flags=SWP_NOMOVE;
					}
					break;
				case ANCHOR_RIGHT|ANCHOR_TOP|ANCHOR_BOTTOM:
					{
						delta=anchor.rect_parent.right-anchor.rect_ctrl.left;
						x=rparent.right-delta;
						y=anchor.rect_ctrl.top-anchor.rect_parent.top;
						cx=anchor.rect_ctrl.right-anchor.rect_ctrl.left;
						delta=anchor.rect_parent.bottom -  anchor.rect_ctrl.bottom;
						cy=(rparent.bottom-rparent.top) - delta - y;
						flags=SWP_SHOWWINDOW;
					}
					break;
				case ANCHOR_BOTTOM|ANCHOR_HCENTER:
					{
						delta=rparent.right-rparent.left;
						x=delta/2;
						delta=anchor.rect_ctrl.right-anchor.rect_ctrl.left;
						delta/=2;
						x-=delta;
						delta=anchor.rect_parent.bottom-anchor.rect_ctrl.top;
						y=rparent.bottom-delta;
						flags=SWP_NOSIZE;
					}
					break;
				default:
					break;
			}
			if(flags){
				flags&=~SWP_SHOWWINDOW;
				flags|=SWP_NOZORDER|SWP_NOREPOSITION;
				SetWindowPos(hctrl,NULL,x,y,cx,cy,flags);
			}
		}
	}
	return 0;
}