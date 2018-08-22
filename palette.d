module palette;

nothrow:

int[] color_lookup=[
	//RRGGBB
	0xFFFFFF, //0 white
	0x000000, //1 black
	0x00007F, //2 blue (navy)
	0x009300, //3 green
	0xFF0000, //4 red
	0x7F0000, //5 brown (maroon)
	0x9C009C, //6 purple
	0xFC7F00, //7 orange (olive)
	0xFFFF00, //8 yellow
	0x00FC00, //9 light green (lime)
	0x009393, //10 teal (a green/blue cyan)
	0x00FFFF, //11 light cyan (cyan) (aqua)
	0x0000FC, //12 light blue (royal)
	0xFF00FF, //13 pink (light purple) (fuchsia)
	0x7F7F7F, //14 grey
	0xD2D2D2, //15 light grey (silver)
	0x470000, //extended colors http://anti.teamidiot.de/static/nei/*/extended_mirc_color_proposal.html
	0x472100,
	0x474700,
	0x324700,
	0x004700,
	0x00472C,
	0x004747,
	0x002747,
	0x000047,
	0x2E0047,
	0x470047,
	0x47002A,
	0x740000,
	0x743A00,
	0x747400,
	0x517400,
	0x007400,
	0x007449,
	0x007474,
	0x004074,
	0x000074,
	0x4B0074,
	0x740074,
	0x740045,
	0xB50000,
	0xB56300,
	0xB5B500,
	0x7DB500,
	0x00B500,
	0x00B571,
	0x00B5B5,
	0x0063B5,
	0x0000B5,
	0x7500B5,
	0xB500B5,
	0xB5006B,
	0xFF0000,
	0xFF8C00,
	0xFFFF00,
	0xB2FF00,
	0x00FF00,
	0x00FFA0,
	0x00FFFF,
	0x008CFF,
	0x0000FF,
	0xA500FF,
	0xFF00FF,
	0xFF0098,
	0xFF5959,
	0xFFB459,
	0xFFFF71,
	0xCFFF60,
	0x6FFF6F,
	0x65FFC9,
	0x6DFFFF,
	0x59B4FF,
	0x5959FF,
	0xC459FF,
	0xFF66FF,
	0xFF59BC,
	0xFF9C9C,
	0xFFD39C,
	0xFFFF9C,
	0xE2FF9C,
	0x9CFF9C,
	0x9CFFDB,
	0x9CFFFF,
	0x9CD3FF,
	0x9C9CFF,
	0xDC9CFF,
	0xFF9CFF,
	0xFF94D3,
	0x000000,
	0x131313,
	0x282828,
	0x363636,
	0x4D4D4D,
	0x656565,
	0x818181,
	0x9F9F9F,
	0xBCBCBC,
	0xE2E2E2,
	0xFFFFFF
];

int get_rgb_color(int pal_index)
{
	int result=0;
	if(pal_index<0 || pal_index>=color_lookup.length)
		return result;
	result=color_lookup[pal_index];
	return result;
}

int get_cindex(int x,int y,int w,int h)
{
	int index,size;
	index=(x/(w/8));
	if(y<(h/2)){
		if(index>=8)
			index=7;
	}else{
		index+=8;
	}
	size=color_lookup.length;
	if(index>=size)
		index=size-1;
	return index;
}

import core.sys.windows.windows;
import core.stdc.string;
import core.stdc.stdlib;
import resource;

static int palette_w,palette_h;
static int *palette;

int get_extcindex(int x,int y,int pw,int ph)
{
	int index=x/(pw/4);
	if(index>3)
		index=3;
	y=y/(ph/20);
	index+=y*4;
	index+=16;
	if(index>99)
		index=99;
	return index;
}
int paint_colors(HWND hwnd,HDC hdc)
{
	BITMAPINFO bmi;
	int w,h,pw,ph;
	int init=FALSE;
	RECT rect;

	GetWindowRect(hwnd,&rect);
	w=rect.right-rect.left;
	h=rect.bottom-rect.top;
	if(palette_w!=w || palette_h!=h){
		int size=w*h*4;
		int *tmp=cast(int*)realloc(palette,size);
		if(tmp){
			palette=tmp;
			init=TRUE;
			palette_w=w;
			palette_h=h;
			memset(palette,0,size);
		}
	}
	if(!palette)
		return 0;
	if(palette_w<=0 || palette_h<=0)
		return 0;
	pw=palette_w;
	ph=palette_h;
	if(init){
		int x,y;
		for(x=0;x<pw;x++){
			for(y=0;y<ph;y++){
				int c,index;
				index=get_cindex(x,y,pw,ph);
				if(index>=color_lookup.length)
					index=0;
				c=color_lookup[index];
				{
					int offset;
					offset=x+(ph-y-1)*pw; //flip
					if(offset<(pw*ph))
						palette[offset]=c;
				}
			}
		}
	}
	memset(&bmi,0,bmi.sizeof);
	bmi.bmiHeader.biBitCount=32;
	bmi.bmiHeader.biWidth=pw;
	bmi.bmiHeader.biHeight=ph;
	bmi.bmiHeader.biPlanes=1;
	bmi.bmiHeader.biSizeImage=pw*ph;
	bmi.bmiHeader.biSize=BITMAPINFOHEADER.sizeof;
	SetDIBitsToDevice(hdc,0,0,pw,ph,
					  0,0, //src xy
					  0,ph, //startscan,scanlines
					  palette,
					  cast(BITMAPINFO*)&bmi,DIB_RGB_COLORS);

	return 0;
}


