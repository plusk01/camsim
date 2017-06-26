classdef Camera < handle
    %CAMERA Create an object that represents a specific camera
    %   Detailed explanation goes here
    
    properties
        wpx, hpx, fmm, pxmm
        afov_x, afov_y
        F
        K
        D
        
        scene
    end
    
    properties (Access = private)
        points
    end
    
    methods
        function cam = Camera(F, wpx, hpx, fmm, pxmm, binning)
            % F         Coordinate frame for the camera
            % wpx       horizontal resolution (pixels)
            % hpx       vertical resolution (pixels)
            % fmm       focal length (mm)
            % pxmm      pixel size (mm)
            % binning   Reduces the resolution by a factor, but doesn't
            %           change the FOV.
            
            if nargin < 6
                binning = 1;
            end
            
            % Perform binning
            wpx = wpx/binning;
            hpx = hpx/binning;
            pxmm = pxmm*binning;
            
            % Save camera info
            cam.F = F;
            cam.wpx = wpx;
            cam.hpx = hpx;
            
            % Focal length in pixels
            % fx = fy = fpx (assume pixel aspect ratio = 1:1)
            fpx = fmm/pxmm;
            
            % Ideal offset from optical axis (cx, cy)
            cx = wpx/2;
            cy = hpx/2;
            
            % Create intrinsic matrix
            cam.K = [fpx  0   cx;...
                     0    fpx cy;...
                     0    0   1 ];
            
            % Compute angular field-of-view for x and y
            cam.afov_x = 2*atan(wpx/(2*fpx));
            cam.afov_y = 2*atan(hpx/(2*fpx));
        end
        
        function draw(cam, varargin)
            %DRAW Draw the Camera FOV frustum
            
            % Argument defaults
            wrtF = cam.F.getAnchor();
            
            % Parse arguments
            for i = 1:(nargin-1)
                if isa(varargin{i}, 'Frame'), wrtF = varargin{i}; end
            end
            
            % Get the origin vector and orientation matrix of the camera
            % frame defined in the wrtF frame.
            [O, R] = cam.F.express(wrtF);
            
            drawFOV(O, R, cam.afov_x, cam.afov_y, cam.F.k+1);
        end
        
        function viewScene(cam, scene)
            %VIEWSCENE Project scene elements onto pixels
            
            cam.scene = scene;
            
            % =============================================================
            % Points
            % =============================================================
            
            pts = zeros(length(scene.points), 4);
            for i=1:length(scene.points)
                pts(i,1:3) = scene.points(i).pt;
                pts(i,4) = scene.points(i).id;
            end
            
            cam.points = pts(:, 1:3);
            
            % -------------------------------------------------------------
        end
        
        function showImage(cam)
            %SHOWIMAGE
            
            % get 3D scene points
            % Rotate and translate into camera frame
            % project onto sensor/pixel plane

            P = cam.K*cam.F.R*[eye(3) -cam.F.O];
            
            % How many points are there?
            N = length(cam.points);
            
            % Get homogeneous points
            pts = [cam.points ones(N,1)];
            
            % Project onto homogeneous pixels
            hpixels = (P*pts')';
            
            % Normalize pixels -- [u v 1]
            hpixels = hpixels./hpixels(:,3);
            
            U = hpixels(:,1);
            V = hpixels(:,2);
            
            title('Camera Image');
            scatter(U, V, 10);
            axis([0 cam.wpx 0 cam.hpx]);
            set(gca,'YDir','Reverse'); set(gca, 'XAxisLocation', 'top');
            xlabel('x (pixels)'); ylabel('y (pixels)');
            
            a = (1:N)'; b = num2str(a); c = cellstr(b);
            % displacement so the text does not overlay the data points
            dx = 8; dy = 0;
            text(U+dx, V+dy, c, 'FontSize', 8);
            
            % =============================================================
            % Planes
            % =============================================================
            
            for i=1:length(cam.scene.planes)
                
                % Create homogeneous 3D plane points
                pts = [cam.scene.planes(i).pts ones(4,1)];
                
                % Project onto homogeneous pixels
                hpixels = (P*pts')';

                % Normalize pixels -- [u v 1]
                hpixels = hpixels./hpixels(:,3);

                U = hpixels(:,1);
                V = hpixels(:,2);
                
                cam.scene.planes(i).draw([U V]);
                
            end
        end
    end
    
end


% function to draw camera fov
function drawFOV(O, R, fov_x, fov_y, k)
%DRAWFOV Draw the frustum of the camera FOV

% O     Origin of the camera
% R     Rotation from camera to world frame
% fov_x angular field of view in the width
% fov_y angular field of view in the height
% k     Scaling

    % define unit vectors along fov in the camera frame by rotating the
    % optical axis vector to the corners of the FOV
    pts = [ (rotx( fov_y/2)*roty( fov_x/2)*rotz(0)*[0;0;1]*k)'     % top-right
            (rotx( fov_y/2)*roty(-fov_x/2)*rotz(0)*[0;0;1]*k)'     % top-left
            (rotx(-fov_y/2)*roty(-fov_x/2)*rotz(0)*[0;0;1]*k)'     % bot-left
            (rotx(-fov_y/2)*roty( fov_x/2)*rotz(0)*[0;0;1]*k)' ]'; % bot-right

    % Rotate and then translate so that the pts that were expressed in the
    % local camera coordinate frame are now expressed in the frame that we
    % are drawing in.
    pts = R'*pts + repmat(O,1,4);
    
    % Create a matrix to hold all five of the vertices (rows)
    Vert = zeros(5, 3);
    
    % first vertex is at the origin of the camera frame, Fc
    Vert(1,:) = O';
    
    for i=1:4
        Vert(i+1,:) = pts(:,i);
    end
    
    Faces = [ 1  1  2  3    % top face
              1  1  2  5    % right face
              1  1  5  4    % bottom face
              1  1  4  3    % left face
              2  3  4  5 ]; % footprint face

    colors = [[1 1 1]; [1 1 1]; [1 1 1]; [1 1 1]; [0 1 0]];

    patch('Vertices', Vert, 'Faces', Faces,'FaceVertexCData',colors,...
            'FaceColor','flat','FaceAlpha',0.05);
    
    adjustAxis(Vert(:,1), Vert(:,2), Vert(:,3));
end