function rotations
    clf
    % Definitions
    % -----------
    % Fi: inertial frame (0, 0, 0)
    % Fc: camera frame Fc = Ri_to_c*Fi + tc_ic

    % location of the inertial frame origin
    Fi = [0; 0; 0];

    % Relationship of Fc to Fi
    Ri_to_c = [0 -1 0; 0 0 -1; 1 0 0];
    % define translation in inertial frame and then rotate to express in Fc
    tc_ic = Ri_to_c*[2; 3; 0];

    % Definition of camera frame
    Fc = Ri_to_c*Fi + tc_ic;
    
    % Plot Coordinate Frames
    plotCoordinateFrame(Fi);
    plotCoordinateFrame(Fc, Ri_to_c');
    view(-90, 90);

    % 3D Point expressed in the inertial frame
    Pi = [10; 4; 0];
    plotPointInFrame(Pi);
    
    Pc = Ri_to_c*(Pi - [2; 3; 0])
end

function plotCoordinateFrame(frame, R)
%PLOTCOORDINATEFRAME Plot a coordinate frame origin and orientation
%   Coordinate frames have a origin and an orientation. This function draws
%   the coordinate axes in a common frame.


    if nargin == 1, R = eye(3); end

    % Create coordinate axes starting at 0
    kk = linspace(0,1,100);
    CX = [kk; zeros(1,length(kk)); zeros(1,length(kk))];
    CY = [zeros(1,length(kk)); kk; zeros(1,length(kk))];
    CZ = [zeros(1,length(kk)); zeros(1,length(kk)); kk];
    
    % Center the origin of the coordinate system according to `frame`
    CX = repmat(frame, 1, size(CX,2)) + CX;
    CY = repmat(frame, 1, size(CY,2)) + CY;
    CZ = repmat(frame, 1, size(CZ,2)) + CZ;
    
    % Transform using the rotation and translation that 
    CX = R*CX;
    CY = R*CY;
    CZ = R*CZ;
    
    % Plot the axes
    hold on; ls = '-';
    plot3(CX(1,:), CX(2,:), CX(3,:),'color','r','linewidth',2,'linestyle',ls);
    plot3(CY(1,:), CY(2,:), CY(3,:),'color','g','linewidth',2,'linestyle',ls);
    plot3(CZ(1,:), CZ(2,:), CZ(3,:),'color','b','linewidth',2,'linestyle',ls);
    
    % Margin on axis
    adjustAxis(CX, CY, CZ);
    view(-30, 30); axis square; grid on;
    xlabel('North (x)'); ylabel('East (y)'); zlabel('-Down (-z)')

end

function plotPointInFrame(pt, frame)
%PLOTPOINTINFRAME Plot a 3D point in the given coordinate frame

    scatter3(pt(1), pt(2), pt(3));
    
    adjustAxis(pt(1), pt(2), pt(3));
end

function adjustAxis(x, y, z)
%ADJUSTAXIS Just keep the size of the axes big enough for current data

    ax = axis;
    x = [min(x(:)) max(x(:)) ax(1) ax(2)];
    y = [min(y(:)) max(y(:)) ax(3) ax(4)];
    if length(ax) == 6
        z = [min(z(:)) max(z(:)) ax(5) ax(6)];
    end

    % Margin on axis
    m = 2;
    axis([min(x(:))-m  max(x(:))+m  min(y(:))-m  max(y(:))+m  min(z(:))-m  max(z(:))+m]);
    axis square;

end