void paint_current_colors(HWND hwnd,HDC hdc,int id,int fg,int bg)
{
	BITMAPINFO bmi;
	int c;
	RECT rect;
	int w,h;
	if(IDC_FG==id)
		c=fg;
	else
		c=bg;
	if(c<0 || c>=color_lookup.length)
		return;
	c=color_lookup[c];
	GetWindowRect(hwnd,&rect);
	w=rect.right-rect.left;
	h=rect.bottom-rect.top;
	memset(&bmi,0,bmi.sizeof);
	bmi.bmiHeader.biBitCount=32;
	bmi.bmiHeader.biWidth=1;
	bmi.bmiHeader.biHeight=1;
	bmi.bmiHeader.biPlanes=1;
	bmi.bmiHeader.biSizeImage=1;
	bmi.bmiHeader.biSize=BITMAPINFOHEADER.sizeof;
	StretchDIBits(hdc,0,0,w,h,
				  0,0,1,1,
				  &c,
				  cast(BITMAPINFO*)&bmi,DIB_RGB_COLORS,SRCCOPY);
	return;
}

void palette_click(int x, int y,UINT msg,int *fg,int *bg)
{
	int index;
	index=get_cindex(x,y,palette_w,palette_h);
	switch(msg){
		case WM_LBUTTONDOWN:
			*fg=index;
			break;
		case WM_RBUTTONDOWN:
			*bg=index;
			break;
		default:
			break;
	}
}

static int ext_palette_w,ext_palette_h;
static int *ext_palette;

int paint_ext_colors(HWND hwnd,HDC hdc)
{
	BITMAPINFO bmi;
	int w,h,pw,ph;
	int init=FALSE;
	RECT rect;

	GetWindowRect(hwnd,&rect);
	w=rect.right-rect.left;
	h=rect.bottom-rect.top;
	if(ext_palette_w!=w || ext_palette_h!=h){
		int size=w*h*4;
		int *tmp=cast(int*)realloc(ext_palette,size);
		if(tmp){
			ext_palette=tmp;
			init=TRUE;
			ext_palette_w=w;
			ext_palette_h=h;
			memset(ext_palette,0,size);
		}
	}
	if(!ext_palette)
		return 0;
	if(ext_palette_w<=0 || ext_palette_h<=0)
		return 0;
	pw=ext_palette_w;
	ph=ext_palette_h;
	if(init){
		int x,y;
		for(x=0;x<pw;x++){
			for(y=0;y<ph;y++){
				int c,index;
				index=get_extcindex(x,y,pw,ph);
				if(index>=color_lookup.length)
					index=0;
				c=color_lookup[index];
				{
					int offset;
					offset=x+(ph-y-1)*pw; //flip
					if(offset<(pw*ph))
						ext_palette[offset]=c;
				}
			}
		}
	}
	memset(&bmi,0,bmi.sizeof);
	bmi.bmiHeader.biBitCount=32;
	bmi.bmiHeader.biWidth=pw;
	bmi.bmiHeader.biHeight=ph;
	bmi.bmiHeader.biPlanes=1;
	bmi.bmiHeader.biSizeImage=pw*ph;
	bmi.bmiHeader.biSize=BITMAPINFOHEADER.sizeof;
	SetDIBitsToDevice(hdc,0,0,pw,ph,
					  0,0, //src xy
					  0,ph, //startscan,scanlines
					  ext_palette,
					  cast(BITMAPINFO*)&bmi,DIB_RGB_COLORS);

	return 0;
}

void ext_palette_click(int x, int y,UINT msg,int *fg,int *bg)
{
	int index;
	index=get_extcindex(x,y,ext_palette_w,ext_palette_h);
	switch(msg){
		case WM_LBUTTONDOWN:
			*fg=index;
			break;
		case WM_RBUTTONDOWN:
			*bg=index;
			break;
		default:
			break;
	}
}