clc;
clear all;
close all;
tic;
image = imread('../data/images/c8.png');
image =  imgaussfilt(image,2);
image=rgb2ycbcr(image);
image = double(image);

% figure(1), hold off, imagesc(image);

% [x, y] = ginput;                                                              
% mask = 255-255*poly2mask(x, y, size(image, 1), size(image, 2)); 


mask = imread('../data/images/c8_mask.png');
mask = 255-mask;
mask = double(mask);

psi = 5;
window = 50;
alpha=255;
width=3;
grad_window = 48;
f = 2.5;

[rows,cols] = size(mask);
confidence_mat = ones(rows,cols);


for i=1:rows
    for j=1:cols
        if mask(i,j) == 0
           confidence_mat(i,j) = 0;
        end
    end
end
    
while 1
    priority_mat = zeros(rows,cols);
    border_list = find_border(mask);
    if size(border_list) == [0,0]
       break
    end
    
    [rows,cols] = size(border_list);
    max_p_x = 0;
    max_p_y = 0;
    max_p = -1;
    G = grad1(image);
    
    for i = 1:rows
        x = border_list(i,1); 
        y = border_list(i,2);
        cp = confidence(psi,x,y,confidence_mat);
        dt = isophote1(x,y,G,psi,mask);

        norm_vector = norm_vec(border_list,[x,y],width);
        dp = abs(dt'*norm_vector)/alpha;
%         prio = cp*dp;
%           prio = cp*dp;
        prio = [cp; f*dp];
        prio = sum(prio);

        priority_mat(x,y) = prio;
        if prio > max_p
            max_p_x = x;
            max_p_y = y;    
            max_p = prio;
        end
    end
    

    confidence_mat(max_p_x,max_p_y) = confidence(psi,max_p_x,max_p_y,confidence_mat);
    [min_i,min_j] = patch_fill(max_p_x,max_p_y,image,mask,window,psi,confidence_mat);
    cp = confidence(psi,max_p_x,max_p_y,confidence_mat);
    
    for i=-psi:psi
        for j=-psi:psi
            if mask(max_p_x+i,max_p_y+j) == 0
               image(max_p_x+i,max_p_y+j,:) = image(min_i+i,min_j+j,:);
               mask(max_p_x+i,max_p_y+j)=255;
               confidence_mat(max_p_x+i,max_p_y+j) = cp;
            end
        end
    end
figure(1);
imagesc(ycbcr2rgb(uint8(image)));

figure(2);
[rows,cols] = size(mask);
I = zeros(rows, cols);
for i=1:rows
    for j=1:cols
        if(mask(i,j)==0)
            I(i,j) = norm(isophote1(i, j, G, psi, mask));
        end
    end
end
imagesc(I); colormap(gray);

figure(3);
imagesc(priority_mat);colormap(gray);

figure(4);
imagesc(confidence_mat); colormap(gray);
end
% image= hsv2rgb(image);
toc;
