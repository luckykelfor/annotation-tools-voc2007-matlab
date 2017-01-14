function varargout = picturecrop(varargin)
% PICTURECROP M-file for picturecrop.fig
%      PICTURECROP, by itself, creates a new PICTURECROP or raises the existing
%      singleton*.
%
%      H = PICTURECROP returns the handle to a new PICTURECROP or the handle to
%      the existing singleton*.
%
%      PICTURECROP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PICTURECROP.M with the given input arguments.
%
%      PICTURECROP('Property','Value',...) creates a new PICTURECROP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before picturecrop_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to picturecrop_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help picturecrop

% Last Modified by GUIDE v2.5 10-Jan-2017 21:01:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @picturecrop_OpeningFcn, ...
                   'gui_OutputFcn',  @picturecrop_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before picturecrop is made visible.
function picturecrop_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to picturecrop (see VARARGIN)

global pic_cut down;   
pic_cut=0;
down=0;

% Choose default command line output for picturecrop
handles.output = hObject;

handles.isSizeFixed = 'NO';
set(handles.FixSize,'Visible','Off');
handles.fixedPoint1=[0 0];
handles.fixedPoint2=[0 0];

handles.fixedHeight = 0;
handles.savePath ='.';%默认的保存目录
handles.openPath = '';
handles.currentPathFileList={};
handles.currentPathFileCount = 0;
handles.currentImageFileNameFull = '';%保存当前打开的文件的完整路径及名称
handles.tempImage = [];%保存为旋转之前的图像
handles.savedCutsCount = 0;
handles.fixedWidth = 0;
% Update handles structure
handles.rect = [];
handles.zoomInCount = 10;
handles.zoomOutCount = -10;
handles.zoom = [1 1.5  2.25 4 5.5 8 10 12.5 15 20];

handles.annotatedRects=[];%标注的矩形位置
handles.annotation.className = 'people';
handles.annotation.pose = 'Front';
handles.annotation.isDifficult = 0;
handles.annotation.isTruncated = 0;

handles.currentImageSize.width = 0;
handles.currentImageSize.height = 0;
handles.xmlBusy = false;
guidata(hObject, handles);


% UIWAIT makes picturecrop wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = picturecrop_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in search.
function search_Callback(hObject, eventdata, handles)
% hObject    handle to search (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename,pathname]=uigetfile({'*.png;*.bmp;*.jpg;*.gif','(*.png;*.bmp;*.jpg;*.gif)';'*.bmp','(*.bmp)';'*.jpg','(*.jpg)';'*.png','(*.png)';},'打开图片');
if(filename == 0)
    return;
end
handles.currentImageFileNameFull = [pathname,filename];
handles.currentImageFileName = filename;
handles.zoomInCount = 10;
handles.zoomOutCount = -10;
handles.annotatedRects =[];
A=imread(handles.currentImageFileNameFull);
[height,width,~] = size(A);
handles.currentImageSize.width = width;
handles.currentImageSize.height = height;
cla(handles.axes1);
axes(handles.axes1);

handles.currentFileList = dir(pathname);%保存当前打开图像所在目录的文件列表
handles.openPath = pathname;

handles.currentPathFileCount = 0;
imshow(A);
handles.image=A;

set(handles.currentImageHeight,'String',num2str(height));
set(handles.currentImageWidth,'String',num2str(width));

guidata(hObject,handles);





% --- Executes on button press in crop.
function crop_Callback(hObject, eventdata, handles)
% hObject    handle to crop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global pic_cut;
pic_cut=1;
zoom off

handles.begin_point=get(gca,'currentpoint'); %先初始化开始的点的坐标，否则程序会报错
set(handles.crop,'Visible','Off');

guidata(hObject,handles);


% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
AnnotationPath = 'Annotations';
if(isempty(handles.rect)~=1)
    tempRect = handles.rect;

    if(~handles.xmlBusy)
        handles.xmlBusy = true;
        
        if(exist([handles.savePath,'/',AnnotationPath],'dir')~=7)
           mkdir([handles.savePath,'/',AnnotationPath]);
        end
        handles.xmlFile = fopen([handles.savePath,'/',AnnotationPath,'/',handles.currentImageFileName(1:end-4),'.xml'],'w');
        fprintf(handles.xmlFile,'<annotation>\n\t<folder>VOC2007</folder>\n\t<filename>%s</filename>\n\t<source>\n\t\t<database>The VOC2007 Database</database>\n\t\t<annotation>PASCAL VOC2007</annotation>\n\t\t<image>flickr</image>\n\t\t<flickrid>NULL</flickrid>\n\t</source>\n\t<owner>\n\t\t<flickrid>VIP-G</flickrid>\n\t\t<name>?</name>\n\t</owner>\n\t<size>\n\t\t<width>%d</width>\n\t\t<height>%d</heigt>\n\t\t<depth>3</depth>\n\t</size>\n\t<segmented>%d</segmented>\n',...
            handles.currentImageFileName,handles.currentImageSize.width,handles.currentImageSize.height,0);
    end
    fprintf(handles.xmlFile,'\t<object>\n\t\t<name>%s</name>\n\t\t<pose>%s</pose>\n\t\t<truncated>%d</truncated>\n\t\t<difficult>%d</difficult>\n\t\t<bndbox>\n\t\t\t<xmin>%d</xmin>\n\t\t\t<ymin>%d</ymin>\n\t\t\t<xmax>%d</xmax>\n\t\t\t<ymax>%d</ymax>\n\t\t</bndbox>\n\t</object>\n',...
        handles.annotation.className,handles.annotation.pose,handles.annotation.isTruncated,handles.annotation.isDifficult,tempRect(1),tempRect(2),tempRect(1)+tempRect(3)+1,tempRect(2)+tempRect(4)+1);
    
    
    
%     file = fopen([handles.savePath,'/MyTrainingSetAnnotation.txt'],'a');

%     fprintf(file,'%d %d %d %d %s\n',tempRect(1),tempRect(2),tempRect(1)+tempRect(3)+1,tempRect(2)+tempRect(4)+1,handles.currentImageFileNameFull);

    % newdata=handles.newdata;
    % filename = [handles.savePath,'\\',num2str(handles.savedCutsCount),'.jpg'];
    % 
    %  imwrite(newdata,filename);  
     handles.savedCutsCount = handles.savedCutsCount+1;
%      fclose(file);
end
  guidata(hObject,handles);


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global pic_cut down;
down=1;

    if pic_cut==1&&down==1
