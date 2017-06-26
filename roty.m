function R = roty( t )
%ROTY Rotate about the y-axis
    R = [cos(t) 0 sin(t); 0 1 0; -sin(t) 0 cos(t)]';
end
