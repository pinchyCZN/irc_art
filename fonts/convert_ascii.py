import os;


def get_outfname(path):
    s=os.path.dirname(path);
    t=os.path.splitext(path)[0];
    t=t.replace(" ","_");
    t=t.replace("-","_");
    s=os.path.join(s,t)+'.d';
    return s;

def get_height(lines):
    result=0;
    if(len(lines)>0):
        s=lines[0];
        if("flf2a$ " in s):
            s=s.replace("flf2a$ ","");
            s=s.split(" ");
            s=s[0];
            result=int(s);
    return result;            
            
def get_str_name(path):
    s=os.path.basename(path);
    s=os.path.splitext(s)[0];
    s=s.replace(" ","_");
    s=s.replace("-","_");
    return s;

def get_ext(path):
    filename, file_extension = os.path.splitext(path)
    return file_extension;
    
def get_flist(path):
    flist=[];
    tmp=os.listdir(path)
    for s in tmp:
        s=os.path.join(path,s)
        if(os.path.isfile(s)):
            ext=get_ext(s);
            ext=ext.lower();
            if("flf" in ext):
                flist.append(s)
    return flist;
    for root,dirs,files in os.walk(path):
        for filename in files:
            tmp=os.path.join(root, filename)
            if(os.path.isfile(tmp)):
                ext=get_ext(filename);
                ext=ext.lower();
                if("flf" in ext):
                    flist.append(os.path.join(root, filename))
    return flist;

def sanitize_str(s):
    s=s.rstrip();
    s=s.replace("$"," ");
    return s;

def escape_str(s):
    if('"' in s):
        s=s.replace('"','"~"\\""~r"');
    return s;

def fix_raw_str(s):
    result="";
    if(len(s)==0):
        result=" ";
    else:
        for c in s:
            if(ord(c)>0x7F):
                c=' ';
            result+=c;
    return result;

def process_fig(fname):
    f=open(fname,"r");

    lines=f.readlines();
    f.close();

    count=0;
    data=[];
    mdata=[];
    for t in lines:
        t=sanitize_str(t);
        if(len(t)==0):
            continue;
        delim=t[-1:]
        if(not('#'==delim) or ('@'==delim)):
            continue;
        count+=1;
        end=False;
        if(len(t)>2):
            tmp=t[-2:];
            if((delim+delim) in tmp):
                t=t[:-2];
                end=True;
        if(len(t)>1):
            tmp=t[-1:];
            if(delim in tmp):
                t=t[:-1]
        line=t;
        if(count>1) and end:
            y=count;
            x=len(line);
            mdata.append((x,y));
            count=0;
        if(len(line)>0):
            data.append(line);
            #print(line);

    if(len(data)==0):
        print("error in:"+fname);
        return;
    foutname=get_outfname(fname);
    f=open(foutname,"w");

    var_name=get_str_name(foutname);
    s="string "+var_name+"_data=\n";
    f.write(s);
    for s in data[:-1]:
        s=fix_raw_str(s);
        if('"' in s):
            if('`' in s):
                s=escape_str(s);
                s="r\""+s+"\"~\n";
            else:
                s="`"+s+"`~\n";
        else:
            s="r\""+s+"\"~\n";
        s="\t"+s;
        f.write(s);
    f.write("\tr\""+data[-1]+"\"\n");
    f.write(";\n\n");

    f.write("ubyte[] "+var_name+"_mdata=[\n");
    for x in mdata:
        s=str(x[0])+','+str(x[1])+',';
        s+='\n';
        s="\t"+s;
        f.write(s);
    f.write("];\n");
    f.close();    

def get_mdata(flist):
    for fname in flist:
        s=get_str_name(fname);
        #s=os.path.basename(fname);
        #s=os.path.splitext(s)[0];
        up=s.upper();
        x="case "+up+":"
        print(x)
        x="\tfont.data=cast(ubyte[])"+s+"_data;";
        print(x)
        x="\tfont.ascii_start=' ';";
        print(x)
        x="\tfont.mdata="+s+"_mdata;";
        print(x)
        x="\tbreak;"
        print(x)
    print("");        
    for fname in flist:
        s=get_str_name(fname);
        up=s.upper();
        print(up+",");


flist=get_flist("b:\\");

for s in flist:
    print("processing: "+s);
    process_fig(s);
get_mdata(flist);



