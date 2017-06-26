function R = rotz( t )
%ROTZ Rotate about the z-axis
    R = [cos(t) -sin(t) 0; sin(t) cos(t) 0; 0 0 1]';
end