%        if(strcmp(handles.isSizeFixed,'NO')
            
          begin_point=get(gca,'currentpoint'); %------按下鼠标左键时取得鼠标当前的坐标值-------
           handles.begin_point=begin_point;
        
            handles.fixedPoint1=begin_point;%保存固定尺寸时候的矩形起始点
%        else
         if(strcmp(handles.isSizeFixed,'YES')==1)
           if handles.fixedWidth*handles.fixedHeight~=0       
                data=handles.image;
                axes(handles.axes1);
                imshow(data);
                %------------用rectangle函数显示选中的图像截取区域------------------------
                rect=floor([handles.fixedPoint1(1,1)-handles.fixedWidth/2,handles.fixedPoint1(1,2)-handles.fixedHeight/2, handles.fixedWidth-1 handles.fixedHeight-1]);
                rectangle('Position',rect,'edgecolor','r','LineWidth',2,'LineStyle','--');

                handles.rect=rect;
                guidata(hObject,handles);
           end
           
         end
    
   end

guidata(hObject,handles);

% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global pic_cut down;
if( strcmp(handles.isSizeFixed , 'NO')==1)
    if pic_cut==1&&down==1
        begin_point=handles.begin_point;
        end_point=get(gca,'currentpoint'); %----------鼠标移动时取得鼠标当前的坐标值-------

        x0=begin_point(1,1);
        y0=begin_point(1,2);
        x=end_point(1,1);
        y=end_point(1,2);

        width=abs(x-x0);
        handles.fixedWidth = width;
        
        height=abs(y-y0);
        handles.fixedHeight = height;
        rect=floor([min(x,x0) min(y, y0) width-1 height-1]);

       if width*height~=0       
        data=handles.image;
        axes(handles.axes1);
        imshow(data);
        %------------用rectangle函数显示选中的图像截取区域------------------------
        rectangle('Position',rect,'edgecolor','r','LineWidth',2,'LineStyle','--');

        handles.rect=rect;
        set(handles.sizeofCut,'String',[num2str(floor(width)),'x',num2str(floor(height))]);
        guidata(hObject,handles);
       end
    end
    
    

end
guidata(hObject,handles);


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global pic_cut down;

% if(strcmp(get(handles.crop,'Visible'),'Off')==1)

    if(strcmp(handles.isSizeFixed, 'NO')==1)
        set(handles.FixSize,'Visible','On');

    end
% end

if(strcmp(handles.isSizeFixed,'NO')==1)
    handles.fixedPoint2 =get(gca,'currentpoint');

    if pic_cut==1
        rect=handles.rect;
        data=handles.image;
        newdata=imcrop(data,rect);%------截取图像的选中区域---------

       %cla;%----------取消图像上的矩形选中区域---------------
       axes(handles.axes2);
       imshow(newdata);

%        pic_cut=0;
       down=0;
       handles.newdata=newdata;
    end
else
    if pic_cut==1
        rect=handles.rect;
        data=handles.image;
        newdata=imcrop(data,rect);%------截取图像的选中区域---------

       %cla;%----------取消图像上的矩形选中区域---------------
       axes(handles.axes2);
       imshow(newdata);

%        pic_cut=0;
       down=0;
       handles.newdata=newdata;
    end  ;
end
guidata(hObject,handles);

% --- Executes on button press in FixSize.
function FixSize_Callback(hObject, eventdata, handles)
% hObject    handle to FixSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% if(strcmp(get(handles.crop,'Visible'),'Off')==1)
     if(strcmp(handles.isSizeFixed,'NO')==1) 
         handles.isSizeFixed = 'YES';
         set(handles.FixSize,'String','取消固定');
         set(handles.editHeight,'Visible','On');
         set(handles.editWidth,'Visible','On');
%         set(handles.manualSize,'Visible','On');
         
         set(handles.editHeight,'String',num2str(floor(handles.fixedHeight)));
         set(handles.editWidth,'String',num2str(floor(handles.fixedWidth)));
         
     
     else 
         handles.isSizeFixed = 'NO'
         set(handles.FixSize,'String','固定窗口');
         set(handles.editHeight,'Visible','Off');
         set(handles.editWidth,'Visible','Off');
%         set(handles.manualSize,'Visible','Off');
     end
% end
   guidata(hObject,handles);%记得更新数据


% --- Executes on button press in SavePath.
function SavePath_Callback(hObject, eventdata, handles)
% hObject    handle to SavePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
path =        uigetdir('./');
if(path == 0)
    return;
end
handles.savePath = path;
guidata(hObject,handles);%记得更新数据




function editHeight_Callback(hObject, eventdata, handles)
% hObject    handle to editHeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tempH = get(hObject,'String');
tempH = str2num(tempH);
if(isequal([],tempH))
    errordlg('Must be an integer.');
    return;
end
if(round(tempH) == 0)
    return;
end
handles.fixedHeight = tempH;
guidata(hObject,handles);%记得更新数据
    
% Hints: get(hObject,'String') returns contents of editHeight as text
%        str2double(get(hObject,'String')) returns contents of editHeight as a double


% --- Executes during object creation, after setting all properties.
function editHeight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editHeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editWidth_Callback(hObject, eventdata, handles)
% hObject    handle to editWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tempW = get(hObject,'String');
tempW = str2num(tempW);
if(isequal([],tempW))
    errordlg('Must be an integer.');
    return;
end
if(round(tempW) == 0)
    return;
end
handles.fixedWidth = tempW;
guidata(hObject,handles);%记得更新数据
% Hints:  returns contents of editWidth as text
%        str2double(get(hObject,'String')) returns contents of editWidth as a double


% --- Executes during object creation, after setting all properties.
function editWidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

         
         


% --- Executes on button press in batchRenameFiles.
function batchRenameFiles_Callback(hObject, eventdata, handles)
% hObject    handle to batchRenameFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 

    processDir = uigetdir('./');
    if(0==processDir)
        return;
    end
    
    list = dir(processDir);
    prompt = {'Enter renaming prefix:','Enter renaming digit number:'};
    dlg_title = 'Renaming Format';
    num_lines = 1;
    def = {'prefix','6'};
    result = inputdlg(prompt,dlg_title,num_lines,def);
    prefix = result{1};
    digitNum = result{2};
    
    if(~isequal([],str2num(digitNum)))
        if(length(digitNum)>1)
            warndlg('Can not be able to handle that many files!');
            return;
        end
        %digitNum = str2num(digitNum);
    else
        errordlg('Must be a number');
        return;
    end 


    num_i = 1;
    for i = 1: size(list,1)
        if(list(i).isdir == 0)%如果不是目录，是文件
            fullFileName = [processDir,'\',list(i).name];

            newName = '';
            [pathstr,~,ext] = fileparts(fullFileName);
           
            %  filedWidth = '';
            %   fprintf(filedWidth,'%d',digitNum);
           newName = sprintf(['%s%0',digitNum,'d%s'],prefix,num_i,ext);
            cmd = [fullFileName,' ',[processDir,'\',newName]];
            if(isunix)
                cmd = ['mv',cmd];
                
                
            else
                
                cmd = ['move ',' ', cmd];
                
            end
            
            [status,~] = system(cmd);
            if(status==0)
                num_i = num_i + 1;
            end
        end
        
        
    end
    
 



 
 
% --- Executes on button press in iterNextImage.
function iterNextImage_Callback(hObject, eventdata, handles)
% hObject    handle to iterNextImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(strcmp(handles.currentImageFileNameFull,'')==1)%如果没有打开图像
    return;
else
    if(handles.xmlBusy)
        fprintf(handles.xmlFile,'</annotation>');
        fclose(handles.xmlFile);
        handles.xmlBusy = false;
    end
    list = handles.currentFileList;
    for i = (handles.currentPathFileCount+1): size(list,1)
        if(list(i).isdir == 0)%如果不是目录，是文件
            fullFileName = [handles.openPath,list(i).name];

            if(strcmp(finfo(fullFileName),'im')~=1)%如果是当前图像，跳过
                continue;
            elseif(strcmp(fullFileName,handles.currentImageFileNameFull) ~=1)%不是当前的图像
                %否则调用打开函数
                handles.currentImageFileNameFull = fullFileName;
                handles.currentImageFileName = list(i).name;
                handles.zoomInCount = 10;
                handles.zoomOutCount = -10;
                handles.annotatedRects=[];
                A=imread(handles.currentImageFileNameFull);
                [height,width,~] = size(A);
                if(length(size(A))>3)
                    continue;
                end
              axes(handles.axes1);

                  handles.currentPathFileCount = i;
 
                imshow(A);
                handles.image=A;

                set(handles.currentImageHeight,'String',num2str(height));
                set(handles.currentImageWidth,'String',num2str(width));

               

                break;
            end

        end
        
    end
    guidata(hObject,handles);


end


% --- Executes on selection change in annotation_isDifficult.
function annotation_isDifficult_Callback(hObject, eventdata, handles)
% hObject    handle to annotation_isDifficult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = cellstr(get(hObject,'String'));%returns annotation_isDifficult contents as cell array\
a = contents{get(hObject,'Value')};
handles.annotation.isDifficult = str2num(a);
guidata(hObject,handles);
% Hints: contents = cellstr(get(hObject,'String')) returns annotation_isDifficult contents as cell array
%        contents{get(hObject,'Value')} returns selected item from annotation_isDifficult


% --- Executes during object creation, after setting all properties.
function annotation_isDifficult_CreateFcn(hObject, eventdata, handles)
% hObject    handle to annotation_isDifficult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in annotation_isTruncated.
function annotation_isTruncated_Callback(hObject, eventdata, handles)
% hObject    handle to annotation_isTruncated (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = cellstr(get(hObject,'String')); %returns annotation_isDifficult contents as cell array\
a = contents{get(hObject,'Value')};
handles.annotation.isTruncated = str2num(a);
guidata(hObject,handles);
% Hints: contents = cellstr(get(hObject,'String')) returns annotation_isTruncated contents as cell array
%        contents{get(hObject,'Value')} returns selected item from annotation_isTruncated


% --- Executes during object creation, after setting all properties.
function annotation_isTruncated_CreateFcn(hObject, eventdata, handles)
% hObject    handle to annotation_isTruncated (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



 
% Hints: get(hObject,'String') returns contents of annotation_className as text
%        str2double(get(hObject,'String')) returns contents of annotation_className as a double


% --- Executes during object creation, after setting all properties.
function annotation_className_CreateFcn(hObject, eventdata, handles)
% hObject    handle to annotation_className (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function annotation_className_Callback(hObject, eventdata, handles)
% hObject    handle to annotation_className (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.annotation.className = get(hObject,'String');
    guidata(hObject,handles);
% Hints: get(hObject,'String') returns contents of annotation_className as text
%        str2double(get(hObject,'String')) returns contents of annotation_className as a double



function annotation_pose_Callback(hObject, eventdata, handles)
% hObject    handle to annotation_pose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.annotation.pose = get(hObject,'String');
    guidata(hObject,handles);
% Hints:  returns contents of annotation_pose as text
%        str2double(get(hObject,'String')) returns contents of annotation_pose as a double


% --- Executes during object creation, after setting all properties.
function annotation_pose_CreateFcn(hObject, eventdata, handles)
% hObject    handle to annotation_pose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(handles.xmlBusy)
    fprintf(handles.xmlFile,'</annotation>');
    fclose(handles.xmlFile);
end
guidata(hObject,handles);



function renamePrefix_edit_Callback(hObject, eventdata, handles)
% hObject    handle to renamePrefix_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of renamePrefix_edit as text
%        str2double(get(hObject,'String')) returns contents of renamePrefix_edit as a double


% --- Executes during object creation, after setting all properties.
function renamePrefix_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to renamePrefix_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function renameDigitNum_Callback(hObject, eventdata, handles)
% hObject    handle to renameDigitNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of renameDigitNum as text
%        str2double(get(hObject,'String')) returns contents of renameDigitNum as a double


% --- Executes during object creation, after setting all properties.
function renameDigitNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to renameDigitNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton14.
function pushbutton14_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(exist([handles.savePath,'/ImageSets'],'dir')~=7)
    mkdir([handles.savePath,'/ImageSets']);
    if(exist([handles.savePath,'/ImageSets/Main'],'dir')~=7)
        mkdir([handles.savePath,'/ImageSets/Main']);
    end
end

file = dir([handles.savePath,'/Annotations/']);
len = length(file)-2;


num_trainval=sort(randperm(len, floor(9*len/10)));%trainval集占所有数据的9/10，可以根据需要设置
num_train=sort(num_trainval(randperm(length(num_trainval), floor(5*length(num_trainval)/6))));%train集占trainval集的5/6，可以根据需要设置
num_val=setdiff(num_trainval,num_train);%trainval集剩下的作为val集
num_test=setdiff(1:len,num_trainval);%所有数据中剩下的作为test集


path = [handles.savePath,'/ImageSets/Main/'];


fid=fopen(strcat(path, 'trainval.txt'),'a+');
for i=1:length(num_trainval)
    s = sprintf('%s',file(num_trainval(i)+2).name);
    fprintf(fid,[s(1:length(s)-4) '\r\n']);
end
fclose(fid);


fid=fopen(strcat(path, 'train.txt'),'a+');
for i=1:length(num_train)
    s = sprintf('%s',file(num_train(i)+2).name);
    fprintf(fid,[s(1:length(s)-4) '\r\n']);
end
fclose(fid);


fid=fopen(strcat(path, 'val.txt'),'a+');
for i=1:length(num_val)
    s = sprintf('%s',file(num_val(i)+2).name);
    fprintf(fid,[s(1:length(s)-4) '\r\n']);
end
fclose(fid);


fid=fopen(strcat(path, 'test.txt'),'a+');
for i=1:length(num_test)
    s = sprintf('%s',file(num_test(i)+2).name);
    fprintf(fid,[s(1:length(s)-4) '\r\n']);
end
fclose(fid);

