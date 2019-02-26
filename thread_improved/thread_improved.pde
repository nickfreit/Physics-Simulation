import peasy.*;


/*-------------------- GLOBAL VARIABLES --------------------*/
PeasyCam cam;
Thread t1;
boolean pressed = false;
Cloth c;
PVector sLocation;
float sRadius = 60;

/*-------------------- SETUP --------------------*/
void setup() {
  size(960, 540, P3D);
  
  float eyeZ = (height/2.0) / tan(PI*30.0 / 180.0);
  float centerX = width/2.0;
  float centerY = height/2.0;

  cam = new PeasyCam(this, centerX, centerY, 0, eyeZ);
  
  sLocation = new PVector(width/2 + 150, height/2-100, 140);
  
  //t1 = new Thread(width/2, 50, 6, 50, 500, 500);
  c = new Cloth(width/2, 50, 0, 30, 10, 20000, 500);
}


/*-------------------- DRAW --------------------*/
void draw() {
  background(200);
  lights();
  
  pushMatrix();
  translate(sLocation.x, sLocation.y, sLocation.z);
  fill(100, 200, 100);
  noStroke();
  sphere(sRadius);
  popMatrix();
  //t1.run(0.0005);
  c.run(0.0001);
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
  float gravStrength;
  
  
  Cloth(float x, float y, float z, int numSprings, int len, float k, float kv) {
    location = new PVector(x, y, z);
    this.numSprings = numSprings;
    springs = new Spring[numSprings][numSprings];
    this.len = len;
    restlen = 0.95*len;
    this.k = k;
    this.kv = kv;
    gravStrength = 50;
    for (int i = 0; i < numSprings; i++) {
      for (int j = 0; j < numSprings; j++) { 
        springs[i][j] = new Spring(x + j*len, y, i*len);
      }
    }
  }
  
  void update(float dt) {
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
    
    for (int i = 1; i < numSprings; i++) {
      for (int j = 0; j < numSprings; j++) {
        Spring s = springs[i][j];
        if (dist(s.location.x, s.location.y, s.location.z, sLocation.x, sLocation.y, sLocation.z) < sRadius) {
          PVector norm = new PVector(s.location.x-sLocation.x, s.location.y-sLocation.y, s.location.z-sLocation.z);
          norm.normalize();
          float dot = s.velocity.dot(norm);
          s.velocity.sub(PVector.mult(norm, 1.2 * dot));
          s.location.set(PVector.add(sLocation, PVector.mult(norm, sRadius)));
        }
        springs[i][j].update(dt);
      }
    }
  }
  
  void display() {
    for (int i = 0; i < numSprings; i++) {
      for (int j = 0; j < numSprings; j++) {
        springs[i][j].display();
      }
    }
    stroke(255);
    strokeWeight(3);
    for (int i = 0; i < numSprings - 1; i++) {
      for (int j = 0; j < numSprings; j++) {
        line(springs[i][j].location.x, springs[i][j].location.y, springs[i][j].location.z,
             springs[i+1][j].location.x, springs[i+1][j].location.y, springs[i+1][j].location.z);
      }
    }   
    for (int i = 0; i < numSprings; i++) {
      for (int j = 0; j < numSprings - 1; j++) {
        line(springs[i][j].location.x, springs[i][j].location.y, springs[i][j].location.z,
             springs[i][j+1].location.x, springs[i][j+1].location.y, springs[i][j+1].location.z);
      }
    }
  }
  
  void run(float dt) {
    if (pressed) {
      for (int i = 0; i < 75; i++) {
        update(dt);
      }
    }
    display();
  }
}

/*-------------------- THREAD --------------------*/
class Thread {
  PVector location;
  int numSprings;
  float len;
  float restlen;
  Spring[] springs;
  float k;
  float kv;
  float gravStrength;
  
  
  Thread(float x, float y, int numSprings, int len, float k, float kv) {
    location = new PVector(x, y);
    this.numSprings = numSprings;
    springs = new Spring[numSprings];
    this.len = len;
    restlen = 0.95*len;
    this.k = k;
    this.kv = kv;
    gravStrength = 50;
    for (int i = 0; i < numSprings; i++) {
      springs[i] = new Spring(x + i*len, y, 0);
    }
  }
  
  void update(float dt) {
    for (int i = 0; i < numSprings-1; i++) {
      
      PVector diff = PVector.sub(springs[i+1].location, springs[i].location);
      float mag = diff.mag();
      PVector norm = PVector.mult(diff, 1/mag);
      float v1 = norm.dot(springs[i].velocity);
      float v2 = norm.dot(springs[i+1].velocity);
      float f = -k * (restlen - mag) - kv * (v1 - v2);
      
      PVector force = PVector.mult(norm, f);
      springs[i].force.add(PVector.mult(force, 1));
      springs[i].force.add(0, gravStrength);
      
      springs[i+1].force.add(PVector.mult(force, -1));
      springs[i+1].force.add(0, gravStrength); 
    }
    
    for (int i = 1; i < numSprings; i++) {
      springs[i].update(dt);
    }
  }
  
  void display() {
    for (int i = 0; i < numSprings; i++) {
      springs[i].display();
    }
    for (int i = 1; i < numSprings; i++) {
      stroke(255);
      strokeWeight(5);
      line(springs[i-1].location.x, springs[i-1].location.y, springs[i].location.x, springs[i].location.y);
    }
  }
  
  void run(float dt) {
    if (pressed) {
      for (int i = 0; i < 50; i++) {
        update(dt);
      }
    }
    display();
  }
}



/*-------------------- Spring --------------------*/
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
/* Function to show the frames per second and number of
 * particles of the system.
 */
void keyPressed() {
  println("Frames " + frameCount / (millis() / 1000.0));
  pressed = !pressed;
}
