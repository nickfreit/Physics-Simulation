import peasy.*;


/*-------------------- GLOBAL VARIABLES --------------------*/
PeasyCam cam;
int windowWidth = 960;
int windowHeight = 540;

boolean pressed = false;
boolean showFrames = false;
boolean air = true;

Cloth c;
float xCloth = windowWidth/2 - 150;
float yCloth = 150;
float zCloth = -100;
int numSprings = 30;
int springLen = 10;
float k = 20000;
float kv = 1750;

/*-------------------- SETUP --------------------*/
void setup() {
  size(960, 540, P3D);
  
  // Set up cam
  float eyeZ = (height/2.0) / tan(PI*30.0 / 180.0);
  float centerX = width/2.0;
  float centerY = height/2.0;
  cam = new PeasyCam(this, centerX, centerY, 0, eyeZ);
  
  // Init cloth
  c = new Cloth(xCloth, yCloth, zCloth, numSprings, springLen, k, kv);
}


/*-------------------- DRAW --------------------*/
void draw() {
  background(200);
  lights();
  
  if (showFrames) {
    fill(0);
    text("Frame Rate " + int(frameRate), 5, 15);
  }
  if (air) {
    fill(0);
    text("AIR ON", 5, 15);
  } else {
    fill(0);
    text("AIR OFF", 5, 15);
  }
  
  c.run(0.00015);
}


/*-------------------- CLOTH --------------------*/
class Cloth {
  PVector location;
  int numSprings;
  float len;
  float restlen;
  Spring[][] springs;
  float k;
  float kv;
  float gravStrength = 50;
  float density = .001;
  float drag = .1;
  
  
  Cloth(float x, float y, float z, int numSprings, int len, float k, float kv) {
    location = new PVector(x, y, z);
    this.numSprings = numSprings;
    springs = new Spring[numSprings][numSprings];
    this.len = len;
    restlen = 0.95*len;
    this.k = k;
    this.kv = kv;
    for (int i = 0; i < numSprings; i++) {
      for (int j = 0; j < numSprings; j++) { 
        springs[i][j] = new Spring(x + i*len, y, z + j*len);
      }
    }
  }
  
  void update(float dt) {
    // Update all springs horizontally using spring law
    for (int i = 0; i < numSprings-1; i++) {
      for (int j = 0; j < numSprings; j++) {
        PVector diff = PVector.sub(springs[i+1][j].location, springs[i][j].location);
        float mag = diff.mag();
        PVector norm = PVector.mult(diff, 1/mag);
        float v1 = norm.dot(springs[i][j].velocity);
        float v2 = norm.dot(springs[i+1][j].velocity);
        float f = -k * (restlen - mag) - kv * (v1 - v2);
        
        PVector force = PVector.mult(norm, f);
        
        springs[i][j].force.add(PVector.mult(force, 1));
        springs[i][j].force.add(0, gravStrength * springs[i][j].mass);
      
        springs[i+1][j].force.add(PVector.mult(force, -1));
        springs[i+1][j].force.add(0, gravStrength * springs[i+1][j].mass); 
      }
    }
    
    // Update all springs vertically using spring law
    for (int i = 0; i < numSprings; i++) {
      for (int j = 0; j < numSprings-1; j++) {
        PVector diff = PVector.sub(springs[i][j+1].location, springs[i][j].location);
        float mag = diff.mag();
        PVector norm = PVector.mult(diff, 1/mag);
        float v1 = norm.dot(springs[i][j].velocity);
        float v2 = norm.dot(springs[i][j+1].velocity);
        float f = -k * (restlen - mag) - kv * (v1 - v2);
        
        PVector force = PVector.mult(norm, f);
        springs[i][j].force.add(PVector.mult(force, 1));
        springs[i][j].force.add(0, gravStrength * springs[i][j].mass);
      
        springs[i][j+1].force.add(PVector.mult(force, -1));
        springs[i][j+1].force.add(0, gravStrength * springs[i][j+1].mass); 
      }
    }
    
    // Add air resistance to springs
    for (int i = 0; i < numSprings-1; i++) {
      for (int j = 0; j < numSprings-1; j++) {
        PVector cross1 = PVector.sub(springs[i][j+1].location, springs[i][j].location);
        PVector cross2 = PVector.sub(springs[i+1][j].location, springs[i][j].location);
        PVector norm = cross1.cross(cross2);
        float area = norm.mag();
        
        norm.normalize();
        PVector sum = new PVector(0,0,0);
        sum.add(springs[i][j].velocity);
        sum.add(springs[i][j+1].velocity);
        sum.add(springs[i+1][j].velocity);
        sum.add(springs[i+1][j+1].velocity);
        sum.mult(0.25);
        if (sum.mag() > 0) {
          area = area * sum.dot(norm) / sum.mag();
        }
        PVector dragForce = PVector.mult(norm, -0.5*density*drag*area*sum.mag()*sum.mag());
        if (air) {
          dragForce.add(random(100, 200), random(-200, 200), random(-100, 100));
        }
        springs[i][j].force.add(dragForce);
        springs[i][j+1].force.add(dragForce);
        springs[i+1][j].force.add(dragForce);
        springs[i+1][j+1].force.add(dragForce); 
      }
    }
    
    // Check if springs are colliding with the sphere and update them
    for (int i = 1; i < numSprings; i++) {
      for (int j = 0; j < numSprings; j++) {
        springs[i][j].update(dt);
      }
    }
  }
  
