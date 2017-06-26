function drawWorld( Fi_i, Fc_i, scene_points )
%DRAW_WORLD Summary of this function goes here
%   Detailed explanation goes here

    X = scene_points(:,1);
    Y = scene_points(:, 2);
    Z = scene_points(:, 3);
    
    figure(1), clf;
    scatter3(X, Y, Z);
    adjustAxis(X,Y,Z);
    
    % Plot inertial frame
    plotCoordinateFrame(Fi_i, eye(3));
    adjustAxis(Fi_i);
    
    % Plot camera frame
    plotCoordinateFrame(Fc_i, eye(3));
    adjustAxis(Fc_i);

end

function plotCoordinateFrame(frame, R)
%PLOTCOORDINATEFRAME Plot a coordinate frame origin and orientation
%   Coordinate frames have a origin and an orientation. This function draws
%   the coordinate axes in a common frame.


    if nargin == 1, R = eye(3); end

    % Create coordinate axes starting at 0
    k = 5; % Size of each axis
    kk = linspace(0,k,100);
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

function adjustAxis(x, y, z)
%ADJUSTAXIS Just keep the size of the axes big enough for current data

    if nargin == 1
        z = x(3);
        y = x(2);
        x = x(1);
    end

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