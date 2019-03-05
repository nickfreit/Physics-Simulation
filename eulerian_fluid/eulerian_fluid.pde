/*-------------------- GLOBAL VARIABLES --------------------*/
Grid g;
int N = 130;
float dens_damp = 0.998;

boolean frames = true;
boolean grid = false;
boolean pretty_colors = false;
boolean pause = false;


/*-------------------- SETUP --------------------*/
void setup() {
  size(940, 940);
  g = new Grid(width, height, N);
  
  for (int i = int(0.3*g.numCells); i <= int(0.7*g.numCells); i++) {
    for (int j = int(0.3*g.numCells); j <= int(0.7*g.numCells); j++) {
      g.d[i][j] = random(0.5, 1);
    }
  }
  
  for (int i = int(0.7*g.numCells); i <= int(0.8*g.numCells); i++) {
    for (int j = int(0.49*g.numCells); j <= int(0.51*g.numCells); j++) {
      g.u_source[i][j] = -random(50, 100);
    }
  }
  colorMode(HSB, 100);
}


/*-------------------- DRAW --------------------*/
void draw() {
  if (!pause) {
    g.update(0.01);
    g.drawGrid(pretty_colors, grid);
    if (frames) {
    fill(0);
    textSize(24);
    text("Frame Rate " + frameRate, 10, 35);
    }
  }
}


/*-------------------- GRID --------------------*/
class Grid
{
  int numCells;
  int grid_w;
  int grid_h;
  
  float xMouseClick;
  float yMouseClick;
  
  float xMouseClickPrev = 0;
  float yMouseClickPrev = 0;
  
  float diffusionRate;
 
  float[][] u;
  float[][] v;
  float[][] u_prev;
  float[][] v_prev;
  float[][] d;
  float[][] d_prev;
  
  float[][] d_source;
  float[][] u_source;
  float[][] v_source;
  
  Grid(int w, int h, int n) {
    grid_w = w;
    grid_h = h;
    numCells = n;
    diffusionRate = 5 / 10000.0;
    
    u = new float[numCells+2][numCells+2];
    v = new float[numCells+2][numCells+2];
    u_prev = new float[numCells+2][numCells+2];
    v_prev = new float[numCells+2][numCells+2];
    d = new float[numCells+2][numCells+2];
    d_prev = new float[numCells+2][numCells+2];
    
    d_source = new float[numCells+2][numCells+2];
    u_source = new float[numCells+2][numCells+2];
    v_source = new float[numCells+2][numCells+2];
  }
  
  void drawGrid(boolean c, boolean g) {
    float cellWidth = grid_w * 1.0 / (numCells+2);
    float cellHeight = grid_h * 1.0 / (numCells+2);
    for (int i = 1; i <= numCells; i++) {
      for (int j = 1; j <= numCells; j++) {
        if (c) {
          fill((1.0-d[i][j])*80, 100, 100);
        } else {
          fill((1 - d[i][j]) * 100);
        }
        if (g) {
          stroke(1);
        } else {
          noStroke();
        }
        rect(j * cellWidth, i * cellHeight, cellWidth, cellHeight);
      }
    }
  }
  
  void update(float dt) {
    updateUI();
    updateVelocity(dt);
    updateDensity(dt);
  }
  
  void updateVelocity(float dt) {
    float[][] temp = new float[numCells+2][numCells+2];
    
    // add sources
    addSource(dt, u, u_source);
    addSource(dt, v, v_source);
    
    // swap and diffuse u
    temp = u;
    u = u_prev;
    u_prev = temp;
    diffuse(u, u_prev, dt, 1);
    
    // swap and diffuse v
    temp = v;
    v = v_prev;
    v_prev = temp;
    diffuse(v, v_prev, dt, 2);
    
    // project onto zero divergence
    project(u, v, u_prev, v_prev);
    
    // swap
    temp = u;
    u = u_prev;
    u_prev = temp;
    
    // swap
    temp = v;
    v = v_prev;
    v_prev = temp;
    
    // advect velocity along itself
    advect(u, u_prev, u_prev, v_prev, dt, 1);
    advect(v, v_prev, u_prev, v_prev, dt, 2);
    
    // project onto zero divergence
    project(u, v, u_prev, v_prev);
  }
  
  void updateDensity(float dt) {
    // dampen density to prevent build up
    for (int i = 1; i <= numCells; i++) {
      for (int j = 1; j <= numCells; j++) {
        if (d[i][j] > 1) {
          d[i][j] = 1;
        }
        d[i][j] *= dens_damp;
      }
    }
    // add source
    addSource(dt, d, d_source);
    
    float[][] temp = new float[numCells+2][numCells+2];
    // swap and diffuse density
    temp = d;
    d = d_prev;
    d_prev = temp;
    diffuse(d, d_prev, dt, 0);
    
    // swap and advect density
    temp = d;
    d = d_prev;
    d_prev = temp;
    advect(d, d_prev, u, v, dt, 0);
  }
  
  void diffuse(float[][] x, float[][] x_prev, float dt, int option) {
    float a = dt * diffusionRate * numCells * numCells;
    linearSolve(x, x_prev, a, 1 + 4 * a, option);
  }
  