  void display() {
    strokeWeight(0);
    for (int i = 0; i < numSprings - 1; i++) {
      for (int j = 0; j < numSprings - 1; j++) {
        fill(100 * (1-i % 2) + 100, 40, 100 * (i % 2) + 100);
        beginShape(TRIANGLE_STRIP);
        vertex(springs[i][j].location.x, springs[i][j].location.y, springs[i][j].location.z);
        vertex(springs[i][j+1].location.x, springs[i][j+1].location.y, springs[i][j+1].location.z);
        vertex(springs[i+1][j+1].location.x, springs[i+1][j+1].location.y, springs[i+1][j+1].location.z);
        endShape();
        beginShape(TRIANGLE_STRIP);
                vertex(springs[i+1][j+1].location.x, springs[i+1][j+1].location.y, springs[i+1][j+1].location.z);
        vertex(springs[i][j].location.x, springs[i][j].location.y, springs[i][j].location.z);
        vertex(springs[i+1][j].location.x, springs[i+1][j].location.y, springs[i+1][j].location.z);
        endShape();
      }
    }
  }
  
  void run(float dt) {
    if (pressed) {
      for (int i = 0; i < 100; i++) {
        update(dt);
      }
    }
    display();
  }
}


/*-------------------- SPRING --------------------*/
class Spring {
  PVector location, velocity, acceleration, force;
  float mass;
  
  Spring(float x, float y, float z) {
    location = new PVector(x, y, z);
    velocity = new PVector(0, 0, 0);
    acceleration = new PVector(0, 0, 0);
    force = new PVector(0, 0, 0);
    mass = 2;
  }
  
  void update(float dt) {
    // Simple Eulerian Integrator
    location.add(PVector.mult(velocity, dt));
    velocity.add(PVector.mult(acceleration, dt));
    acceleration.set(force.mult(1/mass));
    force.set(0, 0, 0);
  }
  
  void display() {
    noStroke();
    fill(255);
    pushMatrix();
    translate(location.x, location.y, location.z);
    point(0, 0);
    popMatrix();
  }
}


/*-------------------- HELPERS --------------------*/
/* Function to show the frames per second and pause simulation.
 */
void keyPressed() {
  if (key == 'f') {
    showFrames = !showFrames;
  } else if (key == 'a') {
    air = !air;
  }
  else {
    pressed = !pressed;
  }
}
