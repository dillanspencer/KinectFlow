import SimpleOpenNI.*;

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;


FlowField           flowField;
ArrayList<Particle> particles;
float               particlesIncrement = 6;
float        particleSpacing = 1.8;
float        particleSpacing2 = 1.9;

float particlesIncrement2 = 2;

float zTranslate = 1000;
float xPadding = 0;
float maxDepth = 2100;
float subtractZ = 0;

float r;
float g;
float b;

boolean onBeat;
boolean testWithoutKinect;

SimpleOpenNI                kinect2;
AudioInput             song;
Minim                  minim;
ddf.minim.analysis.FFT fft;
BeatDetect             beat;

void setup() {
  fullScreen(P3D, 1);
  background(0);
  flowField = new FlowField(20);
  particles = new ArrayList<Particle>();
  xPadding = width / 5;
  
  testWithoutKinect = true;

  if(!testWithoutKinect){
    kinect2 = new SimpleOpenNI(this);
    kinect2.enableDepth();
    kinect2.enableRGB();
    kinect2.setMirror(true);
    
    minim = new Minim(this);
    song  = minim.getLineIn();
    beat  = new BeatDetect();
  }

  
  r = 160;
  g = 255;
  b = 255;

 

}

void draw() {
  if(!testWithoutKinect){
    kinect2.update();
    beat.detect(song.mix);
  }
  translate(
    xPadding,
    0,
    zTranslate
  );

  background(0);
  flowField.updateField();
  
  int[] depth;
  int width = 250;
  int height = 250;
  
  //for kinect
  //int width = kinect2.depthWidth();
  //int height = kinect2.depthHeight();
  
  if(testWithoutKinect){
    depth = new int[62500];
    for(int i = 0; i < 62500-1; i++){
     depth[i] = (int)random(0,10000);
    }
  }else{
    depth = kinect2.depthMap();
  }

  for (int x = 0; x < width; x += particlesIncrement) {
    for (int y = 0; y < height; y += particlesIncrement) {
      int offset = x + y * width;
      int z = depth[offset];
      if (z > maxDepth || z == 0) {
        continue;
      }

      Particle particle = new Particle(
        x * particleSpacing,
        y * particleSpacing,
        subtractZ - z
      );
      particles.add(particle);
    }
  }


  for (int i = 0; i < particles.size(); i++) {
    particles.get(i).update();
    particles.get(i).render();
    if (particles.get(i).age > particles.get(i).lifeSpan) {
      particles.remove(i);
    }
  }

   stroke(160, 255, 255, 190);
   for (int x = 0; x < width; x += particlesIncrement2) {
     for (int y = 0; y < height; y += particlesIncrement2) {
        int offset = x + y * width;
        int z = depth[offset];
        if (z > maxDepth || z == 0) {
          continue;
        }
        if (!testWithoutKinect && beat.isOnset() ) {
          point(
            x * particleSpacing2,
            y * particleSpacing2,
            subtractZ - z
          );
        }
     }
   }
}


class Particle {
  PVector location;
  PVector velocity;

  float speed;
  float lifeSpan;
  float age;


  Particle (float x, float y, float z) {
    location = new PVector(x, y, z);
    velocity = new PVector(0, 0, 0);

    lifeSpan = random(9, 28);
    speed    = random(4, 9);
  }

  void update() {
    // get current velocity
    if (!onBeat) {
      velocity = flowField.lookupVelocity(location);
      velocity.mult(speed);
      location.add(velocity);
      age++;
    }

  }

  void render() {
    strokeWeight(2);
    stroke(r, g, b, 100);
    strokeWeight(2);
    point(location.x, location.y, location.z);
  }
}

class FlowField {
   PVector[][] grid;
   int   cols, rows;
   int   resolution;
   float zNoise = 0.0;

   FlowField (int res) {
     resolution = res;
     rows = height/resolution;
     cols = width/ resolution;
     grid = new PVector[cols][rows];
   }

   void updateField() {
     float xNoise = 0;
     for (int i = 0; i < cols; i++) {
       float yNoise = 0;
       for (int j = 0; j < rows; j++) {
         // TODO: play around with angles to make it prettier?
         //float angle = radians((noise(xNoise, yNoise, zNoise)) *700) + noise(frameCount);
         //sin(noise(xNoise, yNoise, zNoise) * frameCount) * cos(noise(xOff, yOff, zOff));
         //map(noise(xNoise, yNoise, zNoise), 0, 1, 0, radians(360));
         float angle = radians((noise(xNoise, yNoise, zNoise)) * 700);
         grid[i][j] = PVector.fromAngle(angle);
         yNoise += 0.01;
       }
       xNoise += 0.01;
     }
     zNoise += 0.02;
   }

  PVector lookupVelocity(PVector particleLocation) {
    int column = int(
      constrain(
        particleLocation.x / resolution,
        0,
        cols - 1)
      );
    int row = int(
      constrain(
        particleLocation.y / resolution,
        0,
        rows - 1)
       );
    return grid[column][row].copy();
  }
}
