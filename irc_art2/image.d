module image;

import core.sys.windows.windows;

struct CELL{
	WCHAR val;
	int fg;
	int bg;
};

struct IMAGE{
	CELL[] cells;
	int width;
	int height;
	POINT cursor;
	RECT selection;
	void resize_image(int w,int h){
		CELL[] tmp;
		int x,y;
		tmp.length=w*h;
		for(y=0;y<height;y++){
			if(y>=h)
				break;
			for(x=0;x<width;x++){
				int src,dst;
				if(x>=w)
					break;
				src=x+y*width;
				dst=x+y*w;
				if(src>=cells.length)
					break;
				if(dst>=tmp.length)
					break;
				tmp[dst]=cells[src];
			}
		}
		cells=tmp;
	}
					 
};
IMAGE[] images;
int current_image=0;


