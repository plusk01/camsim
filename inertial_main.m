clear, clc;

% Create some rotations that will be used to define coordinate frames
Rw_to_i = [1 0 0; 0 -1 0; 0 0 -1]; % From world to inertial
Ri_to_c = [0 1 0; 0 0 1; 1 0 0];   % From inertial to camera
Ri_to_c = rotx(pi/2)*roty(0)*rotz(pi/2);

% Create inertial (NED) and camera frame
Fw = Frame([0 0 0], eye(3));
Fi = Frame([0 2 -5], Rw_to_i, Fw);
Fc = Frame([10 0 5], Ri_to_c, Fi);

% Define a camera model
cam = Camera(Fc, 1600, 1200, 12, 0.0045);

% Create and draw scene points
scene_points = [randi(5,10,1)+20 randi(5,10,1)+20 randi(5,10,1)];
X = scene_points(:,1);
Y = scene_points(:, 2);
Z = scene_points(:, 3);
    
figure(1), clf;
scatter3(X, Y, Z);
% adjustAxis(X,Y,Z);


%Fw.draw();
Fi.draw('k');
Fc.draw('r');
cam.draw();

scene_points = [randi(5,10,1)+20 randi(5,10,1)+20 randi(5,10,1)];
% drawWorld(Fi_i, Fc_i, scene_points);