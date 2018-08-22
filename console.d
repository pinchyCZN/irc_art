module console;
import core.sys.windows.windows;


int get_key()
{
	int result=0;
	HANDLE hcon;
	hcon=GetStdHandle(STD_INPUT_HANDLE);
	if(hcon!=INVALID_HANDLE_VALUE){
		while(true){
			INPUT_RECORD rec;
			DWORD count=0;
			if(PeekConsoleInput(hcon,&rec,1,&count)){
				if(count==1){
					ReadConsoleInput(hcon,&rec,1,&count);
					if(rec.EventType==KEY_EVENT){
						if(rec.EventType==KEY_EVENT){
							KEY_EVENT_RECORD *ke=cast(KEY_EVENT_RECORD*)&rec.KeyEvent;
							if(ke.bKeyDown){
								result=cast(int)ke.wVirtualKeyCode;
								break;
							}
						}
					}else{
						break;
					}
				}
			}else{
				break;
			}
		}
	}
	return result;
}
