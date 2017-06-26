clear, clc;
rng(1); % For repeatability

%% Coordinate frame and camera setup
% Create some rotations that will be used to define coordinate frames
Rw_to_scene = rotx(-pi/2)*roty(0)*rotz(0);
Rw_to_c = rotx(0)*roty(pi/50)*rotz(0);
R1_to_2 = rotx(-pi/20)*roty(pi/10)*rotz(0);

% Create camera frame
Fw = Frame('w', [0 0 0], eye(3));
Fscene = Frame('scene', [0 0 0], Rw_to_scene, Fw);
Fc1 = Frame('c1', [0 0 0], Rw_to_c, Fscene);
Fc2 = Frame('c2', [-8 -3 30], R1_to_2, Fc1);

% Define a camera model
cam1 = Camera(Fc1, 1600, 1200, 12, 0.0045);
cam2 = Camera(Fc2, 1600, 1200, 12, 0.0045);

%% Scene Creation

% Create a scene expressed in a given frame w/ offset
scene = Scene(Fscene, [0 0 50]);

scene.generatePoints(30, [10 10 5]);

s = 0.3;
scene.addPlane([-3 -4 1]*s, [5 -4 1]*s, [4 0 0]*s, [-2 0 0]*s);

% Register the scene with the camera object
cam1.viewScene(scene);
cam2.viewScene(scene);

%% Visualize the scene with the cameras

% Draw the scene and camera
figure(1), clf;
scene.draw()
Fc1.draw('k');
Fc2.draw('r');
cam1.draw();
cam2.draw();

figure(2), clf; cam1.showImage();
figure(3), clf; cam2.showImage();

figure(4), clf; cam1.showNIP();