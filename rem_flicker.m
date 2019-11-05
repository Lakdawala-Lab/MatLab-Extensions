%% 
close all;
clear all;
% choose directory containing datasets
tic;
dirn = 'D:\SPIMdata\20170823\Lat_A\A549_wt_CA09GFP_LatA_6';
num_tf=500;
cd(dirn);
back_int=zeros(num_tf,1);
fname_txt='Decon_SPIMA';

imginfo = imfinfo('Decon_SPIMA000.tif');
imw=imginfo(1).Width;
imh=imginfo(1).Height;
imd=length(imginfo);

image_temp=zeros(imh,imw,imd,'uint16');

%h = waitbar(0,'file number');
parfor tidx=1:1:num_tf
    norm=0;
    fn=[fname_txt,num2str(tidx-1, '% .3d'),'.tif'];
    for idx=5:1:120%imd-25
        % uncomment for GPU
        % image_temp(:,:,idx) = imread(fn,idx);
        
        % uncomment for CPU
        A = imread(fn,idx);
        norm = norm + sum(sum(A));
    end
    % uncomment for GPU
    %     G1=gpuArray(image_temp);
    %     Gsum = sum(sum(sum(G1)));
    %     back_int (tidx) = gather(Gsum);
    
    % uncomment for CPU
    back_int(tidx)=norm;
    %waitbar(double(tidx/500),h);
end

%disp(norm);
%close(h);
plot(back_int);
back_intn=(max(back_int)*ones(length(back_int),1))./back_int;
figure;
plot(back_intn);

% choose directory where to store normalized dataset
if ~isdir('int_norm')
    mkdir('int_norm');
end
toc;
%cd('int_norm');
%%
parfor tidx=1:1:num_tf
    norm=0;
    image_temp=uint16(zeros(imh,imw,imd));
    fn=[fname_txt,num2str(tidx-1, '% .3d'),'.tif'];
    for zidx=1:1:imd
        image_temp(:,:,zidx) = uint16(back_intn(tidx)*imread(fn,zidx));
    end
    t=Tiff(['int_norm\',fname_txt,'n',num2str(tidx-1, '% .3d'),'.tif'],'w');
    
    for didx=1:1:imd
        setTag(t,'ImageLength',imh);
        setTag(t,'ImageWidth',imw);
        setTag(t,'Photometric',1);
        setTag(t,'BitsPerSample',16);
        setTag(t,'SampleFormat',Tiff.SampleFormat.UInt);
        setTag(t,'Compression',Tiff.Compression.LZW);
        setTag(t,'PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
        setTag(t,'SamplesPerPixel',1);
        setTag(t,'RowsPerStrip',1);
        write(t,image_temp(:,:,didx));
        if didx ~= imd
            writeDirectory(t);
        end
    end
    t.close();
end


