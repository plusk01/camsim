function R = rotx( t )
%ROTX Rotate about the x-axis
    R = [1 0 0; 0 cos(t) -sin(t); 0 sin(t) cos(t)]';
end