  void project(float[][] u, float[][] v, float[][] u_prev, float[][] v_prev)
  {
    for (int i = 1; i <= numCells; i++) {
      for (int j = 1; j <= numCells; j++) {
        u_prev[i][j] = -0.5*(u[i+1][j] - u[i-1][j] + v[i][j+1] - v[i][j - 1])/numCells;
        v_prev[i][j] = 0;
      }
    }
    setBoundaries(0, u_prev);
    setBoundaries(0, v_prev);
    
    // linearly solve to no divergence field
    linearSolve(v_prev, u_prev, 1, 4, 0);
    
    // update u and v
    for (int i = 1; i <= numCells; i++) {
      for (int j = 1; j <= numCells; j++) {
        u[i][j] -= 0.5 * numCells * (v_prev[i+1][j] - v_prev[i-1][j]);
        v[i][j] -= 0.5 * numCells * (v_prev[i][j+1] - v_prev[i][j-1]);
      }
    }
    setBoundaries(1, u);
    setBoundaries(2, v);
  }
  
  void advect(float[][] d, float[][] d_prev, float[][] u, float[][] v, float dt, int option) {
    int i0, j0, i1, j1;
    float x, y, s0, t0, s1, t1, dt0;
    dt0 = dt * numCells;
    
    for (int i = 1; i <= numCells; i++) {
      for (int j = 1; j <= numCells; j++) {
        // find backwards position
        x = i - dt0 * u[i][j];
        y = j - dt0 * v[i][j];
        
        // make sure backward position in bounds
        if (x < 0.5) {
          x = 0.5;
        }
        if (x > numCells + 0.5) {
          x = numCells + 0.5;
        }
        if (y < 0.5) {
          y = 0.5;
        }
        if (y > numCells + 0.5) {
          y = numCells + 0.5;
        }
        
        // set density based on advection
        i0 = int(x);
        i1 = i0 + 1;
        j0 = int(y);
        j1 = j0 + 1;
        
        s1 = x - i0;
        s0 = 1 - s1;
        t1 = y - j0;
        t0 = 1 - t1;
 
        d[i][j] = s0 * (t0 * d_prev[i0][j0] + t1 * d_prev[i0][j1]) +
                  s1 * (t0 * d_prev[i1][j0] + t1 * d_prev[i1][j1]); 
      }
    }
    setBoundaries(option, d);
  }
  
  void linearSolve(float[][] x, float[][] x_prev, float a, float c, int option) {
    // solve a system of equations iteratively
    for (int k = 0; k < 20; k++) {
      for (int i = 1; i <= numCells; i++) {
        for (int j = 1; j <= numCells; j++) {
          x[i][j] = (x_prev[i][j] + a * (x[i-1][j] + x[i+1][j] + x[i][j-1] + x[i][j+1])) / c;
        }
      }
      setBoundaries(option, x);
    }
  }
  
  void setBoundaries(int option, float[][] x) {
    // set boundaries for density/velocity fields
    for (int i = 1; i <= numCells; i++) {
      if (option == 1) { 
        x[0][i] = -x[1][i];
        x[0][numCells+1] = -x[numCells][i];
        x[i][0] = x[i][1];
        x[i][numCells+1] = x[i][numCells];
      } else if (option == 2) {
        x[0][i] = x[1][i];
        x[0][numCells+1] = x[numCells][i];
        x[i][0] = -x[i][1];
        x[i][numCells+1] = -x[i][numCells];
      } else {
        x[0][i] = x[1][i];
        x[0][numCells+1] = x[numCells][i];
        x[i][0] = x[i][1];
        x[i][numCells+1] = x[i][numCells];
      }
    }
    x[0][0] = 0.5 * x[1][0] + x[0][1];
    x[0][numCells+1] = 0.5 * x[1][numCells+1] + x[0][numCells];
    x[numCells+1][0] = 0.5 * x[numCells][0] + x[numCells+1][1];
    x[numCells+1][numCells+1] = 0.5 * x[numCells][numCells+1] + x[numCells+1][numCells];
  }
  
  void addSource(float dt, float[][] x, float[][] source) {
    for (int i = 0; i < numCells+2; i++) {
      for (int j = 0; j < numCells+2; j++) {
        x[i][j] += dt*source[i][j];
        source[i][j] -= dt*source[i][j];
      }
    }

  }
  
  void updateUI() {
    if (mousePressed) {
      xMouseClick = (mouseY * 1.0 / grid_h ) * numCells;
      yMouseClick = (mouseX * 1.0 / grid_w) * numCells;
      if (xMouseClick > 0 && xMouseClick < numCells + 2 &&
          yMouseClick > 0 && yMouseClick < numCells + 2) {
        // when mouse is pressed in bounds, add density at that location
        d_source[int(xMouseClick)][int(yMouseClick)] += 10;
        if (xMouseClickPrev > 0 && yMouseClickPrev > 0) {
          // if mouse is moving while pressed, add velocity at those locations
          float dx = xMouseClick - xMouseClickPrev;
          float dy = yMouseClick - yMouseClickPrev;
          u[int(xMouseClick)][int(yMouseClick)] += dx*10;
          v[int(xMouseClick)][int(yMouseClick)] += dy*10;
        }
        xMouseClickPrev = xMouseClick;
        yMouseClickPrev = yMouseClick;
      }
    }
  }
}


/*-------------------- HELPERS --------------------*/
// Helper function for various toggles
void keyPressed() {
  if (key == 'f') {
    frames = !frames;
  }
  if (key == 'g') {
    grid = !grid;
  }
  if (key == 'c') {
    pretty_colors = !pretty_colors;
  } else {
    pause = !pause;
  }
}
