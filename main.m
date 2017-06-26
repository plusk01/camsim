clear, clc;

% Create some rotations that will be used to define coordinate frames
Rw_to_c = rotx(-pi/2)*roty(0)*rotz(0);

% Create camera frame
Fw = Frame('w', [0 0 0], eye(3));
Fc = Frame('c', [0 0 0], Rw_to_c, Fw);

% Define a camera model
cam = Camera(Fc, 1600, 1200, 12, 0.0045, 1);

% Create a scene expressed in a given frame w/ offset
scene = Scene(Fc, [0 0 30]);

% Generate N points with a given spread in each direction
scene.generatePoints(30, [10 10 10]);

s = 0.3;
scene.addPlane([-3 -4 10]*s, [5 -4 10]*s, [4 0 0]*s, [-2 0 0]*s);

% Register the scene with the camera object
cam.viewScene(scene);

% Draw the scene and camera
figure(1), clf;
scene.draw()
Fc.draw('k');
cam.draw();

figure(2), clf; cam.showImage();