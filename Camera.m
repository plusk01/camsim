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
        points_px
        planes_px
        spheres_px
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
        
        function [U, V] = project(cam, points, R, t)
            %PROJECT Project 3D points onto pixels
            
            % Create the projection matrix: K*[R|t]
            P = cam.K*R*[eye(3) -t];
            
            % How many points are there?
            N = size(points, 1);
            
            % Get homogeneous points
            pts = [points ones(N,1)];
            
            % Project onto homogeneous pixels
            hpixels = (P*pts')';
            
            % Normalize pixels -- [u v 1]
            hpixels = hpixels./hpixels(:,3);
            
            % Extract the nonhomogeneous pixels
            U = hpixels(:,1);
            V = hpixels(:,2);
        end
        
        function viewScene(cam, scene)
            %VIEWSCENE Project scene elements onto pixels
            
            cam.scene = scene;
            
            % Get the origin vector and orientation matrix of
            % the camera frame defined in the scene frame.
            % Scene elements are defined in the scene frame, so this
            % represents the extrinsic camera parameters needed in the
            % projection matrix.
            [t,R] = cam.F.express(scene.F);
            
            % =============================================================
            % Scene Points [...; x y z id; ...] (Nx4)
            % =============================================================
            if ~isempty(scene.points)
                
                % The fourth column is just the id
                pts = scene.points(:, 1:3);

                % Project 3D world points onto pixel plane
                [U, V] = cam.project(pts, R, t);
                
                % Augment pixels with ids and save to cam.points_px
                cam.points_px = [U V scene.points(:,4)];
                
            end
            % -------------------------------------------------------------
            
            % =============================================================
            % Scene Plane [...; tl tr br bl id; ...] (Nx[4*3+1])
            % =============================================================
            for i = 1:size(scene.planes,1)
                % Get plane vertices
                vert = scene.planes(i, 1:12);

                % reshape to match format of [tl; tr; br; bl]
                vert = reshape(vert, 3, 4)';

                % Project 3D world points onto pixel plane
                [U, V] = cam.project(vert, R, t);

                % Reshape to fit plane format (row of [tl tr br bl])
                pixels = reshape([U V]', 1, 8);

                % Augment pixels with ids and save
                cam.planes_px = [cam.planes_px; pixels scene.planes(i,5)];
            end
            % -------------------------------------------------------------
            
            % =============================================================
            % Scene Sphere [...; center radius id; ...] (Nx5)
            % =============================================================
            for i = 1:size(scene.spheres,1)
                
                % Break out center/radius
                center = scene.spheres(i,1:3);
                radius = scene.spheres(i,4);
                id = scene.spheres(i,5);
                
                % Project the center point to pixels
                [U, V] = cam.project(center, R, t);
                
                % Project the radius to pixels
                radius = radius*cam.K(1,1)/center(3);
                
                pixels = [U V radius id];
                
                % Augment pixels with ids and save
                cam.spheres_px = [cam.spheres_px; pixels];
            end
            % -------------------------------------------------------------
        end
        
        function showImage(cam)
            %SHOWIMAGE
            
            hold on;
            
            % Since we are simply plotting pixels that have already been
            % projected from the 3D world, we can set no translation and
            % identity orientation.
            t = zeros(2,1);
            R = eye(2);
           
            % =============================================================
            % Points
            % =============================================================
            if ~isempty(cam.points_px)
                U = cam.points_px(:,1);
                V = cam.points_px(:,2);
                ids = cam.points_px(:,3);
               
                Scene.drawPoints(t, R, [U V], ids);
            end
            % -------------------------------------------------------------
            
            % =============================================================
            % Planes
            % =============================================================
            for i=1:size(cam.planes_px, 1)

                % Get plane vertices
                vert = cam.planes_px(i, 1:8);

                % reshape to match format of [tl; tr; br; bl]
                vert = reshape(vert, 2, 4)';
                
                Scene.drawPlane(t, R, vert);
            end
            % -------------------------------------------------------------
            
            % =============================================================
            % Spheres
            % =============================================================
            for i = 1:size(cam.spheres_px, 1)
                
                % Break out center/radius
                center = cam.spheres_px(i,1:2);
                radius = cam.spheres_px(i,3);
                id = cam.spheres_px(i,4);
                
                Scene.drawSphere(t, R, center, radius, id);
            end
            % -------------------------------------------------------------
            
            title(sprintf('Camera Image: %s', cam.F.name));
            axis([0 cam.wpx 0 cam.hpx]);
            set(gca,'YDir','Reverse'); set(gca, 'XAxisLocation', 'top');
            xlabel('x (pixels)'); ylabel('y (pixels)'); grid off;
        end
        
        function showNIP(cam)
            %SHOWNIP Show normalized image plane
            
            hold on;
            
            % No translation/rotation neccessary
            t = zeros(2,1);
            R = eye(2);
           
            % =============================================================
            % Points
            % =============================================================
            if ~isempty(cam.points_px)
                U = cam.points_px(:,1);
                V = cam.points_px(:,2);
                ids = cam.points_px(:,3);
                
                pixels = [U V ones(length(U), 1)];
                
                nips = (cam.K\pixels')';
               
                Scene.drawPoints(t, R, [nips(:,1) nips(:,2)], ids);
            end
            % -------------------------------------------------------------
            
            % Find maximum normalized image coordinate
            nips = (cam.K\[cam.wpx cam.hpx 1]')';
            
            title(sprintf('NIP: %s', cam.F.name));
            axis([-nips(1) nips(1) -nips(2) nips(2)]);
            set(gca,'YDir','Reverse'); set(gca, 'XAxisLocation', 'top');
            xlabel('x (normalized)'); ylabel('y (normalized)'); grid off;
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