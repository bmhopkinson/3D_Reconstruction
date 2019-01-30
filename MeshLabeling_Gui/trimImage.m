function [Itrim, oldCenter] = trimImage(Image, centerPoint, Radius)
   [height, width, depth] = size(Image);
   x = round(centerPoint(1));
   y = round(centerPoint(2));
   oldCenter = [Radius, Radius]; % want to track input center point in trimmed image coordinates, insert shape uses [x, y] image-style format
   
   rowStart = y - Radius;
   rowEnd   = y + Radius;
   if(rowStart < 1)
       oldCenter(2) = oldCenter(2) + rowStart;
       rowStart = 1; 
   end
   if(rowEnd   > height)
       rowEnd = height; 
   end
   
   colStart = x - Radius;
   colEnd   = x + Radius;
   if(colStart < 1)
       oldCenter(1) = oldCenter(1) + colStart;
       colStart = 1; 
   end
   if(colEnd   > width), colEnd = width; end
   
   Itrim = Image(rowStart:rowEnd, colStart:colEnd, :);
  
end
